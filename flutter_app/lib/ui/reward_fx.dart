import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_confetti/flutter_confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_client.dart';
import '../services/ui_sounds.dart';

final AudioPlayer _rewardPlayer = AudioPlayer();

void showReward(BuildContext context, {int coins = 0, List<dynamic> achievements = const [], ApiClient? api}) {
  final statistics = api != null && achievements.isNotEmpty
    ? api.request('GET', '/extras/analytics/achievements') : null;
  if (!context.mounted || (coins <= 0 && achievements.isEmpty)) return;
  UiSounds.instance.play(coins > 0 ? 'coin' : 'success');
  Confetti.launch(context, options: const ConfettiOptions(particleCount: 85, spread: 95, y: 0.42));
  final title = achievements.isEmpty ? 'Получены монеты!' : 'Новое достижение!';
  const namesMap = <String, String>{
    'first_lesson': 'Первый шаг',
    'three_lessons': 'Любознательный',
    'fifteen_lessons': 'Большой путь',
    'all_lessons': 'Хранитель языка',
    'first_practice': 'Переводчик',
    'five_practices': 'Знаток слов',
    'first_speech': 'Смелый голос',
    'five_speech': 'Оратор',
    'first_game': 'Игрок',
    'ten_games': 'Мастер игр',
    'hundred_coins': 'Собиратель',
  };
  final names = achievements.map((e) => namesMap['$e'] ?? '$e').join(' • ');
  showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    title: TweenAnimationBuilder<double>(tween: Tween(begin: 0.5, end: 1),
      duration: const Duration(milliseconds: 550), curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: child),
      child: const Center(child: Text('🎉🪙', style: TextStyle(fontSize: 62)))),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
      if (coins > 0) Padding(padding: const EdgeInsets.only(top: 10),
        child: Text('+$coins монет', style: const TextStyle(fontSize: 22, color: Color(0xFFB88518), fontWeight: FontWeight.bold))),
      if (names.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(names, textAlign: TextAlign.center)),
      if (statistics != null) FutureBuilder<Map<String,dynamic>>(future: statistics, builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final stats = ((snapshot.data!['items'] as List<dynamic>?) ?? []).whereType<Map<String,dynamic>>().toList();
        return Column(mainAxisSize: MainAxisSize.min, children: [
          for (final entry in stats.where((v) => achievements.contains(v['code'])))
            Padding(padding: const EdgeInsets.only(top: 9), child: Text(
              '🏅 Получили ${entry['count']} из ${entry['total_users']} (${entry['percent']}%) · Топ-регион: ${entry['top_region'] == '' ? 'пока нет' : entry['top_region']}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
        ]);
      }),
    ]),
    actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Афарин!'))],
  ));
}

Future<void> _playRewardAudio() async {
  try {
    final audio = await rootBundle.load('assets/sounds/achievement.wav');
    await _rewardPlayer.stop();
    await _rewardPlayer.play(BytesSource(audio.buffer.asUint8List(), mimeType: 'audio/wav'));
  } catch (_) {
    await SystemSound.play(SystemSoundType.click);
  }
}
