import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../data/extras_controller.dart';
import '../data/game_checkpoints.dart';
import '../data/progress_store.dart';
import '../data/lessons.dart';
import '../services/api_client.dart';
import '../services/audio_recording.dart';
import '../services/speech_player.dart';
import 'reward_fx.dart';
import 'mascot.dart';
import 'regional_map.dart';
import 'admin_tools.dart';
import 'cheat_mode.dart';

const sea = Color(0xFF227F64);

void feedback(BuildContext context, Object e) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.extras, this.progress});
  final ExtrasController extras;
  final ProgressStore? progress;
  @override State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String? loading;
  Future<void> applyItem(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    try {
      if (item['kind'] == 'theme') {
        await widget.extras.chooseTheme(id.substring('theme_'.length));
      } else if (item['kind'] == 'voice') {
        final progress = widget.progress;
        if (progress == null) {
          feedback(context, 'Открой настройки озвучки, чтобы выбрать голос');
          return;
        }
        const voices = {
          'voice_bak_alfia2': ['bak', 'bak_alfia2'],
          'voice_bak_ramilia': ['bak', 'bak_ramilia'],
          'voice_tat_marat': ['tat', 'tat_marat'],
          'voice_tat': ['tat', 'tat_albina'],
          'voice_kaz': ['kaz', 'kaz_zhadyra'],
          'voice_ru': ['ru', 'ru_zhadyra'],
          'voices_all': ['bak', 'bak_ramilia'],
        };
        final chosen = voices[id];
        if (chosen != null) await progress.changeVoice(chosen[0], chosen[1]);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item['name']} — применено ✓')));
    } catch (error) {
      if (mounted) feedback(context, error);
    }
  }

  Future<void> buy(Map<String, dynamic> item) async {
    final id = item['id'] as String;
    setState(() => loading = id);
    try {
      await widget.extras.purchase(id);
      if (!mounted) return;
      final applyNow = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Покупка успешна! 🎉'),
        content: Text('${item['name']} теперь доступно навсегда для этого аккаунта. Применить сейчас?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Позже')),
          FilledButton.icon(onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check_circle_outline), label: const Text('Применить')),
        ],
      ));
      if (applyNow == true && mounted) await applyItem(item);
    } catch (e) { if (mounted) feedback(context, e); }
    finally { if (mounted) setState(() => loading = null); }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Магазин')),
      body: AnimatedBuilder(animation: widget.extras, builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20), children: [
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [
            const Text('🪙', style: TextStyle(fontSize: 34)), const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Мои монеты', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${widget.extras.coins}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
            ])),
          ]))),
          const SizedBox(height: 10),
          const Text('Зарабатывай монеты за уроки, ежедневные переводы и игры с произношением.'),
          const SizedBox(height: 18),
          for (final item in widget.extras.shop) ...[
            Card(child: ListTile(
              leading: Text(item['icon'] as String? ?? '🎁', style: const TextStyle(fontSize: 28)),
              title: Text(item['name'] as String? ?? ''),
              subtitle: Text(item['owned'] == true ? 'Разблокировано' : '${item['price']} монет'),
              trailing: item['owned'] == true ? FilledButton.tonalIcon(
                onPressed: loading != null ? null : () => applyItem(item),
                icon: const Icon(Icons.check_rounded, size: 17),
                label: const Text('Применить')) :
                FilledButton.tonal(onPressed: loading != null ? null : () => buy(item),
                  child: loading == item['id'] ? const SizedBox(width: 15, height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Купить')),
            )),
          ],
          const SizedBox(height: 12),
          const Text('Это внутриигровые монеты, без оплаты настоящими деньгами.',
            style: TextStyle(fontSize: 12)),
        ],
      )));
  }
}

class AwardsPage extends StatefulWidget {
  const AwardsPage({super.key, required this.extras, required this.progress, this.section = 'all'});
  final ExtrasController extras;
  final ProgressStore progress;
  final String section;
  @override State<AwardsPage> createState() => _AwardsPageState();
}

class _AwardsPageState extends State<AwardsPage> {
  bool sending = false;
  Map<String, Map<String, dynamic>> population = {};

  @override void initState() { super.initState(); loadPopulation(); }
  Future<void> loadPopulation() async {
    try {
      final data = await widget.extras.api.request('GET', '/extras/analytics/achievements');
      if (mounted) setState(() => population = {
        for (final entry in ((data['items'] as List<dynamic>?) ?? []).whereType<Map<String,dynamic>>())
          entry['code'] as String: entry,
      });
    } catch (_) { /* Aggregate information is optional when API is offline. */ }
  }
  String statistics(String code) {
    final data = population[code];
    if (data == null) return 'Статистика появится при подключении к серверу';
    final label = code == 'night_project' ? 'Ключи действительно выданы' : 'Получили';
    return '$label: ${data['count']} из ${data['total_users']} (${data['percent']}%) · Лидер: ${data['top_region'] == '' ? 'пока нет' : data['top_region']} (${data['top_region_count']})';
  }
  Future<void> requestKeys() async {
    final email = TextEditingController();
    final emailAddress = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Четыре ключа Night Project'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Я выполнил все задания на башкирском. Укажи почту, на которую создатель сможет прислать четыре ключа.'),
        const SizedBox(height: 13),
        TextField(controller: email, keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Электронная почта', border: OutlineInputBorder())),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(ctx, email.text.trim()), child: const Text('Отправить заявку'))],
    ));
    email.dispose();
    if (emailAddress == null || emailAddress.isEmpty || !mounted) return;
    setState(() => sending = true);
    try {
      final result = await widget.extras.api.request('POST', '/extras/course/redeem', body: {'email': emailAddress});
      await widget.extras.refresh();
      if (mounted) feedback(context, result['status'] == 'sent' ? 'Заявка отправлена!' : 'Заявка уже была отправлена');
    } catch (e) {
      if (mounted) {
        feedback(context, e);
        if ('$e'.contains('SMTP')) {
          final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Отправка по почте'),
            content: const Text('SMTP ещё не настроен. Можно открыть почтовое приложение и отправить письмо самостоятельно. Это не автоматическая отправка.'),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Позже')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Открыть почту'))],
          ));
          if (confirm == true) {
            final username = await widget.extras.api.request('GET', '/me');
            final body = 'Я выполнил все задания на башкирском, мой юзер @${username['username']}.\nПочта: $emailAddress';
            final uri = Uri(scheme: 'mailto', path: 'mysterystudios444@gmail.com',
              queryParameters: {'subject': 'Награда Night Project', 'body': body});
            await launchUrl(uri);
          }
        }
      }
    } finally { if (mounted) setState(() => sending = false); }
  }

  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(widget.section == 'achievements' ? 'Достижения' : 'Награды')),
      body: AnimatedBuilder(animation: widget.extras, builder: (context, _) {
        final done = widget.progress.completed.length >= 100;
        return ListView(padding: const EdgeInsets.all(19), children: [
          if (widget.section != 'rewards') ...[
          const Text('Достижения', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('За новые достижения ты получаешь монеты автоматически.'),
          const SizedBox(height: 17),
          for (final item in widget.extras.achievements) Card(child: ListTile(
            leading: Text(item['unlocked'] == true ? '${item['icon']}' : '🔒', style: const TextStyle(fontSize: 27)),
            title: Text(item['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${item['condition']} · +${item['coins']} монет\n${statistics(item['code'] as String)}"),
            isThreeLine: true,
            trailing: Icon(item['unlocked'] == true ? Icons.check_circle : Icons.lock_outline,
              color: item['unlocked'] == true ? sea : Colors.grey),
          )),
          ],
          if (widget.section != 'achievements') ...[
          const SizedBox(height: 16),
          const Text('Как зарабатывать монеты',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Все награды в приложении виртуальные. Они начисляются сервером после подтверждённого действия.'),
          const SizedBox(height: 12),
          for (final bonus in const [
            ('📗', 'Основной урок', '+15 монет за первое прохождение'),
            ('🗣️', 'Правильное произношение', '+12 монет за уникальную попытку дня'),
            ('🎮', 'Мини-игра', '+5 монет за уникальный правильный ответ дня'),
            ('✍️', 'Практика перевода', '+8 монет за новый фрагмент'),
            ('📘', 'Дополнительный урок', '+10 монет за полное выполнение'),
          ]) Card(child: ListTile(
            leading: Text(bonus.$1, style: const TextStyle(fontSize: 23)),
            title: Text(bonus.$2, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(bonus.$3))),
          const SizedBox(height: 13),
          const Text('Награды за достижения',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const Text('Нажми на каждое достижение, чтобы увидеть условие и долю пользователей, которые уже его получили.'),
          for (final item in widget.extras.achievements) Card(child: ListTile(
            leading: Text(item['unlocked'] == true ? '${item['icon']}' : '🔒',
              style: const TextStyle(fontSize: 22)),
            title: Text('${item['name']} · +${item['coins']} 🪙',
              style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${item['condition']}\n${statistics(item['code'] as String)}'),
            isThreeLine: true,
            trailing: Icon(item['unlocked'] == true ? Icons.verified : Icons.lock_outline,
              color: item['unlocked'] == true ? sea : Colors.grey))),
          const SizedBox(height: 19),
          Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            const Text('🌌 Night Project', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Особая награда: 4 ключа на 4 главы Night Project за прохождение всего основного курса.', textAlign: TextAlign.center),
            const SizedBox(height: 13),
            LinearProgressIndicator(value: (widget.progress.completed.length / lessons.length).clamp(0.0, 1.0)),
            const SizedBox(height: 9),
            Text('${widget.progress.completed.length}/100 уроков'),
            const SizedBox(height: 6),
            Text(statistics('night_project'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 13),
            FilledButton.icon(onPressed: done && !sending && !widget.extras.courseRewardClaimed ? requestKeys : null,
              icon: Icon(widget.extras.courseRewardClaimed ? Icons.check : done ? Icons.mail : Icons.lock),
              label: Text(widget.extras.courseRewardClaimed ? 'Заявка отправлена' : done ? 'Получить награду' : 'Пока закрыто')),
          ]))),
          ],
        ]);
      }));
  }
}

class RegionLeaderboardPage extends StatefulWidget {
  const RegionLeaderboardPage({super.key, required this.api, required this.extras});
  final ApiClient api;
  final ExtrasController extras;
  @override State<RegionLeaderboardPage> createState() => _RegionLeaderboardPageState();
}
class _RegionLeaderboardPageState extends State<RegionLeaderboardPage> {
  String scope = 'region', metric = 'lessons', period = 'all', selectedRegion = '';
  final GlobalKey _mapAnchor = GlobalKey();
  List<dynamic> entries = [];
  List<String> regions = [];
  bool busy = true;

  @override void initState() { super.initState(); reload(); }

  void _scrollToMap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _mapAnchor.currentContext;
      if (!mounted || target == null) return;
      Scrollable.ensureVisible(target,
        alignment: 0.10,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic);
    });
  }
  Future<void> reload() async {
    setState(() => busy = true);
    try {
      if (regions.isEmpty) {
        final locations = await widget.api.request('GET', '/extras/regions');
        regions = ((locations['regions'] as List<dynamic>?) ?? []).whereType<String>().toList();
      }
      final query = Uri(queryParameters: {'scope': scope, 'metric': metric,
        'period': period, if (selectedRegion.isNotEmpty) 'region': selectedRegion}).query;
      final result = await widget.api.request('GET', '/extras/leaderboard?$query');
      if (mounted) setState(() => entries = result['items'] as List<dynamic>? ?? []);
    } catch (e) { if (mounted) feedback(context, e); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Widget dropdown(String value, Map<String, String> items, ValueChanged<String> set) =>
    DropdownButtonFormField<String>(value: value, isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      items: [for (final pair in items.entries) DropdownMenuItem(value: pair.key, child: Text(pair.value, overflow: TextOverflow.ellipsis))],
      onChanged: (v) { if (v != null) { set(v); reload(); }});

  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Рейтинги')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text('Региональные достижения', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Все показатели считаются по фактическим действиям пользователей в общей базе.'),
        const SizedBox(height: 10),
        Container(key: _mapAnchor, child: RegionalMapPanel(api: widget.api, metric: metric,
          onRegionSelected: (name) {
            setState(() { scope = 'users'; selectedRegion = name; });
            reload();
          })),
        const SizedBox(height: 14),
        dropdown(scope, const {'region':'Регионы', 'users':'Пользователи', 'class':'Классы', 'school':'Школы'},
          (v) => setState(() => scope = v)),
        const SizedBox(height: 8),
        dropdown(metric, const {'lessons':'Завершённые уроки', 'practices':'Практики переводов',
          'speaking':'Успешное произношение', 'games':'Победы в играх', 'tasks':'Всего заданий', 'achievements':'Достижения', 'coins':'Заработано монет', 'xp':'Опыт XP'},
          (v) => setState(() => metric = v)),
        const SizedBox(height: 8),
        dropdown(period, const {'all':'За всё время', 'day':'За день', 'week':'За неделю',
          'month':'За месяц', 'year':'За год'}, (v) => setState(() => period = v)),
        const SizedBox(height: 8),
        if (scope == 'users') dropdown(selectedRegion, {'':'Все регионы', for (final region in regions) region:region},
          (v) {
            setState(() => selectedRegion = v);
            if (v.isNotEmpty) _scrollToMap();
          }),
        const SizedBox(height: 15),
        if (busy) const Center(child: CircularProgressIndicator()) else if (entries.isEmpty)
          const Padding(padding: EdgeInsets.all(28), child: Text('Пока недостаточно данных. Пройди урок или практику!'))
        else for (final entry in entries.whereType<Map<String, dynamic>>())
          Card(child: ListTile(leading: CircleAvatar(child: Text('${entry['rank']}')),
            title: Text(entry['name'] as String? ?? ''),
            trailing: Text('${entry['value']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)))),
      ]));
  }
}

class SpeechGamesPage extends StatefulWidget {
  const SpeechGamesPage({super.key, required this.api, required this.speech,
    required this.extras, required this.progress});
  final ApiClient api;
  final SpeechPlayer speech;
  final ExtrasController extras;
  final ProgressStore progress;
  @override State<SpeechGamesPage> createState() => _SpeechGamesPageState();
}
class _SpeechGamesPageState extends State<SpeechGamesPage> with SingleTickerProviderStateMixin {
  late final PronunciationRecorder recorder;
  late final AnimationController pulse;
  List<Map<String, dynamic>> games = [];
  int selected = 0;
  bool recording = false, busy = false, asr = false, completed = false;
  bool preflight = true, loadingSession = true, gamesLoading = true, hasCheckpoint = false;
  String difficulty = 'medium';
  int previousStep = 0;
  late final GameCheckpointRepository speechCheckpoints;
  String? checkpointWarning;
  bool savingEnabled = true;
  String? result;
  @override void initState() {
    super.initState();
    speechCheckpoints = GameCheckpointRepository(widget.api, 'speech');
    recorder = PronunciationRecorder();
    pulse = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 850))..repeat(reverse: true);
    load();
    loadCheckpoint();
  }
  @override void dispose() { pulse.dispose(); recorder.dispose(); super.dispose(); }
  Future<void> load() async {
    try {
      final data = await widget.api.request('GET', '/extras/games');
      if (mounted) setState(() {
        asr = data['asr_installed'] == true;
        games = (data['items'] as List<dynamic>).whereType<Map<String, dynamic>>().toList();
      });
    } catch (e) { if (mounted) feedback(context, e); }
    finally { if (mounted) setState(() => gamesLoading = false); }
  }
  Future<void> loadCheckpoint() async {
    try {
      final data = await speechCheckpoints.load();
      if (mounted) setState(() {
        difficulty = data['difficulty'] as String? ?? 'medium';
        previousStep = (data['step'] as num?)?.toInt() ?? 0;
        hasCheckpoint = previousStep > 0;
        loadingSession = false;
        checkpointWarning = speechCheckpoints.error;
        savingEnabled = data['saving_enabled'] != false;
      });
    } catch (_) { if (mounted) setState(() => loadingSession = false); }
  }

  Future<void> persist() async {
    await speechCheckpoints.save({
      'difficulty': difficulty, 'step': selected,
      'matched': <String>[], 'right_answers': 0, 'earned_display': 0,
    }, enabled: savingEnabled);
    if (mounted) setState(() => checkpointWarning = speechCheckpoints.error);
  }

  Future<void> begin(bool resume) async {
    if (!resume) {
      try { await speechCheckpoints.clear(); }
      catch (e) { if (mounted) setState(() => checkpointWarning = '$e'); }
    }
    if (mounted) setState(() {
      selected = resume && games.isNotEmpty ? previousStep.clamp(0, games.length) : 0;
      completed = selected >= games.length && games.isNotEmpty;
      preflight = false;
      result = null;
    });
    await persist();
  }

  Future<void> setDifficulty(String next) async {
    if (difficulty == next) return;
    if (hasCheckpoint) {
      final yes = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Изменить сложность?'),
        content: const Text('Текущая сессия будет начата заново, без повторной выдачи монет.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Продолжить')),
        ],
      ));
      if (yes != true || !mounted) return;
      try { await speechCheckpoints.clear(); }
      catch (e) { if (mounted) setState(() => checkpointWarning = '$e'); }
      hasCheckpoint = false;
      previousStep = 0;
    }
    if (mounted) setState(() => difficulty = next);
    await persist();
  }

  Widget startMenu() => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 520),
    child: ListView(padding: const EdgeInsets.all(24), shrinkWrap: true, children: [
      const Icon(Icons.record_voice_over_outlined, size: 64, color: sea),
      const SizedBox(height: 9),
      const Text('Тренировка произношения', textAlign: TextAlign.center,
        style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      const Text('Произнеси башкирскую фразу и узнай, насколько близко она была распознана.',
        textAlign: TextAlign.center),
      const SizedBox(height: 17),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: SegmentedButton<String>(selected: {difficulty}, showSelectedIcon: false,
        onSelectionChanged: (choice) => setDifficulty(choice.first),
        segments: const [
          ButtonSegment(value: 'easy', label: Text('Лёгкая')),
          ButtonSegment(value: 'medium', label: Text('Средняя')),
          ButtonSegment(value: 'hard', label: Text('Сложная')),
        ])),
      const SizedBox(height: 12),
      Text(difficulty == 'easy' ? 'Допуск распознавания 62%.'
        : difficulty == 'medium' ? 'Допуск распознавания 72%.' : 'Допуск распознавания 86%.',
        textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey)),
      const SizedBox(height: 18),
      if (checkpointWarning != null) Padding(padding: const EdgeInsets.all(9),
        child: Text(checkpointWarning!, style: const TextStyle(color: Colors.deepOrange))),
      if (!savingEnabled) const Text('Сохранения произношения отключены в профиле.'),
      if (hasCheckpoint) ...[
        FilledButton.icon(onPressed: () => begin(true), icon: const Icon(Icons.play_arrow),
          label: Text(previousStep >= games.length && games.isNotEmpty ? 'Посмотреть результат' : 'Продолжить с задания ${previousStep + 1}')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () => begin(false), icon: const Icon(Icons.replay),
          label: const Text('Начать заново')),
      ] else FilledButton.icon(onPressed: () => begin(false), icon: const Icon(Icons.play_arrow),
        label: const Text('Начать')),
      const SizedBox(height: 12),
      const Text('Игры с речью необязательны. Автоматическое распознавание не оценивает акцент.',
        textAlign: TextAlign.center),
    ])));

  Future<void> microphone() async {
    if (busy || games.isEmpty) return;
    if (!recording) {
      try { await recorder.start(); if (mounted) setState(() {recording = true; result = null;}); }
      catch (e) { if (mounted) feedback(context, e); }
      return;
    }
    setState(() { recording = false; busy = true; });
    try {
      final wav = await recorder.stop();
      final game = games[selected];
      final answer = await widget.api.uploadSpeech((game['id'] as num).toInt(), wav);
      if (answer['success'] == true) {
        await widget.extras.refresh();
        if (mounted) {
          showReward(context, coins: (answer['earned_coins'] as num?)?.toInt() ?? 0,
            achievements: answer['new_achievements'] as List<dynamic>? ?? [], api: widget.extras.api);
          setState(() => result = 'Верно! Афарин! Распознано: ${answer['recognized']}');
          Future<void>.delayed(const Duration(milliseconds: 1050), () {
            if (!mounted) return;
            setState(() {
              if (selected + 1 < games.length) { selected++; result = null; }
              else { selected = games.length; completed = true; }
            });
            persist();
          });
        }
      } else {
        if (mounted) setState(() => result = 'Пока не совпало: ${answer['recognized']}. Попробуй ещё раз или пропусти.');
      }
    } catch (e) { if (mounted) feedback(context, e); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override Widget build(BuildContext context) {
    final game = games.isEmpty ? null : games[selected.clamp(0, games.length - 1)];
    return Scaffold(appBar: AppBar(title: const Text('Игры: произношение')),
      body: loadingSession || gamesLoading ? const Center(child: CircularProgressIndicator())
        : games.isEmpty ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Не удалось получить задания произношения'),
            OutlinedButton(onPressed: () { setState(() => gamesLoading = true); load(); },
              child: const Text('Повторить загрузку')),
          ]))
        : preflight ? startMenu() : ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Скажи это на башкирском', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
        const SizedBox(height: 9),
        const Text('Послушай фразу, затем нажми на микрофон и произнеси её. Произношение проверяет отдельная нейросеть.'),
        const SizedBox(height: 22),
        if (game == null) const CircularProgressIndicator() else ...[
          LinearProgressIndicator(value: ((selected + 1) / games.length).clamp(0.0, 1.0).toDouble()),
          const SizedBox(height: 8), Text('Задание ${completed ? games.length : selected + 1} из ${games.length}'),
          const SizedBox(height: 20),
          Center(child: MascotFigure(api: widget.api, action: result?.startsWith('Верно') == true ? 'success' : 'idle', size: 122)),
          const SizedBox(height: 20),
          Text(game['text'] as String, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (difficulty != 'hard')
            Text(game['meaning'] as String, textAlign: TextAlign.center)
          else const Text('Сложный уровень: перевод скрыт до ответа.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 18),
          OutlinedButton.icon(onPressed: () async {
            try { await widget.speech.speak(game['text'] as String, language: 'bak', speaker: 'bak_aigul'); }
            catch (e) { if (context.mounted) feedback(context, e); }
          }, icon: const Icon(Icons.volume_up), label: const Text('Послушать произношение')),
          const SizedBox(height: 14),
          Center(child: Tooltip(message: recording ? 'Остановить и проверить' : 'Начать запись',
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.06).animate(
                CurvedAnimation(parent: pulse, curve: Curves.easeInOut)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                width: 108, height: 108,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: recording ? const Color(0xFFD95F58) : sea,
                  boxShadow: [BoxShadow(color: (recording ? const Color(0xFFD95F58) : sea).withValues(alpha: 0.32),
                    spreadRadius: recording ? 11 : 3, blurRadius: recording ? 28 : 14)]),
                child: Material(shape: const CircleBorder(), color: Colors.transparent,
                  child: InkWell(customBorder: const CircleBorder(),
                    onTap: completed || busy || !asr ? null : microphone,
                    child: Center(child: busy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Icon(recording ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white, size: 48)))),
              ),
            ),
          )),
          const SizedBox(height: 10),
          Text(busy ? 'Проверяем произношение…' : recording ? 'Идёт запись · нажми ещё раз, чтобы проверить' : 'Нажми на круглый микрофон, чтобы начать',
            textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 11),
          if (!asr) const Text('Модель распознавания не установлена на сервере. Используй requirements-asr.txt. Озвучку можно слушать уже сейчас.',
            textAlign: TextAlign.center),
          if (result != null) Padding(padding: const EdgeInsets.all(10), child: Text(result!, textAlign: TextAlign.center)),
          const SizedBox(height: 11),
          if (!completed) OutlinedButton.icon(onPressed: busy || recording ? null : () { setState(() {
            if (selected + 1 < games.length) selected++;
            else { selected = games.length; completed = true; }
            result = null;
          }); persist(); }, icon: const Icon(Icons.skip_next), label: const Text('Пропустить без штрафа')),
          if (completed) ...[
            const SizedBox(height: 12),
            const Text('Афарин! Все фразы просмотрены 🎉', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () { setState(() { selected = 0; completed = false; result = null; }); persist(); },
              icon: const Icon(Icons.replay), label: const Text('Повторить игру')),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
                  title: const Text('Сбросить произношение?'),
                  content: const Text('Результаты игры на произношение будут удалены. Заработанные ранее монеты повторно не начисляются.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
                    FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сбросить')),
                  ],
                ));
                if (confirmed != true || !mounted) return;
                try {
                  await widget.extras.resetSaved('games', mode: 'speech');
                  if (mounted) setState(() { selected = 0; completed = false; result = null; });
                } catch (error) { if (mounted) feedback(context, error); }
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Сбросить результаты произношения'),
            ),
          ],
          const SizedBox(height: 15),
          const Text('Автоматическое распознавание речи не является оценкой акцента. Модель может ошибаться; разрешены повторные попытки.',
            style: TextStyle(fontSize: 12)),
        ],
      ]));
  }
}

class CreatorPage extends StatelessWidget {
  const CreatorPage({super.key});
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Создатели')),
    body: ListView(padding: const EdgeInsets.all(23), children: [
      const Text('Над проектом работали', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
      const SizedBox(height: 14),
      for (final name in const ['Казарбеков Ильяс','Шагимов Рахим', 'Галеев Альмир',
        'Киценко Даниила','Уразов Руслан'])
        ListTile(leading: const Icon(Icons.person_outline), title: Text(name)),
      const SizedBox(height: 22),
      const Text('При поддержке', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      Tooltip(message: 'Mystery Studios — независимый разработчик игр на Unreal Engine с башкирской локализацией. Помогает другим IT-проектам на башкирском языке.',
        child: Card(child: ListTile(leading: const Icon(Icons.sports_esports_outlined),
          title: const Text('Mystery Studios', style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text('Разработчик ПО и игр на башкирском языке')))),
      const SizedBox(height: 10),
      OutlinedButton.icon(icon: const Icon(Icons.open_in_new), label: const Text('Посмотреть работы'),
        onPressed: () async => launchUrl(Uri.parse('https://store.steampowered.com/curator/45029531'), mode: LaunchMode.externalApplication)),
    ]));
}

class MoreLessonsPage extends StatefulWidget {
  const MoreLessonsPage({super.key, required this.api, required this.speech, required this.extras});
  final ApiClient api; final SpeechPlayer speech; final ExtrasController extras;
  @override State<MoreLessonsPage> createState() => _MoreLessonsPageState();
}
class _MoreLessonsPageState extends State<MoreLessonsPage> {
  List<Map<String,dynamic>> items = [];
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try { final data = await widget.api.request('GET', '/extras/additional-lessons');
      if (mounted) setState(() => items = (data['items'] as List<dynamic>).whereType<Map<String,dynamic>>().toList());
    } catch (e) { if (mounted) feedback(context, e); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Дополнительные уроки')),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('Уроки от преподавателей и авторов приложения'),
      if (items.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Text('Дополнительных уроков пока нет. Их можно загрузить через админ-панель.')),
      for (final item in items) Card(child: ListTile(leading: const Icon(Icons.auto_stories_outlined),
        title: Text(item['title'] as String), subtitle: Text(item['description'] as String? ?? ''),
        trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CustomQuizPage(lesson: item, speech: widget.speech, api: widget.api, extras: widget.extras))))),
    ]));
}
class CustomQuizPage extends StatefulWidget {
  const CustomQuizPage({super.key, required this.lesson, required this.speech, required this.api, required this.extras});
  final Map<String, dynamic> lesson; final SpeechPlayer speech;
  final ApiClient api; final ExtrasController extras;
  @override State<CustomQuizPage> createState() => _CustomQuizPageState();
}
class _CustomQuizPageState extends State<CustomQuizPage> {
  int step = 0, correct = 0;
  String? picked;
  final answers = <String>[];
  bool awarded = false;
  Future<void> finishReward() async {
    if (awarded) return;
    awarded = true;
    try {
      final res = await widget.api.request('POST', '/extras/additional-lessons/${widget.lesson['id']}/complete', body: {'answers': answers});
      await widget.extras.refresh();
      if (mounted) showReward(context, coins: (res['earned_coins'] as num?)?.toInt() ?? 0,
        achievements: res['new_achievements'] as List<dynamic>? ?? [], api: widget.extras.api);
    } catch (e) { if (mounted) feedback(context, e); }
  }
  @override Widget build(BuildContext context) {
    final tasks = (widget.lesson['exercises'] as List<dynamic>?) ?? [];
    if (step >= tasks.length) {
      if (!awarded) WidgetsBinding.instance.addPostFrameCallback((_) => finishReward());
      return Scaffold(appBar: AppBar(title: Text(widget.lesson['title'] as String)),
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🌿', style: TextStyle(fontSize: 72)),
        Text('Правильных ответов: $correct / ${tasks.length}', style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 13), FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Вернуться'))])));
    }
    final task = tasks[step] as Map<String, dynamic>;
    return Scaffold(appBar: AppBar(title: Text('${widget.lesson['title']} · ${step + 1}/${tasks.length}')),
      body: ListView(padding: const EdgeInsets.all(23), children: [
        Text(task['prompt'] as String, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        IconButton(onPressed: () => widget.speech.speak(task['answer'] as String),
          icon: const Icon(Icons.volume_up)),
        for (final choice in task['options'] as List<dynamic>)
          Card(color: picked == choice ? Theme.of(context).colorScheme.primaryContainer : null,
            child: ListTile(title: Text(choice as String), onTap: () => setState(() => picked = choice))),
        const SizedBox(height: 20),
        FilledButton(onPressed: picked == null ? null : () {
          if (picked != task['answer']) {
            feedback(context, 'Пока не совсем верно. Попробуй другой вариант!');
            return;
          }
          answers.add(picked!);
          correct++;
          setState(() { step++; picked = null; });
        }, child: const Text('Проверить и дальше')),
      ]));
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.api});
  final ApiClient api;
  @override State<AdminPage> createState() => _AdminPageState();
}
class _AdminPageState extends State<AdminPage> {
  final login = TextEditingController();
  final password = TextEditingController();
  final lessonJson = TextEditingController();
  final resetUser = TextEditingController();
  final idle = TextEditingController();
  final success = TextEditingController();
  final tap = TextEditingController();
  final levitate = TextEditingController();
  final smile = TextEditingController();
  String previewAction = 'idle';
  final Map<String, TextEditingController> mascotNames = {
    for (final language in const ['ru', 'en', 'tt', 'kk', 'ba'])
      language: TextEditingController(text: 'Bot'),
  };
  Map<String, dynamic> brandingSounds = {};
  String? token;
  String? status;
  Map<String, dynamic> mascot = {};
  bool busy = false;

  @override void dispose() {
    for (final c in [login, password, lessonJson, resetUser, idle, success, tap, levitate, smile, ...mascotNames.values]) { c.dispose(); }
    super.dispose();
  }
  Future<Map<String,dynamic>> admin(String method, String path, {Map<String,dynamic>? body}) async {
    if (token == null) throw const ApiError('Сначала войди как администратор');
    final uri = Uri.parse('${widget.api.baseUrl}$path');
    final headers = {'Authorization':'Bearer $token', 'Content-Type':'application/json'};
    final response = await (method == 'GET' ? httpGet(uri, headers) : httpPost(uri, headers, body ?? {}));
    final result = jsonDecode(response.body) as Map<String,dynamic>;
    if (response.statusCode >= 400) throw ApiError('${result['detail']}');
    return result;
  }
  Future<dynamic> httpGet(Uri uri, Map<String,String> headers) => HttpHelper.get(uri, headers);
  Future<dynamic> httpPost(Uri uri, Map<String,String> headers, Map<String,dynamic> body) => HttpHelper.post(uri, headers, body);

  Future<void> signIn() async {
    setState(() => busy = true);
    try {
      final data = await widget.api.request('POST', '/extras/admin/login',
        body: {'username':login.text.trim(), 'password':password.text}, authorized: false);
      if (mounted) setState(() { token = data['token'] as String; password.clear(); status = 'Вход выполнен'; });
      await loadBranding();
    } catch (e) { if (mounted) feedback(context, e); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> upload() async {
    if (token == null) return;
    try {
      final pick = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['png','jpg','jpeg','webp','gif','glb'], withData: true);
      if (pick == null || pick.files.isEmpty) return;
      final file = pick.files.single;
      if (file.bytes == null) throw const ApiError('Не удалось прочитать файл');
      final result = await HttpHelper.upload('${widget.api.baseUrl}/extras/admin/mascot', token!,
        file.bytes!, file.name, {'idle':idle.text, 'success':success.text,
          'tap':tap.text, 'smile':smile.text, 'float_animation':levitate.text});
      if (mounted) setState(() { mascot = result; status = 'Маскот загружен'; });
    } catch (e) { if (mounted) feedback(context, e); }
  }
  Future<void> uploadAction(String action) async {
    if (token == null) return;
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif', 'glb'], withData: true);
      if (picked == null || picked.files.single.bytes == null) return;
      final file = picked.files.single;
      await HttpHelper.upload('${widget.api.baseUrl}/extras/admin/mascot/action/$action',
        token!, file.bytes!, file.name, {});
      final current = await admin('GET', '/extras/mascot');
      if (mounted) setState(() { mascot = current; previewAction = action;
        status = 'Анимация «$action» загружена'; });
    } catch (e) { if (mounted) feedback(context, e); }
  }

  Future<void> loadBranding() async {
    try {
      final data = await widget.api.request('GET', '/extras/branding');
      final names = data['names'] as Map<String, dynamic>? ?? {};
      for (final entry in mascotNames.entries) {
        entry.value.text = names[entry.key] as String? ?? 'Bot';
      }
      if (mounted) setState(() => brandingSounds = data['sounds'] as Map<String, dynamic>? ?? {});
    } catch (_) { /* Default names remain editable. */ }
  }

  Future<void> saveMascotNames() async {
    try {
      await admin('POST', '/extras/admin/branding/names', body: {
        'names': {for (final entry in mascotNames.entries) entry.key: entry.value.text.trim()},
      });
      if (mounted) setState(() => status = 'Имя маскота сохранено для всех языков');
    } catch (e) { if (mounted) feedback(context, e); }
  }

  Future<void> uploadSound(String event) async {
    if (token == null) return;
    try {
      final pick = await FilePicker.platform.pickFiles(type: FileType.custom,
        allowedExtensions: ['wav', 'mp3', 'ogg'], withData: true);
      if (pick == null || pick.files.isEmpty || pick.files.single.bytes == null) return;
      final file = pick.files.single;
      await HttpHelper.upload('${widget.api.baseUrl}/extras/admin/branding/sound/$event',
        token!, file.bytes!, file.name, {});
      await loadBranding();
      if (mounted) setState(() => status = 'Звук «$event» обновлён');
    } catch (e) { if (mounted) feedback(context, e); }
  }

  Future<void> addLesson() async {
    try {
      final data = jsonDecode(lessonJson.text);
      if (data is! Map<String,dynamic>) throw const FormatException('JSON должен быть объектом');
      final result = await admin('POST','/extras/admin/additional-lessons', body: data);
      if (mounted) setState(() => status = 'Урок №${result['id']} добавлен');
    } catch (e) { if (mounted) feedback(context, e); }
  }
  Future<void> reset() async {
    final approved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Удалить учебный прогресс?'),
      content: Text('Сбросить уроки, награды, покупки и монеты пользователя ${resetUser.text}?'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сбросить'))]));
    if (approved != true) return;
    try { await admin('POST','/extras/admin/reset', body: {'username':resetUser.text.trim()});
      if (mounted) setState(() => status = 'Прогресс сброшен');
    } catch (e) { if (mounted) feedback(context, e); }
  }
  Future<void> report() async {
    try { final data = await admin('GET','/extras/admin/report');
      final logLines = <String>[
        'Bashkir Language School — отчёт приложения',
        'Время: ${data['generated_at'] ?? DateTime.now().toIso8601String()}',
        'Аккаунты: ${data['users']}',
        'Пройденные уроки: ${data['lessons_done']}',
        'Практики: ${data['practices_done']}',
        'Успешная речь: ${data['speech_done']}',
        'Выдано монет: ${data['coins_issued']}',
        'Достижения: ${data['awards']}',
        '', 'Журнал последних начислений:',
        for (final event in data['recent_events'] as List<dynamic>? ?? [])
          '${event['at']} | пользователь #${event['user_id']} | ${event['kind']} | монеты: ${event['coins']}',
      ];
      await Clipboard.setData(ClipboardData(text: logLines.join('\n')));
      if (mounted) setState(() => status = 'Журнал и отчёт скопированы в буфер обмена');
    } catch (e) { if (mounted) feedback(context, e); }
  }
  @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Админ-меню')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      if (token == null) ...[
        const Text('Администратор. На локальном сервере доступны ранее указанные данные. Для удалённого сервера требуется защищённый отдельный аккаунт.'),
        const SizedBox(height: 15),
        TextField(controller: login, decoration: const InputDecoration(labelText: 'Логин')),
        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
        const SizedBox(height: 15),
        FilledButton(onPressed: busy ? null : signIn, child: const Text('Войти')),
      ] else ...[
        Card(child: ListTile(leading: const Icon(Icons.dashboard_customize_outlined),
          title: const Text('Центр управления платформой'),
          subtitle: const Text('Аккаунты, регионы, классы, модерация, заявки на ключи, журнал'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => AdminWorkspace(api: widget.api, token: token!))))),
        const SizedBox(height: 10),
        Card(child: ListTile(
          leading: const Icon(Icons.bolt_outlined),
          title: const Text('Cheat Mode', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Выдать или отнять монеты, достижения, товары и прохождение'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(
            builder: (_) => CheatModePage(api: widget.api,
              adminToken: token!))),
        )),
        const SizedBox(height: 12),
        ExpansionTile(
          leading: const Icon(Icons.smart_toy_outlined),
          title: const Text('Маскот · внешний вид и анимации'),
          subtitle: const Text('Загрузка отдельно для каждого действия и просмотр 3D'),
          children: [Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Базовый маскот: PNG, GIF, WEBP, JPG, GLB (до 8 МБ).',
                style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 9),
              FilledButton.tonalIcon(onPressed: upload, icon: const Icon(Icons.upload_file),
                label: const Text('Загрузить базовую модель')),
              const SizedBox(height: 14),
              for (final entry in <String, TextEditingController>{
                'idle': idle, 'smile': smile, 'success': success,
                'tap': tap, 'float': levitate,
              }.entries) Padding(padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Expanded(child: TextField(controller: entry.value,
                    decoration: InputDecoration(labelText: '${entry.key}: анимация внутри GLB',
                      border: const OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(onPressed: () => uploadAction(entry.key),
                    icon: const Icon(Icons.upload_file_outlined, size: 17),
                    label: const Text('Файл')),
                ])),
              const SizedBox(height: 12),
              Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
                const Text('Предпросмотр маскота', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                SizedBox(height: 270, child: Center(child: MascotFigure(
                  key: ValueKey('${mascot['url']}-$previewAction-${mascot['action_assets']}'),
                  api: widget.api, action: previewAction, size: 245))),
                Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center,
                  children: [for (final action in const {
                    'idle': 'Ожидание', 'smile': 'Улыбка', 'success': 'Успех',
                    'tap': 'Нажатие', 'float': 'Левитация',
                  }.entries) ChoiceChip(
                    selected: previewAction == action.key,
                    label: Text(action.value), onSelected: (_) => setState(() => previewAction = action.key))]),
              ]))),
            ]))],
        ),
        ExpansionTile(
          leading: const Icon(Icons.music_note_rounded),
          title: const Text('Имя и звуки учителя'),
          subtitle: const Text('Пять языков, проверка, переход, успех, ошибка, монеты'),
          children: [Padding(padding: const EdgeInsets.all(13), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('Как зовут маскота в каждом интерфейсе',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (final item in const {'ru':'Русский', 'en':'English',
                'tt':'Татарча', 'kk':'Қазақша', 'ba':'Башҡортса'}.entries)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: TextField(
                  controller: mascotNames[item.key], maxLength: 40,
                  decoration: InputDecoration(labelText: item.value,
                    border: const OutlineInputBorder(), isDense: true))),
              FilledButton.icon(onPressed: saveMascotNames,
                icon: const Icon(Icons.save_outlined), label: const Text('Сохранить имена')),
              const Divider(height: 30),
              const Text('Звуковые события: WAV, MP3, OGG до 3 МБ.',
                style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (final item in const {'check':'Проверка', 'next':'Далее',
                'success':'Верный ответ', 'error':'Ошибка', 'coin':'Монеты'}.entries)
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(item.value),
                      Text(brandingSounds.containsKey(item.key) ? 'Пользовательский звук' : 'Стандартный звук',
                        style: const TextStyle(fontSize: 11, color: Colors.blueGrey))])),
                  OutlinedButton.icon(onPressed: () => uploadSound(item.key),
                    icon: const Icon(Icons.upload_file_outlined, size: 17),
                    label: const Text('Заменить')),
                ])),
            ]))],
        ),
        ExpansionTile(
          title: const Text('Уроки, импорт и отчёты'),
          leading: const Icon(Icons.inventory_2_outlined),
          children: [Padding(padding: const EdgeInsets.all(12), child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Загрузка дополнительного урока (JSON)', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        TextField(controller: lessonJson, minLines: 3, maxLines: 11,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '{"title":"Урок","description":"...","exercises":[{"prompt":"...","answer":"...","options":["...","...","...","..."]}]}')),
        const SizedBox(height: 8),
        OutlinedButton.icon(onPressed: () async {
          final selected = await FilePicker.platform.pickFiles(type: FileType.custom,
            allowedExtensions: ['json'], withData: true);
          if (selected?.files.single.bytes != null) {
            lessonJson.text = utf8.decode(selected!.files.single.bytes!);
          }
        }, icon: const Icon(Icons.folder_open), label: const Text('Открыть файл урока .json')),
        const SizedBox(height: 9),
        FilledButton(onPressed: addLesson, child: const Text('Добавить урок')),
        const Divider(height: 30),
        TextField(controller: resetUser, decoration: const InputDecoration(labelText: 'Имя пользователя для сброса')),
        OutlinedButton.icon(onPressed: reset, icon: const Icon(Icons.restart_alt), label: const Text('Сбросить прогресс')),
        OutlinedButton.icon(onPressed: report, icon: const Icon(Icons.copy), label: const Text('Скопировать отчёт приложения')),
            ]))],
        ),
      ],
      if (status != null) Padding(padding: const EdgeInsets.all(10), child: Text(status!)),
    ]));
}

class HttpHelper {
  static Future<http.Response> get(Uri uri, Map<String,String> headers) =>
    http.get(uri, headers: headers).timeout(const Duration(seconds: 18));
  static Future<http.Response> post(Uri uri, Map<String,String> headers, Map<String,dynamic> body) =>
    http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 18));
  static Future<Map<String,dynamic>> upload(String url, String token, Uint8List bytes,
      String filename, Map<String,String> fields) async {
    final req = http.MultipartRequest('POST', Uri.parse(url));
    req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final response = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 40)));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) throw ApiError('${data['detail'] ?? 'Ошибка загрузки'}');
    return data;
  }
}

class RegionSettings extends StatefulWidget {
  const RegionSettings({super.key, required this.extras});
  final ExtrasController extras;
  @override State<RegionSettings> createState() => _RegionSettingsState();
}
class _RegionSettingsState extends State<RegionSettings> {
  List<String> regions = [];
  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final data = await widget.extras.api.request('GET', '/extras/regions');
      if (mounted) setState(() => regions = (data['regions'] as List<dynamic>).whereType<String>().toList());
    } catch (e) { if (mounted) feedback(context, e); }
  }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: widget.extras,
    builder: (context, _) => DropdownButtonFormField<String>(
      value: regions.contains(widget.extras.region) ? widget.extras.region : '',
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Регион РФ для рейтингов', border: OutlineInputBorder()),
      items: [const DropdownMenuItem(value:'', child: Text('Не выбран')),
        for (final region in regions) DropdownMenuItem(value:region, child: Text(region, overflow: TextOverflow.ellipsis))],
      onChanged: (value) async {
        if (value == null) return;
        try { await widget.extras.setRegion(value); }
        catch (e) { if (context.mounted) feedback(context, e); }
      },
    ));
}

class ThemeSettings extends StatelessWidget {
  const ThemeSettings({super.key, required this.extras, this.progress});
  final ExtrasController extras;
  final ProgressStore? progress;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: extras,
    builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      DropdownButtonFormField<String>(value: extras.theme, isExpanded: true,
        decoration: const InputDecoration(labelText:'Оформление приложения', border: OutlineInputBorder()),
        items: [for (final theme in const {'default':'🌿 Обычная', 'pink':'🌷 Розовая',
          'dark':'🌙 Тёмная', 'cats':'🐈 Котики',
          'kurai':'🌷 Курай и башкирская весна', 'northern':'🌌 Северное сияние'}.entries)
          DropdownMenuItem(value:theme.key, child: Text('${extras.hasTheme(theme.key) ? '' : '🔒 '}${theme.value}'))],
        onChanged: (value) async {
          if (value == null) return;
          if (!extras.hasTheme(value)) {
            final buy = await showDialog<bool>(context:context, builder:(ctx) => AlertDialog(
              title: const Text('Тема закрыта'), content: const Text('Её можно разблокировать в магазине за монеты.'),
              actions: [TextButton(onPressed:()=>Navigator.pop(ctx, false), child:const Text('Позже')),
                FilledButton(onPressed:()=>Navigator.pop(ctx,true), child:const Text('В магазин'))]));
            if (buy == true && context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage(extras: extras, progress: progress)));
            return;
          }
          try { await extras.chooseTheme(value); }
          catch (e) { if (context.mounted) feedback(context,e); }
        }),
      const SizedBox(height: 12),
      SwitchListTile.adaptive(contentPadding:EdgeInsets.zero, title:const Text('Игры с произношением'),
        subtitle:const Text('Необязательные задания. Можно пропускать без штрафа.'),
        value:extras.optionalSpeaking, onChanged:(v) async {
          try { await extras.setSpeaking(v); } catch (e) { if (context.mounted) feedback(context,e); }
        }),
    ]));
}
