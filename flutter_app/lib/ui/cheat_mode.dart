import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_client.dart';

/// Administrative test tools. All changes are validated and logged by FastAPI.
class CheatModePage extends StatefulWidget {
  const CheatModePage({
    super.key,
    required this.api,
    required this.adminToken,
    this.initialUsername = '',
  });

  final ApiClient api;
  final String adminToken;
  final String initialUsername;

  @override
  State<CheatModePage> createState() => _CheatModePageState();
}

class _CheatModePageState extends State<CheatModePage> {
  final account = TextEditingController();
  final coins = TextEditingController(text: '100');
  final lessonCount = TextEditingController(text: '100');
  final lessonNumber = TextEditingController(text: '1');
  final statsNumber = TextEditingController(text: '10');
  final gameNumber = TextEditingController(text: '5');
  final resetLessonNumber = TextEditingController();
  Map<String, dynamic>? snapshot;
  String? selectedAchievement;
  String? selectedItem;
  String mode = 'choice';
  String resetCategory = 'games';
  String resetGameMode = '';
  String notice = '';
  bool busy = false;

  static const modes = <String, String>{
    'choice': 'Выбор перевода',
    'pairs': 'Пары слов',
    'arrange': 'Собери фразу',
    'listen': 'Аудирование',
    'write': 'Написание',
    'speech': 'Произношение',
  };
  static const categories = <String, String>{
    'lessons': 'Уроки и XP',
    'games': 'Игры и произношение',
    'practices': 'Переводческая практика',
    'achievements': 'Достижения',
    'rankings': 'Публичный рейтинг',
    'favorites': 'Избранные слова',
    'purchases': 'Магазин и темы',
    'all': 'Все категории',
  };

  @override
  void initState() {
    super.initState();
    account.text = widget.initialUsername;
    if (account.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => load());
    }
  }

  @override
  void dispose() {
    for (final controller in [account, coins, lessonCount, lessonNumber,
      statsNumber, gameNumber, resetLessonNumber]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> request(String verb, String endpoint,
      [Map<String, dynamic>? body]) async {
    final uri = Uri.parse('${widget.api.baseUrl}$endpoint');
    final headers = {
      'Authorization': 'Bearer ${widget.adminToken}',
      'Content-Type': 'application/json',
    };
    final http.Response reply;
    if (verb == 'GET') {
      reply = await http.get(uri, headers: headers);
    } else {
      reply = await http.post(uri, headers: headers,
          body: jsonEncode(body ?? <String, dynamic>{}));
    }
    final parsed = jsonDecode(utf8.decode(reply.bodyBytes));
    if (parsed is! Map<String, dynamic>) {
      throw const FormatException('Сервер вернул неожиданный ответ');
    }
    if (reply.statusCode >= 400) {
      throw ApiError('${parsed['detail'] ?? 'Ошибка ${reply.statusCode}'}');
    }
    return parsed;
  }

  Future<void> load() async {
    final name = account.text.trim();
    if (name.isEmpty) {
      setState(() => notice = 'Сначала введи имя аккаунта');
      return;
    }
    setState(() { busy = true; notice = ''; });
    try {
      final result = await request('GET',
          '/extras/admin/cheat?username=${Uri.encodeQueryComponent(name)}');
      if (!mounted) return;
      setState(() {
        snapshot = result;
        final catalog = result['catalog'] as Map<String, dynamic>? ?? {};
        final achievements = (catalog['achievements'] as List?) ?? [];
        final shop = (catalog['shop'] as List?) ?? [];
        selectedAchievement ??= achievements.isEmpty
            ? null : (achievements.first as Map)['code'] as String;
        selectedItem ??= shop.isEmpty ? null : (shop.first as Map)['id'] as String;
      });
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  int readNumber(TextEditingController controller) {
    final value = int.tryParse(controller.text.trim());
    if (value == null || value < 0) {
      throw const FormatException('Нужно указать неотрицательное целое число');
    }
    return value;
  }

  Future<void> apply(String operation, {
    int? amount,
    String? code,
    String? item,
    int? lessonIndex,
    String? gameMode,
    String? category,
    bool confirm = false,
  }) async {
    if (snapshot == null) {
      setState(() => notice = 'Сначала загрузите аккаунт');
      return;
    }
    if (confirm) {
      final allowed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: const Text('Подтвердить изменение'),
        content: Text('Действие «$operation» для @${account.text.trim()} изменит данные на сервере. Продолжить?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Подтвердить')),
        ],
      ));
      if (allowed != true || !mounted) return;
    }
    setState(() { busy = true; notice = ''; });
    try {
      final result = await request('POST', '/extras/admin/cheat', {
        'username': account.text.trim(),
        'operation': operation,
        if (amount != null) 'amount': amount,
        if (code != null) 'code': code,
        if (item != null) 'item': item,
        if (lessonIndex != null) 'lesson_index': lessonIndex,
        if (gameMode != null) 'mode': gameMode,
        if (category != null) 'category': category,
      });
      if (!mounted) return;
      setState(() {
        snapshot = result['state'] as Map<String, dynamic>;
        notice = 'Изменение сохранено. Запись добавлена в журнал администратора.';
      });
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> useAmount(String operation, TextEditingController controller,
      {bool confirm = false}) async {
    try {
      await apply(operation, amount: readNumber(controller), confirm: confirm);
    } catch (error) {
      if (mounted) setState(() => notice = '$error');
    }
  }

  Future<void> setGameProgress() async {
    final value = int.tryParse(gameNumber.text.trim());
    if (value == null || value < 0) {
      if (mounted) {
        setState(() => notice = 'Укажи неотрицательное целое число');
      }
      return;
    }
    await apply('game_set', gameMode: mode, amount: value);
  }

  Future<void> completeGameMode() async {
    final currentCatalog = snapshot?['catalog'];
    if (currentCatalog is! Map<String, dynamic>) {
      if (mounted) setState(() => notice = 'Сначала загрузи аккаунт');
      return;
    }
    final limits = currentCatalog['game_limits'];
    final maximum = limits is Map ? limits[mode] : null;
    if (maximum is! int) {
      if (mounted) setState(() => notice = 'Для режима нет числа заданий');
      return;
    }
    await apply('game_set', gameMode: mode,
        amount: maximum, confirm: true);
  }

  Widget section(String heading, IconData icon, List<Widget> contents) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: ExpansionTile(
      leading: Icon(icon),
      title: Text(heading, style: const TextStyle(fontWeight: FontWeight.bold)),
      children: [Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
            children: contents))],
    ),
  );

  Widget numberField(TextEditingController controller, String label) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(border: const OutlineInputBorder(),
        isDense: true, labelText: label),
  );

  Widget actions(List<Widget> buttons) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Wrap(spacing: 8, runSpacing: 8, children: buttons),
  );

  Widget actionButton(String label, VoidCallback action, {
    IconData icon = Icons.check_circle_outline,
    bool outlined = false,
  }) => outlined
      ? OutlinedButton.icon(onPressed: busy ? null : action,
          icon: Icon(icon, size: 18), label: Text(label))
      : FilledButton.tonalIcon(onPressed: busy ? null : action,
          icon: Icon(icon, size: 18), label: Text(label));

  @override
  Widget build(BuildContext context) {
    final state = snapshot;
    final catalog = state?['catalog'] as Map<String, dynamic>? ?? {};
    final achievements = ((catalog['achievements'] as List?) ?? [])
        .whereType<Map<String, dynamic>>().toList();
    final items = ((catalog['shop'] as List?) ?? [])
        .whereType<Map<String, dynamic>>().toList();
    final unlocked = (state?['achievements'] as List?) ?? [];
    final purchases = (state?['purchases'] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Cheat Mode'), actions: [
        IconButton(onPressed: busy ? null : load,
            tooltip: 'Обновить данные', icon: const Icon(Icons.refresh)),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Тестовое управление аккаунтом',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        const Text('Доступно только через административную сессию. Изменения видны в приложении и Telegram-боте.'),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: TextField(controller: account,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => load(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true,
              labelText: 'Логин аккаунта'))),
          const SizedBox(width: 8),
          FilledButton(onPressed: busy ? null : load,
              child: const Text('Открыть')),
        ]),
        if (busy) const Padding(padding: EdgeInsets.only(top: 12),
          child: LinearProgressIndicator()),
        if (notice.isNotEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: SelectableText(notice)),
        if (state != null) ...[
          const SizedBox(height: 15),
          Text('@${state['username']}',
            style: Theme.of(context).textTheme.titleLarge),
          Wrap(spacing: 6, runSpacing: 4, children: [
            Chip(label: Text('${state['coins']} монет')),
            Chip(label: Text('${state['lessons_count']}/100 уроков')),
            Chip(label: Text('${unlocked.length} достижений')),
            Chip(label: Text('${purchases.length} покупок')),
            Chip(label: Text('${state['practices']} практик')),
            Chip(label: Text('${state['speaking']} произношений')),
          ]),
          const SizedBox(height: 12),
          section('Монеты', Icons.toll_outlined, [
            numberField(coins, 'Сумма монет (до 1 млрд)'),
            actions([
              actionButton('Добавить', () => useAmount('wallet_add', coins),
                  icon: Icons.add_circle_outline),
              actionButton('Отнять', () => useAmount('wallet_subtract', coins,
                  confirm: true), icon: Icons.remove_circle_outline),
              actionButton('Установить баланс', () => useAmount('wallet_set', coins,
                  confirm: true), outlined: true),
            ]),
          ]),
          section('Уроки, XP и серия дней', Icons.school_outlined, [
            numberField(lessonCount, 'Сколько первых уроков отметить (0–100)'),
            actions([
              actionButton('Выставить прохождение', () => useAmount(
                  'lessons_set', lessonCount, confirm: true)),
              actionButton('Завершить все 100', () => apply('lessons_set',
                  amount: 100, confirm: true), icon: Icons.workspace_premium),
            ]),
            const SizedBox(height: 12),
            numberField(lessonNumber, 'Отдельный урок (1–100)'),
            actions([
              actionButton('Отметить пройденным', () async {
                try { await apply('lesson_grant',
                    lessonIndex: readNumber(lessonNumber) - 1); }
                catch (error) { if (mounted) setState(() => notice = '$error'); }
              }),
              actionButton('Отменить прохождение', () async {
                try { await apply('lesson_revoke',
                    lessonIndex: readNumber(lessonNumber) - 1, confirm: true); }
                catch (error) { if (mounted) setState(() => notice = '$error'); }
              }, outlined: true),
            ]),
            const SizedBox(height: 12),
            numberField(statsNumber, 'Число для XP, серии или практик'),
            actions([
              actionButton('Установить XP', () => useAmount('xp_set', statsNumber)),
              actionButton('Установить серию', () => useAmount('streak_set', statsNumber)),
              actionButton('Установить практики', () => useAmount('practices_set', statsNumber)),
              actionButton('Установить произношения', () => useAmount('speaking_set', statsNumber)),
            ]),
          ]),
          section('Игровые результаты', Icons.sports_esports_outlined, [
            DropdownButtonFormField<String>(value: mode,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(),
                  labelText: 'Игровой режим', isDense: true),
              items: [for (final entry in modes.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value))],
              onChanged: busy ? null : (v) { if (v != null) setState(() => mode = v); },
            ),
            const SizedBox(height: 12),
            numberField(gameNumber, 'Число выполненных этапов'),
            actions([
              actionButton('Выставить прогресс игры',
                  () => setGameProgress(), icon: Icons.flag_outlined),
              actionButton('Завершить весь режим',
                  () => completeGameMode(), outlined: true),
            ]),
            const SizedBox(height: 8),
            const Text('Результат изменяется только в выбранном режиме; предыдущие честные ответы не подменяются.'),
          ]),
          section('Достижения и награды', Icons.emoji_events_outlined, [
            if (achievements.isNotEmpty) DropdownButtonFormField<String>(
              value: achievements.any((row) => row['code'] == selectedAchievement)
                  ? selectedAchievement : achievements.first['code'] as String,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(),
                  labelText: 'Достижение', isDense: true),
              items: [for (final achievement in achievements)
                DropdownMenuItem(value: '${achievement['code']}',
                  child: Text('${achievement['name']} ${unlocked.contains(achievement['code']) ? '✓' : '🔒'}',
                      overflow: TextOverflow.ellipsis))],
              onChanged: busy ? null : (value) => setState(() => selectedAchievement = value)),
            actions([
              actionButton('Выдать', () => apply('achievement_grant',
                  code: selectedAchievement), icon: Icons.add_task),
              actionButton('Забрать', () => apply('achievement_revoke',
                  code: selectedAchievement, confirm: true), outlined: true),
              actionButton('Выдать все', () => apply('achievements_all_grant',
                  confirm: true), icon: Icons.auto_awesome),
              actionButton('Забрать все', () => apply('achievements_all_revoke',
                  confirm: true), outlined: true),
            ]),
            const SizedBox(height: 8),
            const Text('Награда Night Project открывается через выполнение 100 уроков. Фактическую отправку ключей отмечают отдельно.'),
          ]),
          section('Предметы магазина', Icons.shopping_bag_outlined, [
            if (items.isNotEmpty) DropdownButtonFormField<String>(
              value: items.any((row) => row['id'] == selectedItem)
                  ? selectedItem : items.first['id'] as String,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(),
                  labelText: 'Тема или голос', isDense: true),
              items: [for (final item in items)
                DropdownMenuItem(value: '${item['id']}',
                  child: Text('${item['name']} ${purchases.contains(item['id']) ? '✓' : ''}',
                      overflow: TextOverflow.ellipsis))],
              onChanged: busy ? null : (value) => setState(() => selectedItem = value)),
            actions([
              actionButton('Подарить бесплатно', () => apply('item_grant',
                  item: selectedItem), icon: Icons.card_giftcard),
              actionButton('Отозвать покупку', () => apply('item_revoke',
                  item: selectedItem, confirm: true), outlined: true),
              actionButton('Подарить всё', () => apply('items_all_grant',
                  confirm: true), icon: Icons.card_giftcard),
              actionButton('Забрать всё', () => apply('items_all_revoke',
                  confirm: true), outlined: true),
            ]),
          ]),
          section('Выборочный сброс', Icons.delete_outline, [
            DropdownButtonFormField<String>(value: resetCategory,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder(),
                  labelText: 'Что стереть', isDense: true),
              items: [for (final entry in categories.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value))],
              onChanged: busy ? null : (v) {
                if (v != null) setState(() => resetCategory = v);
              }),
            if (resetCategory == 'games') ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: resetGameMode,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(),
                    labelText: 'Режим', isDense: true),
                items: [const DropdownMenuItem(value: '', child: Text('Все режимы')),
                  for (final entry in modes.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value))],
                onChanged: busy ? null : (v) {
                  if (v != null) setState(() => resetGameMode = v);
                }),
            ],
            if (resetCategory == 'lessons') ...[
              const SizedBox(height: 10),
              numberField(resetLessonNumber, 'Номер одного урока, пусто — все уроки'),
            ],
            actions([
              actionButton('Стереть выбранный прогресс', () async {
                try {
                  final raw = resetLessonNumber.text.trim();
                  await apply('reset', category: resetCategory,
                      gameMode: resetCategory == 'games' && resetGameMode.isNotEmpty
                          ? resetGameMode : null,
                      lessonIndex: resetCategory == 'lessons' && raw.isNotEmpty
                          ? readNumber(resetLessonNumber) - 1 : null,
                      confirm: true);
                } catch (error) {
                  if (mounted) setState(() => notice = '$error');
                }
              }, icon: Icons.delete_forever_outlined),
            ]),
            const Text('Стирание не возвращает потраченные монеты и не отменяет реальные заявки на игровые ключи.'),
          ]),
          const SizedBox(height: 18),
          const Text('Cheat Mode предназначен для администратора и тестирования. Каждое изменение записывается в журнал сервера.',
              style: TextStyle(fontSize: 12)),
        ],
      ]),
    );
  }
}
