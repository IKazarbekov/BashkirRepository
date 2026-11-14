import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import 'progress_store.dart';
import 'lessons.dart';

enum SessionStatus { loading, signedOut, signedIn, unavailable }

class AppSession extends ChangeNotifier {
  AppSession(this.api, this.progress);
  final ApiClient api;
  final ProgressStore progress;
  SessionStatus status = SessionStatus.loading;
  bool busy = false;
  String? error;
  String username = '';
  String? newRecoveryCode;
  String rememberedUser = '';


  Future<void> restore() async {
    status = SessionStatus.loading;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    rememberedUser = prefs.getString('auth_username') ?? '';
    final saved = prefs.getString('auth_token');
    if (saved == null || saved.isEmpty) {
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    api.token = saved;
    try {
      final me = await api.request('GET', '/me');
      await progress.loadForAccount(api);
      await refreshLessonCatalog(api);
      username = me['username'] as String? ?? '';
      status = SessionStatus.signedIn;
      error = null;
    } on ApiError catch (issue) {
      if (issue.status == 401) {
        await prefs.remove('auth_token');
        api.token = null;
        progress.clear();
        status = SessionStatus.signedOut;
      } else {
        status = SessionStatus.unavailable;
        error = issue.message;
      }
    } catch (_) {
      status = SessionStatus.unavailable;
      error = 'Не удалось восстановить сессию';
    }
    notifyListeners();
  }

  Future<bool> signIn(String login, String password, {bool create = false, bool remember = true, String? region}) async {
    if (busy) return false;
    busy = true;
    error = null;
    notifyListeners();
    try {
      if (create) {
        final registration = await api.request('POST', '/register',
          body: {'login': login, 'password': password, if (region != null) 'region': region}, authorized: false);
        newRecoveryCode = registration['recovery_key'] as String?;
      }
      final response = await api.request('POST', '/login',
        body: {'login': login, 'password': password, 'remember': remember}, authorized: false);
      api.token = response['token'] as String;
      await progress.loadForAccount(api);
      await refreshLessonCatalog(api);
      final prefs = await SharedPreferences.getInstance();
      username = response['username'] as String;
      if (remember) {
        // Each Chrome profile/origin and each installed device keeps its own session.
        await prefs.setString('auth_token', api.token!);
        await prefs.setString('auth_username', username);
      } else {
        await prefs.remove('auth_token');
        await prefs.remove('auth_username');
      }
      rememberedUser = remember ? username : '';
      status = SessionStatus.signedIn;
      return true;
    } on ApiError catch (issue) {
      api.token = null;
      error = issue.message;
      return false;
    } catch (_) {
      api.token = null;
      error = 'Не удалось выполнить вход';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final oldToken = api.token;
    api.token = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('auth_token');
    await preferences.remove('auth_username');
    progress.clear();
    username = '';
    rememberedUser = '';
    newRecoveryCode = null;
    status = SessionStatus.signedOut;
    error = null;
    notifyListeners();
    if (oldToken != null) {
      api.token = oldToken;
      try {
        await api.request('POST', '/logout');
      } catch (_) {
        // The local session is already cleared.
      } finally {
        api.token = null;
      }
    }
  }
}
