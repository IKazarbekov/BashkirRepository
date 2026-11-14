import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'api_client.dart';

/// Short, unobtrusive sounds. Files can be overridden by an administrator.
/// Every screen still works if the browser blocks audio or the API is offline.
class UiSounds {
  UiSounds._();
  static final UiSounds instance = UiSounds._();
  final AudioPlayer _player = AudioPlayer();
  Map<String, String> _remote = {};
  String? _baseUrl;

  Future<void> configure(ApiClient api) async {
    _baseUrl = api.baseUrl;
    try {
      final result = await api.request('GET', '/extras/branding');
      final sounds = result['sounds'] as Map<String, dynamic>? ?? {};
      _remote = {for (final item in sounds.entries) item.key: '${item.value}'};
    } catch (_) {
      _remote = {};
    }
  }

  void play(String event) {
    if (!const ['check', 'next', 'success', 'error', 'coin'].contains(event)) return;
    unawaited(_play(event));
  }

  Future<void> _play(String event) async {
    try {
      await _player.stop();
      final path = _remote[event];
      await _player.play(path == null || _baseUrl == null
        ? AssetSource('sounds/$event.wav') : UrlSource('$_baseUrl$path'));
    } catch (_) { /* Audio must never interrupt a lesson. */ }
  }
}
