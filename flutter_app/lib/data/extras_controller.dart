import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import 'ui_copy.dart';
import 'course_adaptive_lexicon.dart';

class ExtrasController extends ChangeNotifier {
  ExtrasController(this.api);
  final ApiClient api;
  String? _loadedFor;
  bool busy = false;
  String region = '';
  int coins = 0;
  String theme = 'default';
  bool optionalSpeaking = true;
  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> shop = [];
  List<Map<String, dynamic>> achievements = [];
  Set<String> purchases = {};
  bool courseRewardClaimed = false;
  String baseLanguage = 'ru';
  bool adaptiveUi = false;
  bool onboardingDone = false;
  bool publicRank = true;
  Map<String, bool> savePreferences = {
    'lessons': true, 'games': true, 'practices': true, 'achievements': true,
    'rankings': true, 'favorites': true, 'purchases': true,
  };
  Map<String, bool> gameModePreferences = {
    'choice': true, 'pairs': true, 'arrange': true,
    'listen': true, 'write': true, 'speech': true,
  };
  bool telegramLinked = false;
  bool courseFinished = false;
  int learnedLessons = 0;
  Set<String> studiedWords = {};
  

  bool hasVoice(String lang, [String? speaker]) {
    if (purchases.contains('voices_all') || purchases.contains('voice_$lang')) return true;
    if (speaker == null) return lang == 'bak' || lang == 'tat';
    if (purchases.contains('voice_$speaker')) return true;
    const free = {'bak': {'bak_aigul', 'bak_alfia', 'bak_miyau'}, 'tat': {'tat_albina'}};
    return free[lang]?.contains(speaker) == true;
  }
  bool hasTheme(String name) => name == 'default' || purchases.contains('theme_$name');

  void clear() {
    _loadedFor = null;
    region = '';
    coins = 0;
    theme = 'default';
    stats = {};
    shop = [];
    achievements = [];
    purchases = {};
    optionalSpeaking = true;
    courseRewardClaimed = false;
    baseLanguage = 'ru'; adaptiveUi = false; onboardingDone = false;
    studiedWords = {}; telegramLinked = false; courseFinished = false;
    savePreferences = {for (final key in savePreferences.keys) key: true};
    gameModePreferences = {for (final key in gameModePreferences.keys) key: true};
    notifyListeners();
  }

  Future<void> load({String? username}) async {
    if (busy || (username != null && username == _loadedFor)) return;
    busy = true;
    try {
      final data = await api.request('GET', '/extras/bootstrap');
      _apply(data);
      if (username != null) _loadedFor = username;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _loadedFor = null;
    await load();
  }

  void _apply(Map<String, dynamic> data) {
    region = data['region'] as String? ?? '';
    coins = (data['coins'] as num?)?.toInt() ?? 0;
    theme = data['theme'] as String? ?? 'default';
    optionalSpeaking = data['optional_speaking'] != false;
    stats = (data['stats'] as Map<String, dynamic>?) ?? {};
    shop = ((data['shop'] as List<dynamic>?) ?? []).whereType<Map<String, dynamic>>().toList();
    achievements = ((data['achievements'] as List<dynamic>?) ?? []).whereType<Map<String, dynamic>>().toList();
    purchases = ((data['purchases'] as List<dynamic>?) ?? []).whereType<String>().toSet();
    courseRewardClaimed = data['course_reward_claimed'] == true;
    final saves = data['save_preferences'] as Map<String, dynamic>?;
    if (saves != null) {
      savePreferences = {for (final key in savePreferences.keys) key: saves[key] != false};
      final modes = saves['game_modes'] as Map<String, dynamic>? ?? {};
      gameModePreferences = {for (final key in gameModePreferences.keys) key: modes[key] != false};
    }
    telegramLinked = data['telegram_linked'] == true;
    final settings = data['learning_preferences'] as Map<String,dynamic>? ?? {};
    baseLanguage = settings['base_language'] as String? ?? 'ru';
    adaptiveUi = settings['adaptive_ui'] == true;
    onboardingDone = settings['onboarding_done'] == true;
    publicRank = settings['public_rank'] != false;
    courseFinished = settings['course_finished'] == true;
    learnedLessons = (settings['completed_count'] as num?)?.toInt() ?? 0;
    studiedWords = ((settings['studied_words'] as List<dynamic>?) ?? []).whereType<String>().toSet();
    notifyListeners();
  }


  Future<void> updateSavePreferences(Map<String, dynamic> values) async {
    final response = await api.request('PUT', '/extras/save/preferences', body: values);
    final saved = response['preferences'] as Map<String, dynamic>? ?? {};
    savePreferences = {for (final key in savePreferences.keys) key: saved[key] != false};
    final modes = saved['game_modes'] as Map<String, dynamic>? ?? {};
    gameModePreferences = {for (final key in gameModePreferences.keys) key: modes[key] != false};
    notifyListeners();
  }

  Future<void> resetSaved(String category, {String? mode, int? lessonIndex}) async {
    final params = Uri(queryParameters: {
      if (mode != null) 'mode': mode,
      if (lessonIndex != null) 'lesson_index': '$lessonIndex',
    }).query;
    await api.request('DELETE', '/extras/save/progress/$category${params.isEmpty ? '' : '?$params'}');
    await refresh();
  }

  Future<void> purchase(String id) async {
    await api.request('POST', '/extras/shop/buy/$id');
    await refresh();
  }

  Future<void> chooseTheme(String name) async {
    final res = await api.request('PUT', '/extras/settings', body: {'theme': name});
    theme = res['theme'] as String? ?? 'default';
    notifyListeners();
  }

  Future<void> setSpeaking(bool enabled) async {
    await api.request('PUT', '/extras/settings', body: {'optional_speaking': enabled});
    optionalSpeaking = enabled;
    notifyListeners();
  }

  /// Base-language localization always works. Adaptive Bashkir is opt-in and
  /// applies only to concepts already learned in actual lessons.
  String tr(String label) {
    final translations = uiCopy[label];
    if (translations == null) return label;
    final base = translations[baseLanguage] ?? translations['ru'] ?? label;
    if (!adaptiveUi) return base;
    final bashkir = translations['ba'] ?? base;
    if (courseFinished) return bashkir;
    final normalized = studiedWords.map((w) => w.trim().toLowerCase()).toSet();
    final phrase = bashkir.toLowerCase();
    if (normalized.contains(phrase)) return bashkir;
    // For multiword controls, all meaningful Bashkir words must have been taught.
    final tokens = phrase.split(RegExp(r'[\s.!?,:;–—]+')).where((w) => w.isNotEmpty);
    if (tokens.isNotEmpty && tokens.every(normalized.contains)) return bashkir;
    return base;
  }

  String adaptText(String message) {
    if (!adaptiveUi || (studiedWords.isEmpty && !courseFinished)) return message;
    final trained = studiedWords.map((w) => w.trim().toLowerCase()).toSet();
    final local = baseLanguage;
    final translations = <String, String>{};
    for (final entry in uiCopy.values) {
      final baseWord = entry[local];
      final target = entry['ba'];
      if (baseWord == null || target == null || baseWord.contains(' ') || target.contains(' ')) continue;
      if (courseFinished || trained.contains(target.toLowerCase())) {
        translations[baseWord.toLowerCase()] = target;
      }
    }
    // Lessons 51–100 supply a second vocabulary source shared with backend,
    // games and the dictionary. Never replace words the user has not studied.
    for (final word in (courseAdaptiveLexicon[local] ?? const <String, String>{}).entries) {
      if (courseFinished || trained.contains(word.value.toLowerCase())) {
        translations.putIfAbsent(word.key, () => word.value);
      }
    }
    if (translations.isEmpty) return message;
    final token = RegExp(r'[A-Za-zА-Яа-яЁёӘәҒғҠҡҢңӨөҮүҘҙҪҫҺһ]+', unicode: true);
    return message.splitMapJoin(token, onMatch: (m) {
      final original = m.group(0)!;
      final translated = translations[original.toLowerCase()];
      if (translated == null) return original;
      final first = original.substring(0, 1);
      return first == first.toUpperCase()
          ? translated[0].toUpperCase() + translated.substring(1)
          : translated;
    }, onNonMatch: (value) => value);
  }

  Future<void> saveLearning({String? language, bool? adaptive, bool? onboarding, bool? public}) async {
    final result = await api.request('PUT', '/extras/learning/preferences', body: {
      if (language != null) 'base_language': language,
      if (adaptive != null) 'adaptive_ui': adaptive,
      if (onboarding != null) 'onboarding_done': onboarding,
      if (public != null) 'public_rank': public,
    });
    baseLanguage = result['base_language'] as String? ?? baseLanguage;
    adaptiveUi = result['adaptive_ui'] == true;
    onboardingDone = result['onboarding_done'] == true;
    publicRank = result['public_rank'] != false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> telegramLink() async => api.request('POST', '/extras/telegram/link');

  Future<void> setRegion(String selected) async {
    await api.request('PUT', '/extras/region', body: {'region': selected});
    region = selected;
    notifyListeners();
  }
}
