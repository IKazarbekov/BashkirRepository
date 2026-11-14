import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';

class ProgressStore extends ChangeNotifier {
  final Set<int> completed = {};
  final Set<String> favorites = {};
  String displayName = 'Ученик';
  int xp = 0;
  int streak = 0;
  String lastStudyDay = '';
  String voiceLanguage = 'bak';
  String voiceId = 'bak_aigul';
  int lastEarnedCoins = 0;
  bool lastSaved = true;
  List<dynamic> lastAchievements = [];
  ApiClient? _api;

  int get nextLesson {
    var index = 0;
    while (completed.contains(index)) {
      index++;
    }
    return index;
  }

  int get activeStreak {
    if (lastStudyDay.isEmpty) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime.tryParse(lastStudyDay);
    if (last == null || today.difference(last).inDays > 1) return 0;
    return streak;
  }

  Future<void> loadForAccount(ApiClient api) async {
    final state = await api.request('GET', '/progress');
    _api = api;
    _apply(state);
  }

  void _apply(Map<String, dynamic> state) {
    completed
      ..clear()
      ..addAll(((state['completed'] as List<dynamic>?) ?? []).whereType<int>());
    favorites
      ..clear()
      ..addAll(((state['favorites'] as List<dynamic>?) ?? []).whereType<String>());
    displayName = state['display_name'] as String? ?? 'Ученик';
    xp = state['xp'] as int? ?? 0;
    streak = state['streak'] as int? ?? 0;
    lastStudyDay = state['last_study_day'] as String? ?? '';
    voiceLanguage = state['voice_language'] as String? ?? 'bak';
    voiceId = state['voice_id'] as String? ?? 'bak_aigul';
    notifyListeners();
  }

  Future<bool> completeLesson(int lessonIndex) async {
    final answer = await _requireApi().request('POST', '/progress/lessons/$lessonIndex');
    _apply(answer['progress'] as Map<String, dynamic>);
    lastSaved = answer['saved'] != false;
    if (!lastSaved) { completed.add(lessonIndex); notifyListeners(); }
    lastEarnedCoins = (answer['earned_coins'] as num?)?.toInt() ?? 0;
    lastAchievements = answer['new_achievements'] as List<dynamic>? ?? [];
    return answer['awarded_xp'] == true;
  }

  Future<void> toggleFavorite(String word) async {
    final nextValue = !favorites.contains(word);
    final answer = await _requireApi().request('PUT', '/progress/favorites', body: {
      'word': word,
      'favorite': nextValue,
    });
    if (answer['saved'] == false) {
      if (nextValue) favorites.add(word); else favorites.remove(word);
      notifyListeners();
    } else { _apply(answer); }
  }

  Future<void> rename(String name) async {
    final answer = await _requireApi().request('PATCH', '/progress/profile', body: {'display_name': name.trim()});
    _apply(answer);
  }

  Future<void> changeVoice(String language, String voiceId) async {
    final answer = await _requireApi().request('PUT', '/progress/settings', body: {
      'voice_language': language,
      'voice_id': voiceId,
    });
    _apply(answer);
  }

  Future<bool> hasLegacyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('completed_lessons') ?? []).isNotEmpty ||
        (prefs.getStringList('favorite_words') ?? []).isNotEmpty;
  }

  Future<void> importLegacyProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final completedLessons = (prefs.getStringList('completed_lessons') ?? [])
        .map(int.tryParse).whereType<int>().toSet().toList()..sort();
    final favoriteWords = prefs.getStringList('favorite_words') ?? [];
    final state = await _requireApi().request('POST', '/progress/import', body: {
      'completed': completedLessons,
      'favorites': favoriteWords,
      'display_name': prefs.getString('display_name') ?? 'Ученик',
    });
    _apply(state);
    for (final key in [
      'completed_lessons', 'favorite_words', 'display_name',
      'xp', 'streak', 'last_study_day',
    ]) {
      await prefs.remove(key);
    }
  }

  Future<void> reset() async {
    final answer = await _requireApi().request('DELETE', '/progress');
    _apply(answer);
  }

  void clear() {
    _api = null;
    _apply({});
  }

  ApiClient _requireApi() {
    final api = _api;
    if (api == null) throw const ApiError('Нет подключения к аккаунту');
    return api;
  }
}
