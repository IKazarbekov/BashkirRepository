import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/extras_controller.dart';
import '../data/ui_copy.dart';
import 'save_settings.dart';

const guideGreen = Color(0xFF227F64);
const introLanguages = <String, String>{
  'ru': 'Русский', 'en': 'English', 'tt': 'Татарча', 'kk': 'Қазақша',
};

class WelcomeGuide extends StatefulWidget {
  const WelcomeGuide({super.key, required this.extras});
  final ExtrasController extras;
  @override State<WelcomeGuide> createState() => _WelcomeGuideState();
}

class _WelcomeGuideState extends State<WelcomeGuide> {
  final PageController pages = PageController();
  int step = 0;
  static const int pageCount = 5;
  late String language;
  late bool adapt;
  bool saving = false;

  @override void initState() {
    super.initState();
    language = widget.extras.baseLanguage;
    adapt = widget.extras.adaptiveUi;
  }

  // The chosen source language previews instantly, before it is saved.
  String preview(String key) => uiCopy[key]?[language] ?? key;
  String intro(String key) {
    const copy = <String, Map<String, String>>{
      'hello': {'ru':'Рәхим ит! Добро пожаловать', 'en':'Рәхим ит! Welcome!',
        'tt':'Рәхим ит! Рәхим итегез!', 'kk':'Рәхим ит! Қош келдіңіз!'},
      'helloText': {'ru':'100 коротких уроков. Прогресс сохраняется на твоём аккаунте.',
        'en':'100 short lessons. Your progress stays with your account.',
        'tt':'100 кыска дәрес. Уңышларың аккаунтыңда саклана.',
        'kk':'100 қысқа сабақ. Үлгерімің аккаунтыңда сақталады.'},
      'games': {'ru':'Тренируйся по-своему', 'en':'Practice your way',
        'tt':'Үзеңә уңайлыча күнек', 'kk':'Өзіңе ыңғайлы жаттық'},
      'gamesText': {'ru':'Шесть игровых режимов, задания на слух и произношение. Микрофон можно пропустить.',
        'en':'Six game modes, listening and speaking exercises. The microphone is optional.',
        'tt':'Алты уен режимы, тыңлау һәм сөйләм күнегүләре. Микрофон мәҗбүри түгел.',
        'kk':'Алты ойын режимі, тыңдалым және айтылым. Микрофон міндетті емес.'},
      'people': {'ru':'Учись вместе с другими', 'en':'Learn together',
        'tt':'Бергә өйрән', 'kk':'Бірге үйрен'},
      'peopleText': {'ru':'Достижения, магазин, классы, рейтинги регионов и Telegram связаны с твоим аккаунтом.',
        'en':'Achievements, shop, classes, regional rankings and Telegram share one account.',
        'tt':'Казанышлар, кибет, сыйныфлар, төбәк рейтингы һәм Telegram бер аккаунтка бәйләнгән.',
        'kk':'Жетістіктер, дүкен, сыныптар, өңірлік рейтинг пен Telegram бір аккаунтқа байланған.'},
      'explain': {'ru':'Выбери понятный тебе язык. Если включить адаптацию, только уже изученные слова интерфейса постепенно станут башкирскими.',
        'en':'Choose your language. With adaptation enabled, only interface words you have learned gradually become Bashkir.',
        'tt':'Үз телеңне сайла. Җайлаштыруны кабызсаң, өйрәнгән интерфейс сүзләре генә башкортчага күчә.',
        'kk':'Өз тіліңді таңда. Бейімдеуді қоссаң, интерфейстегі тек үйренген сөздер біртіндеп башқұртша болады.'},
      'adaptText': {'ru':'Добровольно: можно выключить когда угодно.',
        'en':'Optional: turn off whenever you like.',
        'tt':'Ихтыяри: теләсә кайчан сүндереп була.',
        'kk':'Ерікті: кез келген уақытта өшіруге болады.'},
    };
    return copy[key]?[language] ?? copy[key]?['ru'] ?? key;
  }

  @override void dispose() { pages.dispose(); super.dispose(); }

  Future<void> finish() async {
    setState(() => saving = true);
    try {
      await widget.extras.saveLearning(language: language, adaptive: adapt, onboarding: true);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7FAF5),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 580), child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20), child: Column(children: [
        Row(children: [
          const Text('БАШҠОРТ ТЕЛЕ', style: TextStyle(color: guideGreen, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const Spacer(), Text('${step + 1}/$pageCount', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: (step + 1) / pageCount, minHeight: 7)),
        const SizedBox(height: 10),
        Expanded(child: PageView(controller: pages, onPageChanged: (v) => setState(() => step = v), children: [
          _slide('🌷', intro('hello'), intro('helloText')),
          _slide('🎮', intro('games'), intro('gamesText')),
          _slide('🏆', intro('people'), intro('peopleText')),
          ListView(children: [
            const SizedBox(height: 20), const Center(child: Text('🗣️', style: TextStyle(fontSize: 76))),
            const SizedBox(height: 18),
            Text(preview('Твой язык. Твой темп.'), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(intro('explain'), textAlign: TextAlign.center),
            const SizedBox(height: 13),
            Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(
              color: const Color(0xFFE5F5EB), borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Как это происходит', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                const SizedBox(height: 7),
                const Text('1. Ты изучаешь слово в уроке.\n2. После выполнения оно становится знакомым приложению.\n3. Подпись может постепенно перейти на башкирский.\n4. В настройках всё можно вернуть обратно.',
                  style: TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 7),
                const Row(children: [
                  Expanded(child: Chip(label: Text('Слова'))),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward)),
                  Expanded(child: Chip(label: Text('Һүҙҙәр'))),
                ]),
                const Text('Эта функция необязательна и не влияет на награды, XP или рейтинг.',
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              ])),
            const SizedBox(height: 25),
            DropdownButtonFormField<String>(value: language, isExpanded: true,
              decoration: InputDecoration(labelText: preview('Мой основной язык'), border: OutlineInputBorder()),
              items: [for (final item in introLanguages.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
              onChanged: (v) { if (v != null) setState(() => language = v); }),
            const SizedBox(height: 15),
            SwitchListTile.adaptive(value: adapt, activeColor: guideGreen,
              title: Text(preview('Адаптация приложения'), style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(intro('adaptText')),
              onChanged: (v) => setState(() => adapt = v)),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: () => showTelegramLink(context, widget.extras),
              icon: const Icon(Icons.send_outlined), label: Text(preview('Связать с Telegram (по желанию)'))),
          ]),
          ListView(children: [
            const SizedBox(height: 12),
            const Text('☁️ Твои сохранения', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('Выбери, какие результаты сохранять. Это можно изменить в профиле в любой момент.'),
            const SizedBox(height: 10),
            SaveSettings(extras: widget.extras),
          ]),
        ])),
        const SizedBox(height: 12),
        Row(children: [
          if (step > 0) TextButton.icon(onPressed: () => pages.previousPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic),
            icon: const Icon(Icons.arrow_back), label: Text(preview('Назад'))),
          const Spacer(),
          FilledButton.icon(onPressed: saving ? null : () {
            if (step == pageCount - 1) { finish(); } else {
              pages.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
            }
          }, icon: Icon(step == pageCount - 1 ? Icons.check_circle : Icons.arrow_forward),
            label: Text(preview(step == pageCount - 1 ? 'Начать обучение' : 'Далее'))),
        ]),
      ]),
    )))),
  );

  Widget _slide(String icon, String title, String text) => Center(child: TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.94, end: 1), duration: const Duration(milliseconds: 520), curve: Curves.easeOutBack,
    builder: (context, value, child) => Transform.scale(scale: value, child: child),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: const TextStyle(fontSize: 98)), const SizedBox(height: 24),
      Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
      const SizedBox(height: 14),
      Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5)),
    ]),
  ));
}

Future<void> showTelegramLink(BuildContext context, ExtrasController extras) async {
  try {
    final data = await extras.telegramLink();
    if (!context.mounted) return;
    final url = data['url'] as String?;
    final code = data['code'] as String;
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Привязать Telegram'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Открой бота по ссылке и нажми Start. Привязка будет действовать для текущего аккаунта. Ссылка активна 10 минут.'),
        const SizedBox(height: 12),
        SelectableText(url ?? 'Укажи BASHKIR_BOT_USERNAME в backend_api/.env, затем используй /start link_$code'),
      ]),
      actions: [
        TextButton.icon(onPressed: () => Clipboard.setData(ClipboardData(text: url ?? code)), icon: const Icon(Icons.copy), label: const Text('Копировать')),
        if (url != null) FilledButton(onPressed: () async { Navigator.pop(ctx); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }, child: const Text('В Telegram')),
      ],
    ));
  } catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
  }
}

class LearningSettings extends StatelessWidget {
  const LearningSettings({super.key, required this.extras});
  final ExtrasController extras;
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: extras, builder: (context, _) => Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(extras.tr('Адаптация приложения'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text('Пройдено ${extras.learnedLessons}/100 уроков · известно ${extras.studiedWords.length} слов. ${extras.courseFinished ? 'Полный башкирский интерфейс открыт!' : 'Новые слова появляются после уроков.'}'),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(value: extras.baseLanguage, isExpanded: true,
        decoration: const InputDecoration(labelText: 'Исходный язык интерфейса', border: OutlineInputBorder()),
        items: [for (final item in introLanguages.entries) DropdownMenuItem(value: item.key, child: Text(item.value))],
        onChanged: (v) async { if (v != null) { try { await extras.saveLearning(language: v); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'))); } } }),
      const SizedBox(height: 9),
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: Text(extras.tr('Постепенный башкирский')),
        subtitle: const Text('Заменяем только знакомые слова. После 100 уроков доступен весь интерфейс.'),
        value: extras.adaptiveUi, onChanged: (v) => extras.saveLearning(adaptive: v)),
      SwitchListTile.adaptive(contentPadding: EdgeInsets.zero, title: const Text('Мой ник в публичных рейтингах'),
        subtitle: const Text('Даже при отключении общие региональные числа продолжают учитываться.'),
        value: extras.publicRank, onChanged: (v) => extras.saveLearning(public: v)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        OutlinedButton.icon(onPressed: () => showTelegramLink(context, extras), icon: const Icon(Icons.send),
          label: Text(extras.telegramLinked ? 'Telegram привязан' : 'Привязать Telegram')),
        OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => WelcomeGuide(extras: extras))),
          icon: const Icon(Icons.play_circle_outline), label: const Text('Посмотреть приветствие')),
      ]),
    ],
  ));
}
