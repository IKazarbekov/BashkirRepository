import 'package:flutter/material.dart';

import '../data/extras_controller.dart';
import '../data/progress_store.dart';

const saveCategories = <String, ({String title, String description, IconData icon})>{
  'lessons': (title: 'Уроки', description: 'Завершённые уроки, XP и серия дней', icon: Icons.school_outlined),
  'games': (title: 'Игры и произношение', description: 'Победы, результаты и монеты за игры', icon: Icons.sports_esports_outlined),
  'practices': (title: 'Практика переводов', description: 'Мои ответы и вклад в общую базу переводов', icon: Icons.translate_rounded),
  'achievements': (title: 'Достижения и награды', description: 'Полученные достижения и бонусные монеты', icon: Icons.emoji_events_outlined),
  'rankings': (title: 'Региональные рейтинги', description: 'Участие в рейтингах и показ публичных результатов', icon: Icons.leaderboard_outlined),
  'favorites': (title: 'Избранные слова', description: 'Личный словарь избранного', icon: Icons.bookmark_outline),
  'purchases': (title: 'Магазин и покупки', description: 'Новые покупки и разблокировки тем и голосов', icon: Icons.shopping_bag_outlined),
};

const gameModeTitles = <String, String>{
  'choice': 'Выбери перевод', 'pairs': 'Найди пары', 'arrange': 'Собери фразу',
  'listen': 'Угадай на слух', 'write': 'Напиши сам', 'speech': 'Произношение',
};

class SaveSettings extends StatefulWidget {
  const SaveSettings({super.key, required this.extras, this.progress, this.showResets = false});
  final ExtrasController extras;
  final ProgressStore? progress;
  final bool showResets;

  @override
  State<SaveSettings> createState() => _SaveSettingsState();
}

class _SaveSettingsState extends State<SaveSettings> {
  String? busy;

  Future<void> toggle(String category, bool value) async {
    if (busy != null) return;
    setState(() => busy = category);
    try {
      await widget.extras.updateSavePreferences({category: value});
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  Future<void> toggleGameMode(String mode, bool value) async {
    if (busy != null) return;
    setState(() => busy = 'game:$mode');
    try {
      await widget.extras.updateSavePreferences({'game_modes': {mode: value}});
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally { if (mounted) setState(() => busy = null); }
  }

  Future<void> resetGameMode(String mode) async {
    if (busy != null) return;
    final approved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Сбросить «${gameModeTitles[mode]}»?'),
      content: const Text('Все сохранённые ответы этого режима будут удалены, но ранее заработанные монеты повторно не выдаются.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сбросить')),
      ],
    ));
    if (approved != true || !mounted) return;
    setState(() => busy = 'game:$mode');
    try {
      await widget.extras.resetSaved('games', mode: mode);
      if (widget.progress != null) await widget.progress!.loadForAccount(widget.extras.api);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally { if (mounted) setState(() => busy = null); }
  }

  Future<void> reset(String category) async {
    if (busy != null) return;
    final label = category == 'all' ? 'весь прогресс и покупки' : saveCategories[category]!.title.toLowerCase();
    final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Сбросить $label?'),
      content: Text(category == 'all'
          ? 'Удалятся результаты уроков, игр, практик, достижения, избранное и покупки. Купленные предметы и монеты не возмещаются. Аккаунт останется.'
          : 'Данные этой категории будут удалены из аккаунта и общих рейтингов. Действие нельзя отменить.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
          child: const Text('Удалить')),
      ],
    ));
    if (accepted != true || !mounted) return;
    setState(() => busy = category);
    try {
      await widget.extras.resetSaved(category);
      if (widget.progress != null) await widget.progress!.loadForAccount(widget.extras.api);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Категория «$label» сброшена')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => busy = null);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.extras,
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Что сохранять в аккаунте', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        const Text('Настройки общие для веба, Android, iOS и привязанного Telegram. '
            'Если сохранение отключено, новые результаты категории не накапливаются на сервере. '
            'Уже сохранённые данные остаются, пока ты их не сбросишь.',
            style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        for (final entry in saveCategories.entries) ...[
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: Icon(entry.value.icon),
            title: Text(entry.value.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(entry.value.description, style: const TextStyle(fontSize: 12)),
            value: widget.extras.savePreferences[entry.key] ?? true,
            onChanged: busy == null ? (v) => toggle(entry.key, v) : null,
          ),
          if (entry.key == 'games') ...[
            const Padding(padding: EdgeInsets.fromLTRB(20, 6, 0, 4),
              child: Text('По режимам игр', style: TextStyle(fontWeight: FontWeight.bold))),
            for (final mode in gameModeTitles.entries)
              Padding(padding: const EdgeInsets.only(left: 18), child: Column(children: [
                SwitchListTile.adaptive(
                  dense: true, title: Text(mode.value),
                  value: widget.extras.gameModePreferences[mode.key] ?? true,
                  onChanged: busy == null && widget.extras.savePreferences['games'] != false
                    ? (v) => toggleGameMode(mode.key, v) : null,
                ),
                if (widget.showResets) Align(alignment: Alignment.centerRight,
                  child: TextButton(onPressed: busy == null ? () => resetGameMode(mode.key) : null,
                    child: const Text('Сбросить режим'))),
              ])),
          ],
          if (widget.showResets)
            Align(alignment: Alignment.centerRight, child: TextButton.icon(
              onPressed: busy == null ? () => reset(entry.key) : null,
              icon: const Icon(Icons.history, size: 17),
              label: const Text('Сбросить сохранённое'),
            )),
        ],
        if (widget.showResets) ...[
          const Divider(height: 22),
          OutlinedButton.icon(
            onPressed: busy == null ? () => reset('all') : null,
            icon: const Icon(Icons.delete_forever_outlined),
            label: const Text('Сбросить весь прогресс и покупки'),
          ),
        ],
      ],
    ),
  );
}
