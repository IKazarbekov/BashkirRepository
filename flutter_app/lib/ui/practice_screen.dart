import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/progress_store.dart';
import '../data/extras_controller.dart';
import 'reward_fx.dart';
import '../services/api_client.dart';
import '../services/speech_player.dart';

const _ink = Color(0xFF173E35);
const _green = Color(0xFF227F64);
const _line = Color(0xFFE3EAE3);
const _muted = Color(0xFF77867F);

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key, required this.api, required this.progress, required this.speech, required this.extras});
  final ApiClient api;
  final ProgressStore progress;
  final SpeechPlayer speech;
  final ExtrasController extras;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final correction = TextEditingController();
  Map<String, dynamic>? task;
  List<Map<String, dynamic>> pairs = [];
  String pair = 'ba-ru';
  String? message;
  bool loading = true;
  bool submitting = false;
  bool correcting = false;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    correction.dispose();
    super.dispose();
  }

  Future<void> reload() async {
    setState(() { loading = true; message = null; });
    try {
      final languages = await widget.api.request('GET', '/language-pairs');
      final list = (languages['pairs'] as List<dynamic>?) ?? [];
      final selected = languages['selected'] as String? ?? 'ba-ru';
      final today = await widget.api.request('GET', '/daily?language_pair=$selected');
      if (!mounted) return;
      setState(() {
        pairs = list.whereType<Map<String, dynamic>>().toList();
        pair = selected;
        task = today;
        correcting = false;
        correction.text = '';
      });
    } catch (error) {
      if (mounted) setState(() => message = '$error');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> changePair(String next) async {
    try {
      await widget.api.request('PUT', '/language-pairs', body: {'language_pair': next});
      await reload();
    } catch (error) {
      if (mounted) _notice('$error');
    }
  }

  Future<void> sendAnswer({required bool isCorrection}) async {
    if (task == null || submitting) return;
    final translation = isCorrection ? correction.text.trim() : task!['proposed_translation'] as String;
    if (translation.isEmpty) {
      _notice('Напиши правильный вариант перевода.');
      return;
    }
    setState(() => submitting = true);
    try {
      final result = await widget.api.request('POST', '/translations/submit', body: {
        'fragment_id': task!['fragment_id'],
        'language_pair': pair,
        'translation': translation,
        'action': isCorrection ? 'correct' : 'confirm',
      });
      await widget.progress.loadForAccount(widget.api);
      await widget.extras.refresh();
      if (!mounted) return;
      setState(() {
        task = {...task!, 'answered': true, 'your_translation': translation};
        correcting = false;
      });
      final xp = (result['awarded_xp'] as num?)?.toInt() ?? 0;
      _notice(result['saved'] == false ? 'Практика выполнена без сохранения' :
          xp > 0 ? 'Ответ сохранён · +$xp XP' : 'Ответ обновлён и сохранён');
      if (xp > 0) showReward(context, coins: (result['earned_coins'] as num?)?.toInt() ?? 0,
        achievements: result['new_achievements'] as List<dynamic>? ?? [], api: widget.extras.api);
    } catch (error) {
      if (mounted) _notice('$error');
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final data = task;
    return Center(child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(padding: const EdgeInsets.fromLTRB(22, 23, 22, 35), children: [
        const Text('Практика переводов', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Помогай собирать проверенные переводы башкирского языка', style: TextStyle()),
        const SizedBox(height: 22),
        if (pairs.isNotEmpty) DropdownButtonFormField<String>(
          value: pair,
          decoration: _field('Языковая пара'),
          items: pairs.map((item) => DropdownMenuItem(
            value: item['id'] as String, child: Text(item['label'] as String? ?? item['id'] as String),
          )).toList(),
          onChanged: loading ? null : (next) { if (next != null) changePair(next); },
        ),
        const SizedBox(height: 18),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(35), child: CircularProgressIndicator())),
        if (!loading && message != null) Column(children: [
          Text(message!, textAlign: TextAlign.center),
          TextButton(onPressed: reload, child: const Text('Повторить')),
        ]),
        if (!loading && data != null) ...[
          _panel(Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Row(children: [Icon(Icons.today_outlined, color: _green), SizedBox(width: 8),
              Text('Задание на сегодня', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18))]),
            const SizedBox(height: 15),
            Text(data['text_ba'] as String? ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(
              onPressed: () async {
                try { await widget.speech.speak(data['text_ba'] as String? ?? '', language: 'bak',
                    speaker: widget.progress.voiceLanguage == 'bak' ? widget.progress.voiceId : 'bak_aigul'); }
                catch (error) { if (mounted) _notice('$error'); }
              },
              icon: const Icon(Icons.volume_up_outlined), label: const Text('Прослушать по-башкирски'),
            )),
            const SizedBox(height: 16),
            const Text('Предложенный перевод', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 7),
            Text(data['proposed_translation'] as String? ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            const Text('Найди ошибку или подтверди перевод. Иногда предложенный вариант неправильный.',
              style: TextStyle()),
            const SizedBox(height: 10),
            Text(_sourceText(data['source']), style: const TextStyle(fontSize: 12)),
          ])),
          const SizedBox(height: 18),
          if (data['answered'] == true) _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Icon(Icons.check_circle_outline, color: _green), SizedBox(width: 8),
              Text('Твой ответ сохранён', style: TextStyle(fontWeight: FontWeight.w800))]),
            const SizedBox(height: 8),
            Text(data['your_translation'] as String? ?? '', style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 8),
            const Text('Вариант проверяется ответами других участников.', style: TextStyle()),
            TextButton(onPressed: () => setState(() { correcting = true; correction.text = data['your_translation'] as String? ?? ''; }),
                child: const Text('Изменить ответ')),
          ])),
          if (correcting) ...[
            TextField(controller: correction, maxLines: 3, maxLength: 1500,
              decoration: _field('Правильный перевод').copyWith(hintText: 'Напиши свой вариант')),
            const SizedBox(height: 8),
            FilledButton.icon(onPressed: submitting ? null : () => sendAnswer(isCorrection: true),
              icon: const Icon(Icons.check_rounded), label: Text(submitting ? 'Сохраняем...' : 'Отправить исправление')),
            TextButton(onPressed: () => setState(() => correcting = false), child: const Text('Отмена')),
          ] else if (data['answered'] != true) ...[
            SizedBox(height: 52, child: FilledButton.icon(
              onPressed: submitting ? null : () => sendAnswer(isCorrection: false),
              icon: const Icon(Icons.verified_outlined), label: const Text('Перевод правильный'))),
            const SizedBox(height: 9),
            SizedBox(height: 52, child: OutlinedButton.icon(
              onPressed: () => setState(() { correcting = true; correction.text = data['proposed_translation'] as String? ?? ''; }),
              icon: const Icon(Icons.edit_outlined), label: const Text('Исправить перевод'))),
          ],
        ],
        const SizedBox(height: 23),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Библиотека практики', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('Ежедневный перевод — только начало. Выбирай другие фрагменты, проверяй варианты, предлагай исправления, слушай тексты и помогай собирать базу переводов.'),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: () => _open(PracticeLibraryPage(
              api: widget.api, speech: widget.speech, progress: widget.progress,
              extras: widget.extras, languagePair: pair)),
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('Открыть все тексты')),
          ]))),
        const SizedBox(height: 13),
        _nav(Icons.emoji_events_outlined, 'Рейтинг участников', () => _open(LeaderboardScreen(api: widget.api))),
        _nav(Icons.school_outlined, 'Мой класс и отчёты', () => _open(ClassesScreen(api: widget.api))),
        _nav(Icons.library_books_outlined, 'Подтверждённые переводы', () => _open(ArchiveScreen(api: widget.api))),
      ]),
    ));
  }

  void _open(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  Widget _nav(IconData icon, String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ListTile(onTap: action, tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor)),
      leading: Icon(icon, color: _green), title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right_rounded)),
  );
}

String _sourceText(dynamic source) {
  if (source is! Map<String, dynamic>) return '';
  final document = source['document'] as String? ?? 'Учебный материал';
  final fragment = source['fragment'];
  return 'Источник: $document · фрагмент $fragment';
}

InputDecoration _field(String label) => InputDecoration(
  labelText: label, filled: true,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
);

Widget _panel(Widget child) => Builder(builder: (context) => Container(
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Theme.of(context).dividerColor)),
  child: child,
));

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String period = 'week';
  String mode = 'activity';
  String scope = 'users';
  bool busy = true;
  String? error;
  List<Map<String, dynamic>> entries = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() { busy = true; error = null; });
    try {
      final route = scope == 'users' ? '/leaderboard?period=$period&mode=$mode'
          : '/leaderboard/$scope?period=$period';
      final result = await widget.api.request('GET', route);
      if (mounted) setState(() => entries = (result['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>().toList());
    } catch (issue) {
      if (mounted) setState(() => error = '$issue');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Рейтинг')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640), child: ListView(
      padding: const EdgeInsets.all(22), children: [
        DropdownButtonFormField<String>(value: period, decoration: _field('Период'),
          items: const [DropdownMenuItem(value: 'day', child: Text('Сегодня')),
            DropdownMenuItem(value: 'week', child: Text('Неделя')),
            DropdownMenuItem(value: 'month', child: Text('Месяц')),
            DropdownMenuItem(value: 'year', child: Text('Год'))],
          onChanged: (x) { if (x != null) { setState(() => period = x); load(); } }),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: scope, decoration: _field('Рейтинг'),
          items: const [DropdownMenuItem(value: 'users', child: Text('Участники')),
            DropdownMenuItem(value: 'classes', child: Text('Классы')),
            DropdownMenuItem(value: 'schools', child: Text('Школы'))],
          onChanged: (x) { if (x != null) { setState(() => scope = x); load(); } }),
        const SizedBox(height: 12),
        if (scope == 'users') DropdownButtonFormField<String>(value: mode, decoration: _field('Показатель'),
          items: const [DropdownMenuItem(value: 'activity', child: Text('Активность')),
            DropdownMenuItem(value: 'vocabulary', child: Text('Словарный запас')),
            DropdownMenuItem(value: 'corrections', child: Text('Исправления')),
            DropdownMenuItem(value: 'accuracy', child: Text('Совпадения с большинством'))],
          onChanged: (x) { if (x != null) { setState(() => mode = x); load(); } }),
        const SizedBox(height: 20),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!),
        if (!busy && entries.isEmpty) const Text('Пока нет ответов. Выполни ежедневное задание!'),
        for (var i = 0; i < entries.length; i++) Builder(builder: (context) {
          final item = entries[i];
          final label = scope == 'users' ? item['username'] :
              scope == 'schools' ? item['school'] : '${item['school']} · ${item['name']}';
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: _panel(Row(children: [
          SizedBox(width: 35, child: Text('${i + 1}', style: const TextStyle(fontSize: 20, color: _green, fontWeight: FontWeight.w900))),
          Expanded(child: Text('$label', style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('${item['score']}', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        ])));
        }),
      ],
    ))));
}

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Map<String, dynamic>> classes = [];
  bool busy = true;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final result = await widget.api.request('GET', '/classes');
      if (mounted) setState(() { classes = (result['items'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList(); error = null; });
    } catch (issue) {
      if (mounted) setState(() => error = '$issue');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> join() async {
    final code = TextEditingController();
    final value = await showDialog<String>(context: context, builder: (c) => AlertDialog(
      title: const Text('Вступить в класс'),
      content: TextField(controller: code, decoration: _field('Код от преподавателя')),
      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(c, code.text.trim()), child: const Text('Вступить'))],
    ));
    code.dispose();
    if (value == null || value.isEmpty) return;
    try { await widget.api.request('POST', '/classes/join', body: {'code': value}); await load(); }
    catch (issue) { if (mounted) _show(issue); }
  }

  Future<void> create() async {
    final name = TextEditingController();
    final school = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Создать учебный класс'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: school, decoration: _field('Учебное заведение')),
        const SizedBox(height: 10),
        TextField(controller: name, decoration: _field('Класс (например, 7А)')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Создать'))],
    ));
    if (accepted == true) {
      try { await widget.api.request('POST', '/classes', body: {'name': name.text, 'school': school.text}); await load(); }
      catch (issue) { if (mounted) _show(issue); }
    }
    name.dispose(); school.dispose();
  }

  Future<void> report(int classId) async {
    try {
      final response = await widget.api.request('GET', '/classes/$classId/report');
      final items = (response['students'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList();
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (c) => AlertDialog(
        title: Text('Отчёт: ${response['class_name']}'),
        content: SizedBox(width: 440, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final student in items) ListTile(
            title: Text(student['username'] as String),
            subtitle: Text('Ответов: ${student['translation_answers']} · Уроков: ${student['completed_lessons']}'),
            trailing: Text('${student['xp']} XP'),
          ),
          if (items.isEmpty) const Text('Пока нет учеников'),
        ]))),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Закрыть'))],
      ));
    } catch (issue) { if (mounted) _show(issue); }
  }

  Future<void> addStudent(int classId) async {
    final username = TextEditingController();
    final accepted = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Зарегистрировать ученика'),
      content: TextField(controller: username, decoration: _field('Имя аккаунта ученика')),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Создать'))],
    ));
    if (accepted == true) {
      try {
        final result = await widget.api.request('POST', '/classes/$classId/students',
          body: {'login': username.text.trim()});
        if (!mounted) return;
        final text = 'Аккаунт: ${result['username']}\nПароль: ${result['temporary_password']}\nРезервный код: ${result['recovery_key']}';
        await showDialog<void>(context: context, barrierDismissible: false, builder: (c) => AlertDialog(
          title: const Text('Аккаунт ученика готов'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Передай эти данные ученику лично, не публикуй их в общем чате.'),
            const SizedBox(height: 15),
            SelectableText(text),
          ]),
          actions: [TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: text)),
            icon: const Icon(Icons.copy), label: const Text('Копировать')),
            FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Готово'))],
        ));
      } catch (issue) { if (mounted) _show(issue); }
    }
    username.dispose();
  }

  void _show(Object issue) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$issue')));

  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Мои классы')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Ученики вступают по коду преподавателя.', style: TextStyle()),
        const SizedBox(height: 15),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: join, icon: const Icon(Icons.group_add_outlined), label: const Text('Вступить'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: create, icon: const Icon(Icons.add), label: const Text('Создать'))),
        ]),
        const SizedBox(height: 19),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!),
        if (!busy && classes.isEmpty) const Text('Ты ещё не состоишь в учебном классе.'),
        for (final schoolClass in classes) Padding(padding: const EdgeInsets.only(bottom: 10), child: _panel(Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${schoolClass['school']} · ${schoolClass['name']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            Text(schoolClass['role'] == 'teacher' ? 'Преподаватель' : 'Ученик', style: const TextStyle()),
            if (schoolClass['role'] == 'teacher') ...[
              const SizedBox(height: 10),
              SelectableText('Код приглашения: ${schoolClass['code']}'),
              TextButton(onPressed: () => report(schoolClass['id'] as int), child: const Text('Отчёт по классу')),
              TextButton(onPressed: () => addStudent(schoolClass['id'] as int), child: const Text('Зарегистрировать ученика')),
            ],
          ],
        ))),
      ]))));
}

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<Map<String, dynamic>> items = [];
  String? error;
  bool busy = true;

  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final response = await widget.api.request('GET', '/translations');
      if (mounted) setState(() => items = (response['items'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>().toList());
    } catch (issue) { if (mounted) setState(() => error = '$issue'); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> copyCsv() async {
    try {
      final text = await widget.api.getText('/translations/export');
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV скопирован в буфер обмена')));
    } catch (issue) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$issue')));
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('База переводов')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 640),
      child: ListView(padding: const EdgeInsets.all(22), children: [
        const Text('Здесь собраны переводы, за которые проголосовало большинство участников.', style: TextStyle()),
        const SizedBox(height: 15),
        OutlinedButton.icon(onPressed: copyCsv, icon: const Icon(Icons.copy_outlined), label: const Text('Скопировать CSV для выгрузки')),
        const SizedBox(height: 15),
        if (busy) const Center(child: CircularProgressIndicator()),
        if (error != null) Text(error!),
        if (!busy && items.isEmpty) const Text('Подтверждённых переводов пока нет.'),
        for (final item in items) Padding(padding: const EdgeInsets.only(bottom: 10), child: _panel(Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['text_ba'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 7),
            Text(item['translation'] as String? ?? ''),
            const SizedBox(height: 7),
            Text('${item['lang_pair']} · подтверждений: ${item['confirmed']}', style: const TextStyle(fontSize: 12)),
            Text(_sourceText(item['source']), style: const TextStyle(fontSize: 12)),
          ],
        ))),
      ]))));
}

/// Browse and review the corpus independently from the one-fragment-per-day task.
class PracticeLibraryPage extends StatefulWidget {
  const PracticeLibraryPage({super.key, required this.api, required this.speech,
    required this.progress, required this.extras, required this.languagePair});
  final ApiClient api;
  final SpeechPlayer speech;
  final ProgressStore progress;
  final ExtrasController extras;
  final String languagePair;

  @override State<PracticeLibraryPage> createState() => _PracticeLibraryPageState();
}

class _PracticeLibraryPageState extends State<PracticeLibraryPage> {
  final filter = TextEditingController();
  List<Map<String, dynamic>> items = [];
  bool busy = true;
  String? error;

  @override void initState() { super.initState(); load(); }
  @override void dispose() { filter.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() { busy = true; error = null; });
    try {
      final pair = Uri.encodeQueryComponent(widget.languagePair);
      final response = await widget.api.request('GET', '/fragments?language_pair=$pair&limit=100');
      if (mounted) setState(() => items = (response['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>().toList());
    } catch (e) { if (mounted) setState(() => error = '$e'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override Widget build(BuildContext context) {
    final visible = items.where((v) => (v['text_ba'] as String? ?? '')
        .toLowerCase().contains(filter.text.toLowerCase())).toList();
    return Scaffold(appBar: AppBar(title: const Text('Библиотека переводов')),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('Выбирай текст, слушай его и помогай проверять перевод.',
            style: TextStyle(fontSize: 16)),
          const SizedBox(height: 11),
          TextField(controller: filter, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Поиск по башкирскому тексту',
              prefixIcon: Icon(Icons.search), border: OutlineInputBorder())),
          const SizedBox(height: 10),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (error != null) Text('Ошибка: $error'),
          if (!busy && visible.isEmpty) const Text('Фрагменты не найдены.'),
          for (final item in visible) Card(child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.translate)),
            title: Text(item['text_ba'] as String? ?? ''),
            subtitle: Text(_sourceText(item['source'])),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => FragmentReviewPage(
                fragmentId: (item['id'] as num).toInt(),
                languagePair: widget.languagePair, api: widget.api,
                progress: widget.progress, speech: widget.speech, extras: widget.extras))),
          )),
        ])),
      ));
  }
}

class FragmentReviewPage extends StatefulWidget {
  const FragmentReviewPage({super.key, required this.fragmentId, required this.languagePair,
    required this.api, required this.progress, required this.speech, required this.extras});
  final int fragmentId;
  final String languagePair;
  final ApiClient api;
  final ProgressStore progress;
  final SpeechPlayer speech;
  final ExtrasController extras;
  @override State<FragmentReviewPage> createState() => _FragmentReviewPageState();
}

class _FragmentReviewPageState extends State<FragmentReviewPage> {
  final correction = TextEditingController();
  Map<String, dynamic>? task;
  String? error;
  bool loading = true, sending = false;

  @override void initState() { super.initState(); load(); }
  @override void dispose() { correction.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final result = await widget.api.request('GET',
          '/fragments/${widget.fragmentId}/review?language_pair=${widget.languagePair}');
      if (mounted) setState(() { task = result; correction.text =
        result['your_translation'] as String? ?? result['proposed_translation'] as String? ?? ''; });
    } catch (e) { if (mounted) setState(() => error = '$e'); }
    finally { if (mounted) setState(() => loading = false); }
  }

  Future<void> submit(bool correct) async {
    if (sending || task == null) return;
    setState(() => sending = true);
    try {
      final result = await widget.api.request('POST', '/translations/submit', body: {
        'fragment_id': widget.fragmentId, 'language_pair': widget.languagePair,
        'translation': correct ? correction.text.trim() : task!['proposed_translation'],
        'action': correct ? 'correct' : 'confirm',
      });
      await widget.progress.loadForAccount(widget.api);
      await widget.extras.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:
        Text(result['notice'] as String? ?? 'Ответ отправлен')));
      await load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally { if (mounted) setState(() => sending = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Проверка перевода')),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600),
      child: ListView(padding: const EdgeInsets.all(20), children: [
        if (loading) const LinearProgressIndicator(),
        if (error != null) Text(error!),
        if (task != null) ...[
          Text(task!['text_ba'] as String? ?? '',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () async {
            try { await widget.speech.speak(task!['text_ba'] as String? ?? '',
              language: 'bak', speaker: widget.progress.voiceLanguage == 'bak'
                ? widget.progress.voiceId : 'bak_aigul'); }
            catch (e) { if (context.mounted) ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e'))); }
          }, icon: const Icon(Icons.volume_up), label: const Text('Прослушать')),
          const SizedBox(height: 10),
          Text(_sourceText(task!['source']), style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 18),
          const Text('Предложенный перевод', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('${task!['proposed_translation']}', style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 17),
          if (task!['answered'] == true) Card(child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Ты уже участвовал в проверке'),
            subtitle: Text('${task!['your_translation']}'))),
          TextField(controller: correction, maxLength: 1500, maxLines: 3,
            decoration: const InputDecoration(labelText: 'Твой вариант перевода',
              border: OutlineInputBorder())),
          const SizedBox(height: 8),
          FilledButton.icon(onPressed: sending ? null : () => submit(false),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Подтвердить предложенный')),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: sending ? null : () => submit(true),
            icon: const Icon(Icons.edit), label: const Text('Отправить исправление')),
        ],
      ])),
    ),
  );
}
