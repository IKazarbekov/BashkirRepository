import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';

/// Per-account checkpoints. SQLite remains authoritative; SharedPreferences
/// retains a local backup if a request fails or the browser is temporarily offline.
class GameCheckpointRepository {
  GameCheckpointRepository(this.api, this.mode);
  final ApiClient api;
  final String mode;
  Future<void> _queue = Future<void>.value();
  String? _key;
  String? error;

  Future<String> _storageKey() async {
    if (_key != null) return _key!;
    final preferences = await SharedPreferences.getInstance();
    var username = preferences.getString('auth_username') ?? '';
    if (username.isEmpty) {
      try {
        final account = await api.request('GET', '/me');
        username = '${account['username']}';
      } catch (_) { username = 'session_${api.token?.hashCode ?? 0}'; }
    }
    _key = 'bashkir_checkpoint_v12_${Uri.encodeComponent(api.baseUrl)}_${Uri.encodeComponent(username)}_$mode';
    return _key!;
  }

  Future<Map<String, dynamic>?> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(await _storageKey());
      return raw == null ? null : (jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>> load() async {
    final local = await _readLocal();
    try {
      final server = await api.request('GET', '/extras/game-sessions/$mode');
      error = null;
      // Recover a locally completed step only if the last server sync failed.
      if (local?['sync_pending'] == true && server['saving_enabled'] != false &&
          (local?['step'] as num? ?? 0) > (server['step'] as num? ?? 0)) {
        final recovered = Map<String, dynamic>.from(local!);
        recovered['has_checkpoint'] = true;
        unawaited(save(recovered, enabled: true));
        return recovered;
      }
      return server;
    } catch (e) {
      error = 'Не удалось подключиться к серверу: $e';
      return local ?? {
        'difficulty': 'medium', 'step': 0, 'right_answers': 0,
        'earned_display': 0, 'matched': <String>[], 'has_checkpoint': false,
        'saving_enabled': true,
      };
    }
  }

  Future<void> save(Map<String, dynamic> data, {required bool enabled}) async {
    final state = Map<String, dynamic>.from(data);
    state['has_checkpoint'] = (state['step'] as num? ?? 0) > 0 ||
      (state['right_answers'] as num? ?? 0) > 0 ||
      ((state['matched'] as List<dynamic>? ?? []).isNotEmpty);
    state['sync_pending'] = true;
    final prefs = await SharedPreferences.getInstance();
    if (enabled) {
      await prefs.setString(await _storageKey(), jsonEncode(state));
    } else {
      await prefs.remove(await _storageKey());
    }
    // Keep writes ordered. The server also rejects stale step numbers.
    _queue = _queue.catchError((Object _) {}).then((_) async {
      try {
        await api.request('PUT', '/extras/game-sessions/$mode', body: {
          'difficulty': data['difficulty'], 'step': data['step'],
          'matched': data['matched'] ?? <String>[],
          'right_answers': data['right_answers'] ?? 0,
          'earned_display': data['earned_display'] ?? 0,
        });
        error = null;
        // Do not clear the marker of a newer local write.
        if (enabled && prefs.getString(await _storageKey()) == jsonEncode(state)) {
          state['sync_pending'] = false;
          await prefs.setString(await _storageKey(), jsonEncode(state));
        }
      } catch (e) { error = 'Не удалось сохранить на сервере: $e'; }
    });
    await _queue;
  }

  Future<void> clear() async {
    await _queue.catchError((Object _) {});
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _storageKey());
    await api.request('DELETE', '/extras/game-sessions/$mode');
    error = null;
  }
}
