import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/extras_controller.dart';
import '../data/game_checkpoints.dart';
import '../services/ui_sounds.dart';
import '../data/progress_store.dart';
import '../services/api_client.dart';
import '../services/speech_player.dart';
import 'community_pages.dart';
import 'reward_fx.dart';
import 'word_composer.dart';

const _accent = Color(0xFF227F64);
const _light = Color(0xFFE4F3E9);

class GameModeInfo {
  const GameModeInfo(this.id, this.title, this.details, this.icon, this.length);
  final String id;
  final String title;
  final String details;
  final IconData icon;
  final int length;
}

const _modes = [
  GameModeInfo('choice', 'Выбери перевод', 'Выбирай правильные слова из четырёх ответов', Icons.touch_app_outlined, 172),
  GameModeInfo('pairs', 'Найди пары', 'Соединяй башкирские слова с их значениями', Icons.compare_arrows_rounded, 156),
  GameModeInfo('arrange', 'Собери фразу', 'Составляй предложения из карточек', Icons.view_module_outlined, 48),
  GameModeInfo('listen', 'Угадай на слух', 'Слушай и определяй значение слова', Icons.headphones_rounded, 48),
  GameModeInfo('write', 'Напиши сам', 'Тренируй правописание на башкирском', Icons.edit_note_rounded, 49),
  GameModeInfo('speech', 'Говори смелее', 'Произноси фразы в микрофон и получай обратную связь', Icons.mic_rounded, 50),
];

class GameModesPage extends StatefulWidget {
  const GameModesPage({super.key, required this.api, required this.speech, required this.extras, required this.progress});
  final ApiClient api;
  final SpeechPlayer speech;
  final ExtrasController extras;
  final ProgressStore progress;

  @override State<GameModesPage> createState() => _GameModesPageState();
}

class _GameModesPageState extends State<GameModesPage> {
  final Map<String, Map<String, dynamic>> stats = {};
  bool loading = false;

  @override void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    try {
      final data = await widget.api.request('GET', '/extras/save/games/summary');
      if (mounted) setState(() {
        stats.clear();
        for (final item in (data['items'] as List<dynamic>? ?? [])) {
          if (item is Map<String, dynamic>) stats[item['mode'] as String] = item;
        }
      });
    } catch (_) { /* The games themselves remain available. */ }
    finally { loading = false; }
  }

  Future<void> openMode(GameModeInfo mode) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => mode.id == 'speech'
      ? SpeechGamesPage(api: widget.api, speech: widget.speech,
          extras: widget.extras, progress: widget.progress)
      : MiniGameSessionPage(mode: mode, api: widget.api,
          speech: widget.speech, extras: widget.extras)));
    if (mounted) await refresh();
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.extras.tr('Игры'))),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700),
      child: ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 45), children: [
        Text(widget.extras.tr('Игровая'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        const Text('Выбери, как хочешь тренироваться сегодня.', style: TextStyle(color: Colors.blueGrey)),
        const SizedBox(height: 17),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [_accent, Color(0xFF14654F)]),
          borderRadius: BorderRadius.circular(22)), child: const Row(children: [
          Text('🎮', style: TextStyle(fontSize: 37)), SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('6 режимов · 500+ испытаний', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
            SizedBox(height: 5),
            Text('Результаты сохраняются по режимам. Игры необязательны.', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ])),
        const SizedBox(height: 16),
        for (final mode in _modes) Padding(padding: const EdgeInsets.only(bottom: 11),
          child: Material(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(18),
            child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () => openMode(mode),
              child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(
                border: Border.all(color: _light), borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Container(width: 54, height: 54,
                    decoration: BoxDecoration(color: _light, borderRadius: BorderRadius.circular(17)),
                    child: Icon(mode.icon, color: _accent, size: 27)),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.extras.tr(mode.title), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(mode.details, style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(stats[mode.id] == null
                        ? '${mode.length} заданий'
                        : '${stats[mode.id]!['completed']} из ${stats[mode.id]!['total']} правильных ответов · ${((stats[mode.id]!['checkpoint'] as num?)?.toInt() ?? 0) > 0 ? 'Сохранено задание ${(stats[mode.id]!['checkpoint'] as num).toInt() + 1}' : stats[mode.id]!['finished'] == true ? 'Завершено ✓' : 'В процессе'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _accent)),
                  ])),
                  const Icon(Icons.chevron_right, color: _accent),
                ]))))),
      ]))));
}

class MiniGameSessionPage extends StatefulWidget {
  const MiniGameSessionPage({super.key, required this.mode, required this.api, required this.speech, required this.extras});
  final GameModeInfo mode;
  final ApiClient api;
  final SpeechPlayer speech;
  final ExtrasController extras;

  @override
  State<MiniGameSessionPage> createState() => _MiniGameSessionPageState();
}

class _MiniGameSessionPageState extends State<MiniGameSessionPage> {
  final answerController = TextEditingController();
  final List<int> assembled = [];
  final Set<String> matchedLeft = {};
  late Future<List<Map<String, dynamic>>> loading;
  int step = 0;
  String difficulty = 'medium';
  bool startMenu = true, checkingSession = true, hasCheckpoint = false;
  Map<String, dynamic> savedSession = {};
  String? chosen, leftChoice, rightChoice;
  String? response;
  bool busy = false, success = false;
  int earned = 0, rightAnswers = 0;
  late final GameCheckpointRepository checkpoints;
  bool savingEnabled = true;
  String? syncWarning;

  @override void initState() {
    super.initState();
    loading = Future.value(<Map<String, dynamic>>[]);
    checkpoints = GameCheckpointRepository(widget.api, widget.mode.id);
    fetchCheckpoint();
  }

  Future<void> fetchCheckpoint() async {
    try {
      final record = await checkpoints.load();
      if (!mounted) return;
      setState(() {
        savedSession = record;
        difficulty = record['difficulty'] as String? ?? 'medium';
        hasCheckpoint = record['has_checkpoint'] == true || (record['step'] as num? ?? 0) > 0;
        checkingSession = false;
        savingEnabled = record['saving_enabled'] != false;
        syncWarning = checkpoints.error;
      });
    } catch (_) {
      if (mounted) setState(() => checkingSession = false);
    }
  }

  Future<void> saveCheckpoint() async {
    await checkpoints.save({
      'difficulty': difficulty, 'step': step,
      'matched': matchedLeft.toList(), 'right_answers': rightAnswers,
      'earned_display': earned,
    }, enabled: savingEnabled);
    if (mounted) setState(() => syncWarning = checkpoints.error);
  }

  Future<void> start({required bool resume}) async {
    if (!resume) {
      try { await checkpoints.clear(); }
      catch (error) { if (mounted) setState(() => syncWarning = '$error'); }
    }
    if (!mounted) return;
    setState(() {
      step = resume ? (savedSession['step'] as num?)?.toInt() ?? 0 : 0;
      rightAnswers = resume ? (savedSession['right_answers'] as num?)?.toInt() ?? 0 : 0;
      earned = resume ? (savedSession['earned_display'] as num?)?.toInt() ?? 0 : 0;
      matchedLeft.clear();
      if (resume) matchedLeft.addAll((savedSession['matched'] as List<dynamic>? ?? []).whereType<String>());
      startMenu = false;
      loading = widget.api.request('GET', '/extras/mini-games?mode=${widget.mode.id}&difficulty=$difficulty')
        .then((data) => (data['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>().toList());
    });
    await saveCheckpoint();
  }

  Future<void> changeDifficulty(String value) async {
    if (value == difficulty) return;
    if (hasCheckpoint) {
      final accepted = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Изменить сложность?'),
        content: const Text('Текущая игровая сессия начнётся с первого задания. Ранее начисленные монеты сохранятся.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Изменить')),
        ],
      ));
      if (accepted != true || !mounted) return;
      try { await checkpoints.clear(); }
      catch (error) { if (mounted) setState(() => syncWarning = '$error'); }
      hasCheckpoint = false;
      savedSession = {};
    }
    if (!mounted) return;
    setState(() => difficulty = value);
    await saveCheckpoint();
  }

  Widget gameStart() => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
      Icon(widget.mode.icon, size: 52, color: _accent),
      const SizedBox(height: 12),
      Text(widget.mode.title, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 5),
      Text(widget.mode.details, textAlign: TextAlign.center),
      const SizedBox(height: 24),
      const Text('Сложность', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegmentedButton<String>(
        showSelectedIcon: false, selected: {difficulty},
        onSelectionChanged: (values) => changeDifficulty(values.first),
        segments: const [
          ButtonSegment(value: 'easy', label: Text('Лёгкая')),
          ButtonSegment(value: 'medium', label: Text('Средняя')),
          ButtonSegment(value: 'hard', label: Text('Сложная')),
        ],
      )),
      const SizedBox(height: 9),
      Text(difficulty == 'hard'
        ? 'Больше похожих ответов и лишних слов в предложениях.'
        : difficulty == 'easy'
          ? 'Меньше вариантов, меньше пар и подсказки.'
          : 'Полный набор вариантов и дополнительные слова в фразах.',
        style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
      const SizedBox(height: 22),
      if (hasCheckpoint) ...[
        FilledButton.icon(onPressed: () => start(resume: true),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Продолжить с задания ${((savedSession['step'] as num?)?.toInt() ?? 0) + 1}')),
        const SizedBox(height: 9),
        OutlinedButton.icon(onPressed: () => start(resume: false),
          icon: const Icon(Icons.replay_rounded), label: const Text('Начать заново')),
        const SizedBox(height: 7),
        TextButton.icon(onPressed: () async {
          final yes = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
            title: const Text('Удалить результаты режима?'),
            content: const Text('Будут удалены сохранённые ответы, достижения и контрольная точка этого режима. Уже выданные монеты повторно не начислятся.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Отмена')),
              FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Сбросить')),
            ],
          ));
          if (yes != true || !mounted) return;
          try {
            await widget.extras.resetSaved('games', mode: widget.mode.id);
            if (mounted) setState(() { hasCheckpoint = false; savedSession = {}; });
          } catch (error) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
          }
        }, icon: const Icon(Icons.delete_outline), label: const Text('Сбросить прогресс этого режима')),
      ] else FilledButton.icon(onPressed: () => start(resume: false),
        icon: const Icon(Icons.play_arrow_rounded), label: const Text('Начать игру')),
      if (!savingEnabled) const Text('Сохранение этого режима отключено в профиле.', style: TextStyle(color: Colors.deepOrange)),
      if (syncWarning != null) Text(syncWarning!, style: const TextStyle(color: Colors.deepOrange)),
      const SizedBox(height: 11),
      const Text('Результаты записываются на аккаунт, если сохранения этого режима включены в профиле.',
        textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
    ])));

  @override void dispose() {
    answerController.dispose();
    super.dispose();
  }

  void next() {
    UiSounds.instance.play('next');
    setState(() {
      step++;
      chosen = null; leftChoice = null; rightChoice = null;
      response = null; success = false;
      assembled.clear(); matchedLeft.clear(); answerController.clear();
    });
    saveCheckpoint();
  }

  Future<void> submit(Map<String, dynamic> task, String answer, {String? matchingWord}) async {
    if (busy || answer.trim().isEmpty || success) return;
    setState(() { busy = true; response = null; });
    try {
      final result = await widget.api.request('POST', '/extras/mini-games/${widget.mode.id}/${task['id']}/answer',
        body: {'answer': answer});
      if (!mounted) return;
      if (result['success'] == true) {
        final got = (result['earned_coins'] as num?)?.toInt() ?? 0;
        earned += got;
        rightAnswers++;
        final achievements = result['new_achievements'] as List<dynamic>? ?? [];
        if (achievements.isNotEmpty) showReward(context, achievements: achievements, coins: got, api: widget.extras.api);
        if (matchingWord != null) {
          matchedLeft.add(matchingWord);
          leftChoice = null; rightChoice = null;
          response = '+$got 🪙 · Пара найдена!';
          if (matchedLeft.length >= (task['left'] as List).length) success = true;
        } else {
          success = true;
          response = '+$got 🪙 · Верно! Афарин!';
        }
        await widget.extras.refresh();
        UiSounds.instance.play(got > 0 ? 'coin' : 'success');
        await saveCheckpoint();
      } else {
        UiSounds.instance.play('error');
        response = 'Пока неверно. Попробуй ещё раз!';
        leftChoice = null; rightChoice = null;
      }
    } catch (error) {
      if (mounted) response = 'Не удалось проверить ответ: $error';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void pairTap(Map<String, dynamic> task, String word, {required bool isLeft}) {
    if (busy || success) return;
    setState(() {
      if (isLeft) leftChoice = word;
      else rightChoice = word;
    });
    if (leftChoice != null && rightChoice != null) {
      submit(task, jsonEncode([leftChoice, rightChoice]), matchingWord: leftChoice);
    }
  }

  Widget _answers(Map<String, dynamic> task) {
    if (widget.mode.id == 'pairs') {
      final left = (task['left'] as List<dynamic>).cast<String>();
      final right = (task['right'] as List<dynamic>).cast<String>();
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final side in [true, false]) Expanded(child: Padding(
          padding: EdgeInsets.only(right: side ? 6 : 0, left: side ? 0 : 6),
          child: Column(children: [for (final word in (side ? left : right))
            Padding(padding: const EdgeInsets.only(bottom: 9), child: _answerTile(
              word, matchedLeft.contains(side ? word : _pairLeft(task, word)),
              (side ? leftChoice : rightChoice) == word,
              () => pairTap(task, word, isLeft: side)))],
          ),
        ))
      ]);
    }
    if (widget.mode.id == 'write') {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (task['word_length'] != null) Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(task['first_letter'] != null
            ? 'Подсказка: первая буква «${task['first_letter']}», символов: ${task['word_length']}'
            : 'Подсказка: ${task['word_length']} символов',
            style: const TextStyle(color: Colors.blueGrey))),
        TextField(controller: answerController, maxLength: 100,
        decoration: InputDecoration(labelText: widget.extras.tr('Напиши ответ на башкирском'),
          border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.keyboard)),
        onSubmitted: (_) => submit(task, answerController.text),
      )]);
    }
    if (widget.mode.id == 'arrange') {
      return WordComposer(
        key: ValueKey('game_${widget.mode.id}_$step'),
        words: (task['words'] as List<dynamic>).cast<String>(),
        selected: assembled,
        enabled: !busy && !success,
        onAdd: (index) => setState(() { if (!assembled.contains(index)) assembled.add(index); }),
        onRemove: (index) => setState(() => assembled.remove(index)),
      );
    }
    return Column(children: [for (final answer in (task['options'] as List<dynamic>).cast<String>())
      Padding(padding: const EdgeInsets.only(bottom: 9), child: _answerTile(answer, false, chosen == answer,
        () => setState(() => chosen = answer))),
    ]);
  }

  String _pairLeft(Map<String, dynamic> task, String right) {
    final left = (task['left'] as List<dynamic>).cast<String>();
    final rights = (task['right'] as List<dynamic>).cast<String>();
    // A client cannot infer the correspondence from the displayed order;
    // only confirmed answers in matchedLeft are hidden on both sides.
    // The right column is reversed; this method is for confirmed tiles only.
    final i = rights.indexOf(right);
    return i >= 0 && i < left.length ? left[left.length - 1 - i] : '';
  }

  Widget _answerTile(String word, bool matched, bool selected, VoidCallback onTap) =>
    SizedBox(width: double.infinity, child: OutlinedButton(
      onPressed: matched || busy || success ? null : onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
        backgroundColor: matched ? _light : selected ? const Color(0xFFDBEFE5) : null,
        side: BorderSide(color: selected || matched ? _accent : Colors.black12,
          width: selected ? 2 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(matched ? '✓ $word' : word, textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w800)),
    ));

  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.extras.tr(widget.mode.title))),
      body: checkingSession ? const Center(child: CircularProgressIndicator())
        : startMenu ? gameStart() : FutureBuilder<List<Map<String, dynamic>>>(future: loading, builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Text('Не удалось загрузить задания: ${snapshot.error}')));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final tasks = snapshot.data!;
        if (tasks.isEmpty) return const Center(child: Text('Пока нет заданий'));
        if (step >= tasks.length) return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(padding: const EdgeInsets.all(25), child: Column(
            mainAxisSize: MainAxisSize.min, children: [
              const Text('🏆', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 15),
              const Text('Афарин! Игра завершена', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Правильных ответов: $rightAnswers · Заработано: $earned 🪙'),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: () async {
                final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Сбросить результаты режима?'),
                  content: Text('Сбросить сохранённые результаты режима «${widget.mode.title}»?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сбросить')),
                  ],
                ));
                if (accepted != true || !mounted) return;
                try {
                  await widget.extras.resetSaved('games', mode: widget.mode.id);
                  await checkpoints.clear();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                }
              }, icon: const Icon(Icons.restart_alt), label: const Text('Сбросить прогресс режима')),
              const SizedBox(height: 13),
              FilledButton.icon(onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back), label: Text(widget.extras.tr('Выбери новую игру'))),
            ])),
        ));
        final task = tasks[step];
        final mode = widget.mode.id;
        final answer = mode == 'arrange'
          ? assembled.map((i) => (task['words'] as List<dynamic>)[i]).join(' ')
          : mode == 'write' ? answerController.text : chosen ?? '';
        return Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 590),
          child: ListView(padding: const EdgeInsets.all(21), children: [
            LinearProgressIndicator(value: (step + (success ? 1 : 0)) / tasks.length, minHeight: 8,
              borderRadius: BorderRadius.circular(10)),
            const SizedBox(height: 9),
            Text('Задание ${step + 1} из ${tasks.length}', style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 22),
            Icon(widget.mode.icon, size: 63, color: _accent),
            const SizedBox(height: 16),
            Text(mode == 'pairs' ? widget.extras.tr('Найди подходящие пары') : '${task['prompt']}',
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            if (mode == 'listen') ...[
              const SizedBox(height: 17),
              Center(child: FilledButton.icon(onPressed: () async {
                try { await widget.speech.speak('${task['audio_text']}', language: 'bak', speaker: 'bak_aigul'); }
                catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); }
              }, icon: const Icon(Icons.volume_up), label: Text(widget.extras.tr('Слушать слово')))),
            ],
            const SizedBox(height: 24),
            _answers(task),
            const SizedBox(height: 15),
            if (response != null) AnimatedSwitcher(duration: const Duration(milliseconds: 250),
              child: Container(key: ValueKey(response), padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(color: response!.contains('Верно') || response!.contains('найдена') ? _light : const Color(0xFFFFF0E3),
                  borderRadius: BorderRadius.circular(12)),
                child: Text(response!, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)))),
            const SizedBox(height: 11),
            if (success) FilledButton.icon(onPressed: next, icon: const Icon(Icons.arrow_forward),
              label: Text(widget.extras.tr(step == tasks.length - 1 ? 'Завершить игру' : 'Следующее задание')))
            else if (mode != 'pairs') FilledButton.icon(
              onPressed: busy || answer.trim().isEmpty ? null : () => submit(task, answer),
              icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_circle_outline), label: Text(widget.extras.tr('Проверить ответ'))),
            const SizedBox(height: 11),
            OutlinedButton.icon(onPressed: busy ? null : next, icon: const Icon(Icons.skip_next),
              label: Text(widget.extras.tr('Пропустить без штрафа'))),
            const SizedBox(height: 7),
            const Text('Монеты за правильный ответ выдаются один раз в день за каждое задание.',
              style: TextStyle(fontSize: 11, color: Colors.blueGrey), textAlign: TextAlign.center),
          ])),
        );
      }));
  }
}
