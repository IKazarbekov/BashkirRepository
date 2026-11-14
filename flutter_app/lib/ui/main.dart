import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/lessons.dart';
import '../data/progress_store.dart';
import '../data/session.dart';
import '../data/extras_controller.dart';
import '../services/api_client.dart';
import '../services/speech_player.dart';
import 'auth_screen.dart';
import 'voice_settings.dart';
import 'practice_screen.dart';
import 'community_pages.dart';
import 'mini_games.dart';
import 'tutor_dock.dart';
import 'mascot.dart';
import 'reward_fx.dart';
import 'learning_guide.dart';
import 'themes.dart';
import 'word_composer.dart';
import 'lesson_dialogue.dart';
import 'bashkir_alphabet.dart';
import '../services/ui_sounds.dart';
import 'save_settings.dart';
import 'feedback_page.dart';

class AppColors {
  static Color dark = const Color(0xFF173E35);
  static Color green = const Color(0xFF227F64);
  static Color greenDeep = const Color(0xFF156B54);
  static Color greenLight = const Color(0xFFE4F3E9);
  static Color background = const Color(0xFFF8F9F4);
  static Color card = Colors.white;
  static Color line = const Color(0xFFE3EAE3);
  static Color muted = const Color(0xFF77867F);
  static Color amber = const Color(0xFFFFBB53);

  static void select(String name) {
    switch (name) {
      case 'pink':
        dark = const Color(0xFF6E3458); green = const Color(0xFFCC6498);
        greenDeep = const Color(0xFFAA477F); greenLight = const Color(0xFFFFE2F0);
        background = const Color(0xFFFFF5FA); card = Colors.white;
        line = const Color(0xFFF2D9E5); muted = const Color(0xFF97758A);
        break;
      case 'dark':
        dark = const Color(0xFFF2F6F6); green = const Color(0xFF53B69A);
        greenDeep = const Color(0xFF25856E); greenLight = const Color(0xFF273E3A);
        background = const Color(0xFF151D1C); card = const Color(0xFF222D2A);
        line = const Color(0xFF364743); muted = const Color(0xFFABC0B8);
        break;
      case 'cats':
        dark = const Color(0xFF5C4544); green = const Color(0xFFA46A5D);
        greenDeep = const Color(0xFF82564B); greenLight = const Color(0xFFF9E9DE);
        background = const Color(0xFFFFF8EF); card = Colors.white;
        line = const Color(0xFFF0DFD3); muted = const Color(0xFF958078);
        break;
      case 'kurai':
        dark = const Color(0xFF244C3A); green = const Color(0xFF367E56);
        greenDeep = const Color(0xFF235C46); greenLight = const Color(0xFFF0ECDD);
        background = const Color(0xFFFBF7E9); card = const Color(0xFFFFFEF9);
        line = const Color(0xFFE8DFC3); muted = const Color(0xFF88745B);
        break;
      case 'northern':
        dark = const Color(0xFFE8F9FF); green = const Color(0xFF45CAB7);
        greenDeep = const Color(0xFF238C95); greenLight = const Color(0xFF273F5C);
        background = const Color(0xFF101C31); card = const Color(0xFF1C2941);
        line = const Color(0xFF344763); muted = const Color(0xFFA0C3D0);
        break;
      default:
        dark = const Color(0xFF173E35); green = const Color(0xFF227F64);
        greenDeep = const Color(0xFF156B54); greenLight = const Color(0xFFE4F3E9);
        background = const Color(0xFFF8F9F4); card = Colors.white;
        line = const Color(0xFFE3EAE3); muted = const Color(0xFF77867F);
        break;
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ProgressStore progress = ProgressStore();
  final ApiClient api = ApiClient();
  late final AppSession session;
  late final SpeechPlayer speech;
  late final ExtrasController extras;

  @override
  void initState() {
    super.initState();
    session = AppSession(api, progress);
    speech = SpeechPlayer(api, progress);
    extras = ExtrasController(api);
    session.addListener(() {
      if (session.status == SessionStatus.signedIn) {
        extras.load(username: session.username).catchError((_) {});
      } else if (session.status == SessionStatus.signedOut) {
        extras.clear();
      }
    });
    session.restore();
  }

  @override
  void dispose() {
    speech.dispose();
    session.dispose();
    progress.dispose();
    extras.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: extras, builder: (context, _) {
      AppColors.select(extras.theme);
      return MaterialApp(
      title: 'Башкирский язык',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: (extras.theme == 'dark' || extras.theme == 'northern') ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green,
          brightness: (extras.theme == 'dark' || extras.theme == 'northern') ? Brightness.dark : Brightness.light,
          primary: AppColors.green,
          surface: AppColors.background,
        ),
        appBarTheme:  AppBarTheme(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.dark,
          surfaceTintColor: Colors.transparent,
        ),
        textTheme:  TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.dark),
          headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: AppColors.dark),
          titleLarge: TextStyle(fontWeight: FontWeight.w800, color: AppColors.dark),
          titleMedium: TextStyle(fontWeight: FontWeight.w700, color: AppColors.dark),
          bodyLarge: TextStyle(color: AppColors.dark),
          bodyMedium: TextStyle(color: AppColors.dark),
        ),
      ),
      home: AnimatedBuilder(
        animation: Listenable.merge([session, extras]),
        builder: (context, _) {
          switch (session.status) {
            case SessionStatus.loading:
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            case SessionStatus.unavailable:
              return ReconnectScreen(session: session);
            case SessionStatus.signedOut:
              return AuthScreen(session: session);
            case SessionStatus.signedIn:
              return HomeShell(progress: progress, session: session, speech: speech, extras: extras);
          }
        },
      ),
    );
    });
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.progress, required this.session, required this.speech, required this.extras});
  final ProgressStore progress;
  final AppSession session;
  final SpeechPlayer speech;
  final ExtrasController extras;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tabIndex = 0;
  bool _guideOpened = false;
  bool _recoveryHandled = false;

  void _openGuideWhenReady() {
    if (!mounted || _guideOpened || !_recoveryHandled || widget.extras.achievements.isEmpty || widget.extras.onboardingDone) return;
    _guideOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.push(context, MaterialPageRoute<void>(builder: (_) => WelcomeGuide(extras: widget.extras)));
    });
  }

  @override void dispose() {
    widget.extras.removeListener(_openGuideWhenReady);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    UiSounds.instance.configure(widget.session.api);
    widget.extras.addListener(_openGuideWhenReady);
    // Show the once-only backup code immediately after a new registration.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final code = widget.session.newRecoveryCode;
      if (code != null && mounted) {
        widget.session.newRecoveryCode = null;
        await showRecoveryCode(context, code);
      }
      _recoveryHandled = true;
      _openGuideWhenReady();
    });
  }

  void openLesson(int index) {
    if (index > widget.progress.nextLesson) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала пройди предыдущий урок')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(index: index, progress: widget.progress, speech: widget.speech, extras: widget.extras),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.progress,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Stack(children: [IndexedStack(
              index: tabIndex,
              children: [
                Dashboard(progress: widget.progress, onLesson: openLesson, extras: widget.extras, speech: widget.speech),
                PracticeScreen(api: widget.session.api, progress: widget.progress, speech: widget.speech, extras: widget.extras),
                DictionaryScreen(progress: widget.progress, speech: widget.speech, extras: widget.extras),
                ProfileScreen(progress: widget.progress, session: widget.session, speech: widget.speech, extras: widget.extras),
                GameModesPage(api: widget.session.api, speech: widget.speech, extras: widget.extras, progress: widget.progress),
              ],
            ),
            Positioned(right: 12, bottom: 13, child: TutorDock(api: widget.session.api)),
            ]),
          ),
          bottomNavigationBar: NavigationBar(
            height: MediaQuery.sizeOf(context).width < 395 ? 65 : 72,
            backgroundColor: AppColors.card,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.greenLight,
            selectedIndex: tabIndex,
            onDestinationSelected: (value) => setState(() => tabIndex = value),
            labelBehavior: MediaQuery.sizeOf(context).width < 395
              ? NavigationDestinationLabelBehavior.onlyShowSelected
              : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.route_outlined),
                selectedIcon: Icon(Icons.route),
                label: widget.extras.tr('Уроки'),
              ),
              NavigationDestination(
                icon: Icon(Icons.translate),
                selectedIcon: Icon(Icons.translate),
                label: widget.extras.tr('Практика'),
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: widget.extras.tr('Слова'),
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: widget.extras.tr('Профиль'),
              ),
              NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: widget.extras.tr('Игры')),
            ],
          ),
        );
      },
    );
  }
}

class PageWidth extends StatelessWidget {
  const PageWidth({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: child,
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key, required this.progress, required this.onLesson, required this.extras, required this.speech});
  final ProgressStore progress;
  final ValueChanged<int> onLesson;
  final ExtrasController extras;
  final SpeechPlayer speech;

  @override
  Widget build(BuildContext context) {
    final next = progress.nextLesson;
    final finished = next >= lessons.length;
    return PageWidth(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
        children: [
          if (extras.theme == 'kurai') const BashkirLandscape(),
          if (extras.theme == 'northern') const NorthernGlow(),
          if (extras.theme == 'pink') const PinkGarden(),
          if (extras.theme == 'cats') const CatCornerBanner(),
          if (extras.theme == 'dark') const DarkNightBanner(),
          Row(
            children: [
              Container(
                height: 46,
                width: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(extras.theme == 'cats' ? '🐈' : 'Ә', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.greenDeep)),
              ),
              const SizedBox(width: 12),
               Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('БАШҠОРТ ТЕЛЕ', style: TextStyle(fontSize: 11, letterSpacing: 2.0, fontWeight: FontWeight.w800, color: AppColors.green)),
                    SizedBox(height: 3),
                    Text(extras.theme == 'cats' ? 'Учимся с котиками!' : '${extras.tr('Привет')}! Время учиться!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  ],
                ),
              ),
              _SmallStat(icon: Icons.local_fire_department_rounded, value: '${progress.activeStreak}', color: const Color(0xFFE68442)),
              const SizedBox(width: 8),
              _SmallStat(icon: Icons.bolt_rounded, value: '${progress.xp}', color: const Color(0xFFD39C24)),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🏅', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 9),
                Expanded(child: Text(extras.tr('Площадь побед'), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppColors.dark))),
                Text('🪙 ${extras.coins}', style: TextStyle(color: AppColors.greenDeep, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(height: 5),
              Text('Награды, рекорды и покупки за твои знания', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 2.7,
                children: [
                  _HubButton(icon: Icons.workspace_premium_outlined, title: extras.tr('Достижения'), onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AwardsPage(extras: extras, progress: progress, section: 'achievements')))),
                  _HubButton(icon: Icons.card_giftcard_rounded, title: extras.tr('Награды'), onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => AwardsPage(extras: extras, progress: progress, section: 'rewards')))),
                  _HubButton(icon: Icons.storefront_outlined, title: extras.tr('Магазин'), onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => ShopPage(extras: extras, progress: progress)))),
                  _HubButton(icon: Icons.leaderboard_rounded, title: extras.tr('Рейтинги'), onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => RegionLeaderboardPage(api: speech.api, extras: extras)))),
                ],
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient:  LinearGradient(
                colors: [AppColors.green, AppColors.greenDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.16), blurRadius: 24, offset: const Offset(0, 12))],
            ),
            child: Stack(
              children: [
                Positioned(right: -38, top: -55, child: _DecorCircle(size: 185)),
                Positioned(right: 25, bottom: -65, child: _DecorCircle(size: 130)),
                Padding(
                  padding: const EdgeInsets.all(23),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Һаумыһығыҙ!', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 7),
                      Text(finished ? 'Все уроки пройдены. Повтори материал!' : 'Каждое новое слово — маленькая победа.', style: const TextStyle(color: Color(0xFFE3F5E9), fontSize: 14)),
                      const SizedBox(height: 27),
                      Row(
                        children: [
                          Expanded(
                            child: _SolidButton(
                              label: extras.tr(finished ? 'Повторить урок' : next == 0 ? 'Начать учиться' : 'Продолжить'),
                              icon: Icons.arrow_forward_rounded,
                              inverted: true,
                              onPressed: () => onLesson(finished ? 0 : next),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 55,
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(17)),
                            child: const Icon(Icons.auto_stories_rounded, size: 29, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 27),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text(extras.tr('Путь обучения'), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.dark)),
              Text('${progress.completed.length}/${lessons.length} уроков', style:  TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress.completed.length / lessons.length,
              minHeight: 8,
              backgroundColor: AppColors.line,
              valueColor:  AlwaysStoppedAnimation(AppColors.green),
            ),
          ),
          const SizedBox(height: 17),
          for (var i = 0; i < lessons.length; i++)
            _LessonTile(
              lesson: lessons[i],
              language: extras.baseLanguage,
              index: i,
              completed: progress.completed.contains(i),
              locked: i > next,
              onTap: () => onLesson(i),
            ),
          Card(child: ListTile(
            leading: const Icon(Icons.add_box_outlined, color: Color(0xFF227F64)),
            title: Text(extras.tr('Дополнительные уроки')),
            subtitle: const Text('Темы, добавленные преподавателями'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
              MoreLessonsPage(api: speech.api, speech: speech, extras: extras))),
          )),
          const SizedBox(height: 10),
           Center(child: Text('Бәләкәй аҙымдар — ҙур еңеүҙәр.', style: TextStyle(color: AppColors.muted, fontSize: 13))),
        ],
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  const _HubButton({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => Material(
    color: AppColors.greenLight, borderRadius: BorderRadius.circular(13),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(13), child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 19, color: AppColors.greenDeep), const SizedBox(width: 6),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.dark))),
      ]))),
  );
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.11), width: 22),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({required this.icon, required this.value, required this.color});
  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 4),
        Text(value, style:  TextStyle(fontWeight: FontWeight.w900, color: AppColors.dark)),
      ]),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.index, required this.completed, required this.locked, required this.onTap, required this.language});
  final Lesson lesson;
  final String language;
  final int index;
  final bool completed;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = completed ? AppColors.green : locked ? const Color(0xFFB7C3BC) : AppColors.greenDeep;
    const lessonWords = <String, String>{'ru':'УРОК', 'en':'LESSON', 'tt':'ДӘРЕС', 'kk':'САБАҚ', 'ba':'ДӘРЕС'};
    final lessonWord = lessonWords[language] ?? 'УРОК';
    return Padding(
      padding: EdgeInsets.only(left: index.isOdd ? 16 : 0, right: index.isEven ? 16 : 0, bottom: 12),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: locked ? AppColors.line : AppColors.greenLight, width: 1.3),
            ),
            child: Row(
              children: [
                Container(
                  height: 59,
                  width: 59,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: locked ? const Color(0xFFF0F2EE) : AppColors.greenLight, borderRadius: BorderRadius.circular(19)),
                  child: locked ?  Icon(Icons.lock_outline_rounded, color: AppColors.muted, size: 25) : Text(lesson.icon, style: const TextStyle(fontSize: 27)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('$lessonWord ${index + 1}', style: TextStyle(fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: accent)),
                  const SizedBox(height: 4),
                  Text(lesson.titleFor(language), style:  TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.dark)),
                  const SizedBox(height: 3),
                  Text(lesson.subtitleFor(language), style:  TextStyle(fontSize: 12, color: AppColors.muted)),
                ])),
                Icon(completed ? Icons.check_circle_rounded : locked ? Icons.lock_rounded : Icons.arrow_forward_ios_rounded,
                  size: completed ? 23 : 17, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  const _SolidButton({required this.label, required this.onPressed, this.icon, this.inverted = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 51,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: inverted ? Colors.white : AppColors.green,
          foregroundColor: inverted ? AppColors.greenDeep : Colors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.muted,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
            if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 19)],
          ],
        ),
      ),
    );
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.index, required this.progress, required this.speech, required this.extras});
  final int index;
  final ProgressStore progress;
  final SpeechPlayer speech;
  final ExtrasController extras;

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final GlobalKey<TutorDockState> tutor = GlobalKey<TutorDockState>();
  int questionIndex = 0;
  String? picked;
  final List<int> assembled = [];
  bool? correct;
  bool finished = false;
  bool gainedXp = false;
  bool finishing = false;
  bool introducing = true;
  int introductionStage = 0;
  String mascotName = 'Bot';

  @override void initState() {
    super.initState();
    _loadMascotBranding();
  }

  Future<void> _loadMascotBranding() async {
    UiSounds.instance.configure(widget.speech.api);
    try {
      final config = await widget.speech.api.request('GET', '/extras/branding');
      final names = config['names'] as Map<String, dynamic>? ?? {};
      if (mounted) setState(() => mascotName =
        names[widget.extras.baseLanguage] as String? ?? 'Bot');
    } catch (_) { /* Offline robot stays named Bot. */ }
  }

  Exercise get question => lessons[widget.index].exercises[questionIndex];
  String get answer => question.type == ExerciseType.choice
      ? picked ?? ''
      : assembled.map((index) => question.words[index]).join(' ').replaceAll(' ?', '?');

  void selectChoice(String value) {
    if (correct != null) return;
    HapticFeedback.selectionClick();
    setState(() => picked = value);
  }

  void addWord(int index) {
    if (correct != null || assembled.contains(index)) return;
    HapticFeedback.selectionClick();
    setState(() => assembled.add(index));
  }

  void removeWord(int index) {
    if (correct != null) return;
    HapticFeedback.selectionClick();
    setState(() => assembled.remove(index));
  }

  Future<void> next() async {
    if (correct == null) {
      if (answer.isEmpty) return;
      UiSounds.instance.play('check');
      final right = answer == question.correctAnswer;
      setState(() => correct = right);
      UiSounds.instance.play(right ? 'success' : 'error');
      return;
    }
    if (correct == false) {
      setState(() {
        correct = null;
        picked = null;
        assembled.clear();
      });
      return;
    }
    UiSounds.instance.play('next');
    if (widget.index > 0 && (questionIndex + 1) % 3 == 0 && !widget.extras.adaptiveUi) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 7),
        content: const Text('🌿 Хочешь, чтобы знакомые слова появлялись на башкирском в меню?'),
        action: SnackBarAction(label: 'Включить', onPressed: () { widget.extras.saveLearning(adaptive: true); })));
    }
    if (questionIndex + 1 < lessons[widget.index].exercises.length) {
      setState(() {
        questionIndex++;
        picked = null;
        assembled.clear();
        correct = null;
      });
    } else {
      if (finishing) return;
      setState(() => finishing = true);
      try {
        gainedXp = await widget.progress.completeLesson(widget.index);
        await widget.extras.refresh();
        if (mounted && widget.extras.adaptiveUi && (widget.index + 1) % 3 == 0) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 5),
            content: Text('🌿 Интерфейс адаптируется: уже знакомо ${widget.extras.studiedWords.length} башкирских слов.')));
        }
        if (mounted) {
          setState(() => finished = true);
          if (gainedXp) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showReward(context, coins: widget.progress.lastEarnedCoins, achievements: widget.progress.lastAchievements, api: widget.extras.api);
            });
          }
        }
      } catch (e) {
        if (mounted) showApiMessage(context, e);
      } finally {
        if (mounted) setState(() => finishing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = lessons[widget.index];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Закрыть урок',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Text(lesson.titleFor(widget.extras.baseLanguage), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: PageWidth(
          child: Stack(children: [
            finished ? _buildFinish() : introducing ? _buildIntroduction() : _buildQuestion(),
            if (!introducing && !finished) Positioned(right: 10, bottom: 94,
              child: TutorDock(key: tutor, api: widget.speech.api)),
          ]),
        ),
      ),
    );
  }

  Widget _buildIntroduction() {
    final lesson = lessons[widget.index];
    final languages = widget.extras.baseLanguage;
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(20, 22, 20, 18), children: [
        Text('${lesson.icon} ${lesson.titleFor(widget.extras.baseLanguage)}', style: TextStyle(
          color: AppColors.dark, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(lesson.subtitleFor(widget.extras.baseLanguage), style: TextStyle(color: AppColors.muted, fontSize: 14)),
        const SizedBox(height: 25),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MascotFigure(api: widget.speech.api, action: 'smile', size: 93),
          const SizedBox(width: 12),
          Expanded(child: MascotDialogue(name: mascotName,
            text: LessonDialogue.message(lesson, introductionStage, languages, adapt: widget.extras.adaptText))),
        ]),
        const SizedBox(height: 19),
        Text('${introductionStage + 1}/3', textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
        const SizedBox(height: 13),
        Text('✦', textAlign: TextAlign.center, style: TextStyle(fontSize: 38, color: AppColors.green)),
      ])),
      Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: _SolidButton(label: introductionStage == 2
          ? widget.extras.tr('Начать урок') : widget.extras.tr('Далее'),
          icon: Icons.arrow_forward_rounded, onPressed: () {
            UiSounds.instance.play('next');
            setState(() {
              if (introductionStage == 2) introducing = false;
              else introductionStage++;
            });
          })),
    ]);
  }

  void _showReading() {
    final original = question.spokenText;
    showModalBottomSheet<void>(context: context, showDragHandle: true,
      isScrollControlled: true, builder: (sheet) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.extras.tr('Не могу слушать'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 15),
            Text(widget.extras.tr('На башкирском'), style: const TextStyle(fontWeight: FontWeight.w700)),
            SelectableText(original, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 14),
            Text(widget.extras.tr('Приблизительно русскими буквами'), style: const TextStyle(fontWeight: FontWeight.w700)),
            SelectableText(LessonDialogue.russianReading(original),
              style: TextStyle(fontSize: 20, color: AppColors.green)),
            const SizedBox(height: 9),
            Text(widget.extras.tr('Это подсказка, а не точная транскрипция: некоторые башкирские звуки не имеют русских аналогов.'),
              style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ]))));
  }

  Widget _buildQuestion() {
    final exercises = lessons[widget.index].exercises;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(23, 10, 23, 0),
          child: Row(children: [
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: questionIndex / exercises.length,
                minHeight: 9,
                backgroundColor: AppColors.line,
                valueColor:  AlwaysStoppedAnimation(AppColors.green),
              ),
            )),
            const SizedBox(width: 12),
            Text('${questionIndex + 1}/${exercises.length}', style:  TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800)),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(23, 34, 23, 16),
          children: [
            Row(children: [
              MascotFigure(api: widget.speech.api,
                action: correct == true ? 'success' : 'idle', size: 88),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.help_outline),
                label: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(mascotName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                  Text(widget.extras.tr('Не понял тему или слово'), textAlign: TextAlign.center)]),
                onPressed: () => tutor.currentState?.openForLesson(widget.index + 1, lessons[widget.index].title))),
            ]),
            const SizedBox(height: 22),
            Text(widget.extras.tr(question.type == ExerciseType.choice ? 'Выбери правильный ответ' : 'Составь фразу'), style:  TextStyle(color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 13)),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Text(question.promptFor(widget.extras.baseLanguage), style:  TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.dark, height: 1.25))),
              Column(mainAxisSize: MainAxisSize.min, children: [
                IconButton(tooltip: 'Прослушать',
                  icon: Icon(Icons.volume_up_rounded, color: AppColors.green),
                  onPressed: () => playSpeech(context, widget.speech, question.spokenText)),
                TextButton.icon(onPressed: _showReading,
                  icon: const Icon(Icons.subtitles_outlined, size: 15),
                  label: Text(widget.extras.tr('Не могу слушать'), textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 10))),
              ]),
            ]),
            const SizedBox(height: 29),
            if (question.type == ExerciseType.choice) _buildOptions() else _buildWords(),
            if (correct != null) ...[
              const SizedBox(height: 23),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: correct! ? AppColors.greenLight : const Color(0xFFFFF1E7),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(correct! ? Icons.check_circle_rounded : Icons.info_rounded, color: correct! ? AppColors.green : const Color(0xFFD48236)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.extras.tr(correct! ? 'Верно! Афарин!' : 'Пока не получилось'), style:  TextStyle(fontWeight: FontWeight.w900, color: AppColors.dark, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(correct! ? (question.note.isEmpty ? widget.extras.tr('Отличная работа') : question.noteFor(widget.extras.baseLanguage)) : 'Попробуй ещё раз.', style:  TextStyle(color: AppColors.dark)),
                  ])),
                ]),
              ),
            ],
          ],
        )),
        Container(
          padding: const EdgeInsets.fromLTRB(23, 14, 23, 20),
          decoration:  BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.line))),
          child: _SolidButton(
            label: widget.extras.tr(correct == null ? 'Проверить' : correct! ? 'Продолжить' : 'Попробуй ещё раз'),
            icon: Icons.arrow_forward_rounded,
            onPressed: finishing || (correct == null && answer.isEmpty) ? null : next,
          ),
        ),
      ],
    );
  }

  Widget _buildOptions() {
    return Column(children: [
      for (final option in question.answers)
        Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: Material(
            color: picked == option ? AppColors.greenLight : AppColors.card,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              borderRadius: BorderRadius.circular(17),
              onTap: () => selectChoice(option),
              child: Container(
                constraints: const BoxConstraints(minHeight: 65),
                padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: picked == option ? AppColors.green : AppColors.line, width: picked == option ? 2 : 1.2),
                ),
                child: Row(children: [
                  Expanded(child: Text(option, style:  TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark))),
                  Icon(picked == option ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: picked == option ? AppColors.green : AppColors.muted),
                ]),
              ),
            ),
          ),
        ),
    ]);
  }

  Widget _buildWords() => WordComposer(
    key: ValueKey('lesson_${widget.index}_question_$questionIndex'),
    words: question.words,
    selected: assembled,
    enabled: correct == null && !finishing,
    onAdd: addWord,
    onRemove: removeWord,
  );

  Widget _buildFinish() {
    return Padding(
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: Text('🌿', style: TextStyle(fontSize: 90))),
          const SizedBox(height: 24),
           Text('Афарин!', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.dark)),
          const SizedBox(height: 7),
           Text(widget.extras.tr('Урок завершён'), textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: AppColors.muted)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(23),
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.line)),
            child: Column(children: [
              const Icon(Icons.bolt_rounded, size: 38, color: Color(0xFFDEA12A)),
              const SizedBox(height: 3),
              Text(!widget.progress.lastSaved ? 'Без сохранения' : gainedXp ? '+20 XP' : 'Урок повторён', style:  TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.dark)),
              const SizedBox(height: 5),
              Text(!widget.progress.lastSaved ? 'Результат доступен до перезагрузки приложения.' : gainedXp ? 'Новые знания в копилке!' : 'Дополнительные XP даются за первый проход.', textAlign: TextAlign.center, style:  TextStyle(color: AppColors.muted)),
            ]),
          ),
          const SizedBox(height: 30),
          if (widget.extras.optionalSpeaking) ...[
            OutlinedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => GameModesPage(api: widget.speech.api, speech: widget.speech,
                extras: widget.extras, progress: widget.progress))),
              icon: const Icon(Icons.sports_esports_outlined), label: const Text('Попробовать игры (необязательно)')),
            const SizedBox(height: 10),
          ],
          TextButton.icon(
            onPressed: () async {
              final accepted = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('Сбросить этот урок?'),
                content: const Text('Удалится сохранённое прохождение и связанная награда за этот урок.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Сбросить')),
                ],
              ));
              if (accepted != true || !mounted) return;
              try {
                await widget.extras.resetSaved('lessons', lessonIndex: widget.index);
                await widget.progress.loadForAccount(widget.extras.api);
                if (mounted) Navigator.of(context).pop();
              } catch (e) { if (mounted) showApiMessage(context, e); }
            },
            icon: const Icon(Icons.restart_alt), label: const Text('Сбросить прохождение урока'),
          ),
          const SizedBox(height: 8),
          if (widget.index + 1 < lessons.length) ...[
            _SolidButton(label: widget.extras.tr('Следующий урок'),
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                UiSounds.instance.play('next');
                Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) =>
                  LessonScreen(index: widget.index + 1, progress: widget.progress,
                    speech: widget.speech, extras: widget.extras)));
              }),
            const SizedBox(height: 9),
          ],
          OutlinedButton.icon(onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.home_outlined), label: const Text('К урокам')),
        ],
      ),
    );
  }
}

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key, required this.progress, required this.speech, required this.extras});
  final ProgressStore progress;
  final SpeechPlayer speech;
  final ExtrasController extras;

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  String query = '';
  String filter = 'Все';
  bool alphabetMode = false;
  String categoryLabel(String key) {
    for (final lesson in lessons) {
      if (lesson.title == key) return lesson.titleFor(widget.extras.baseLanguage);
    }
    return widget.extras.tr(key);
  }

  @override
  Widget build(BuildContext context) {
    final moreCategories = dictionary.map((word) => word.category).toSet().toList()..sort();
    final categories = ['Все', 'Избранное', ...moreCategories];
    final visible = dictionary.where((word) {
      final matchText = word.bashkir.toLowerCase().contains(query.toLowerCase()) || word.russian.toLowerCase().contains(query.toLowerCase());
      final matchFilter = filter == 'Все' || (filter == 'Избранное' && widget.progress.favorites.contains(word.bashkir)) || word.category == filter;
      return matchText && matchFilter;
    }).toList();

    return PageWidth(child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 23, 22, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
         Text(widget.extras.tr('Словарь'), style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.dark)),
        const SizedBox(height: 6),
         Text(widget.extras.tr('Повторяй слова и сохраняй любимые'), style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: ChoiceChip(label: Text(widget.extras.tr('Слова')),
            selected: !alphabetMode, onSelected: (_) => setState(() => alphabetMode = false))),
          const SizedBox(width: 12),
          Expanded(child: ChoiceChip(label: Text(widget.extras.tr('Алфавит')),
            selected: alphabetMode, onSelected: (_) => setState(() => alphabetMode = true))),
        ]),
        const SizedBox(height: 15),
        if (alphabetMode) Expanded(child: BashkirAlphabetPanel(speech: widget.speech, extras: widget.extras))
        else ...[
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: widget.extras.tr('Найти слово или перевод'),
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.card,
            enabledBorder: OutlineInputBorder(borderSide:  BorderSide(color: AppColors.line), borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(borderSide:  BorderSide(color: AppColors.green, width: 1.5), borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(height: 45, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final category = categories[index];
            final selected = category == filter;
            return ChoiceChip(
              label: Text(categoryLabel(category)),
              selected: selected,
              onSelected: (_) => setState(() => filter = category),
              backgroundColor: AppColors.card,
              selectedColor: AppColors.greenLight,
              side: BorderSide(color: selected ? AppColors.green : AppColors.line),
              labelStyle: TextStyle(color: selected ? AppColors.greenDeep : AppColors.dark, fontWeight: FontWeight.w700),
              showCheckmark: false,
            );
          },
        )),
        const SizedBox(height: 12),
        Expanded(child: visible.isEmpty
          ?  Center(child: Text(widget.extras.tr('Пока ничего не найдено'), style: TextStyle(color: AppColors.muted)))
          : ListView.separated(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              itemCount: visible.length,
              separatorBuilder: (context, index) => const SizedBox(height: 9),
              itemBuilder: (context, index) {
                final word = visible[index];
                final favorite = widget.progress.favorites.contains(word.bashkir);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.line)),
                  child: Row(children: [
                    Container(width: 42, height: 42, alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(14)),
                      child: Text(word.bashkir.substring(0, 1), style:  TextStyle(fontSize: 20, color: AppColors.greenDeep, fontWeight: FontWeight.w900))),
                    const SizedBox(width: 13),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(word.bashkir, style:  TextStyle(fontSize: 16, color: AppColors.dark, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(word.russian, style:  TextStyle(fontSize: 13, color: AppColors.muted)),
                    ])),
                    IconButton(
                      tooltip: widget.extras.tr('Прослушать слово'),
                      onPressed: () => playSpeech(context, widget.speech, word.bashkir),
                      icon:  Icon(Icons.volume_up_outlined, color: AppColors.green),
                    ),
                    IconButton(
                      tooltip: widget.extras.tr(favorite ? 'Убрать из избранного' : 'В избранное'),
                      onPressed: () async {
                        try {
                          await widget.progress.toggleFavorite(word.bashkir);
                        } catch (e) {
                          if (context.mounted) showApiMessage(context, e);
                        }
                      },
                      icon: Icon(favorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: favorite ? AppColors.green : AppColors.muted),
                    ),
                  ]),
                );
              },
            )),
        ],
      ]),
    ));
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.progress, required this.session, required this.speech, required this.extras});
  final ProgressStore progress;
  final AppSession session;
  final SpeechPlayer speech;
  final ExtrasController extras;

  Future<void> editName(BuildContext context) async {
    final controller = TextEditingController(text: progress.displayName);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Как тебя зовут?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 25,
          decoration: const InputDecoration(labelText: 'Имя'),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) Navigator.pop(dialogContext, value.trim());
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Отмена')),
          FilledButton(onPressed: () {
            if (controller.text.trim().isNotEmpty) Navigator.pop(dialogContext, controller.text.trim());
          }, child: const Text('Сохранить')),
        ],
      ),
    );
    controller.dispose();
    if (newName != null && newName.isNotEmpty) {
      try {
        await progress.rename(newName);
      } catch (e) {
        if (context.mounted) showApiMessage(context, e);
      }
    }
  }

  Future<void> confirmReset(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Сбросить прогресс?'),
        content: const Text('Уроки, игры, практики, достижения, избранное и покупки будут сброшены. Монеты за уже выданные награды повторно не начисляются, покупки не возмещаются.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Сбросить', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (accepted == true) {
      try {
        await extras.resetSaved('all');
        await progress.loadForAccount(session.api);
      } catch (e) {
        if (context.mounted) showApiMessage(context, e);
      }
    }
  }

  Future<void> showRecovery(BuildContext context) async {
    try {
      final response = await session.api.request('POST', '/auth/recovery-key/rotate');
      if (context.mounted) await showRecoveryCode(context, response['recovery_key'] as String);
    } catch (error) {
      if (context.mounted) showApiMessage(context, error);
    }
  }

  Future<void> confirmImport(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Перенести старый прогресс?'),
        content: const Text('Добавим ранее пройденные уроки и избранные слова из браузера к этому аккаунту.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Отмена')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Перенести')),
        ],
      ),
    );
    if (accepted == true) {
      try {
        await progress.importLegacyProgress();
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Прежний прогресс перенесён')));
      } catch (e) {
        if (context.mounted) showApiMessage(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress.completed.length * 100 / lessons.length).round();
    return PageWidth(child: ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      children: [
         Text('Мой профиль', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.dark)),
        const SizedBox(height: 21),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(23), border: Border.all(color: AppColors.line)),
          child: Row(children: [
            Container(height: 70, width: 70, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(24)),
              child:  Icon(Icons.person_rounded, color: AppColors.green, size: 39)),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(progress.displayName, style:  TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: AppColors.dark)),
              const SizedBox(height: 5),
              Text('@${session.username} · Башкирский язык · v1.0.0 (кандидат)', style:  TextStyle(fontSize: 13, color: AppColors.muted)),
            ])),
            IconButton(tooltip: 'Изменить имя', onPressed: () => editName(context), icon:  Icon(Icons.edit_outlined, color: AppColors.green)),
          ]),
        ),
        const SizedBox(height: 19),
        Row(children: [
          Expanded(child: _ProfileStat(icon: Icons.bolt_rounded, number: '${progress.xp}', title: extras.tr('Очков опыта'), color: const Color(0xFFE3A52D))),
          const SizedBox(width: 10),
          Expanded(child: _ProfileStat(icon: Icons.local_fire_department_rounded, number: '${progress.activeStreak}', title: extras.tr('Дней подряд'), color: const Color(0xFFE48E4A))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _ProfileStat(icon: Icons.check_circle_outline_rounded, number: '${progress.completed.length}', title: extras.tr('Пройдено уроков'), color: AppColors.green)),
          const SizedBox(width: 10),
          Expanded(child: _ProfileStat(icon: Icons.bookmark_rounded, number: '${progress.favorites.length}', title: extras.tr('Избранных слов'), color: AppColors.green)),
        ]),
        const SizedBox(height: 27),
         Text(extras.tr('Мои достижения'), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.dark)),
        const SizedBox(height: 12),
        _Achievement(emoji: '🌱', title: 'Первый шаг', subtitle: 'Заверши первый урок', unlocked: progress.completed.isNotEmpty),
        const SizedBox(height: 9),
        _Achievement(emoji: '📚', title: 'Любознательный', subtitle: 'Пройди 3 урока', unlocked: progress.completed.length >= 3),
        const SizedBox(height: 9),
        _Achievement(emoji: '🏆', title: 'Хранитель языка', subtitle: 'Пройди 20 уроков', unlocked: progress.completed.length >= 20),
        const SizedBox(height: 9),
        _Achievement(emoji: '🏅', title: '50 уроков: Хранитель языка', subtitle: 'Пройди 50 уроков', unlocked: progress.completed.length >= 50),
        const SizedBox(height: 9),
        _Achievement(emoji: '👑', title: '100 уроков: Хранитель башкирского', subtitle: 'Пройди весь курс из 100 уроков', unlocked: progress.completed.length == lessons.length),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.greenLight, borderRadius: BorderRadius.circular(19)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Прогресс курса: $progressPercent% · ${lessons.length} уроков', style:  TextStyle(fontWeight: FontWeight.w900, color: AppColors.dark)),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progressPercent / 100, minHeight: 8, backgroundColor: AppColors.card, valueColor:  AlwaysStoppedAnimation(AppColors.green))),
          ]),
        ),
        FutureBuilder<bool>(
          future: progress.hasLegacyProgress(),
          builder: (context, snapshot) => snapshot.data == true
            ? Padding(
                padding: const EdgeInsets.only(top: 15),
                child: OutlinedButton.icon(
                  onPressed: () => confirmImport(context),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Перенести старый прогресс'),
                ),
              )
            : const SizedBox.shrink(),
        ),
        const SizedBox(height: 25),
        Card(clipBehavior: Clip.antiAlias, child: ExpansionTile(
          leading: const Icon(Icons.translate_rounded),
          initiallyExpanded: true,
          title: Text(extras.tr('Язык интерфейса'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(extras.tr('Язык, адаптация и Telegram')),
          children: [Padding(padding: const EdgeInsets.all(16), child: LearningSettings(extras: extras))],
        )),
        Card(clipBehavior: Clip.antiAlias, child: ExpansionTile(
          leading: const Icon(Icons.graphic_eq_rounded),
          title: Text(extras.tr('Настройки озвучки'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(extras.tr('Язык речи и голос')),
          children: [Padding(padding: const EdgeInsets.all(16), child:
            VoiceSettings(progress: progress, api: session.api, speech: speech, extras: extras))],
        )),
        Card(clipBehavior: Clip.antiAlias, child: ExpansionTile(
          leading: const Icon(Icons.palette_outlined),
          title: Text(extras.tr('Регион и оформление'), style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(extras.tr('Регион для рейтинга, темы приложения')),
          children: [Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            RegionSettings(extras: extras), const SizedBox(height: 12), ThemeSettings(extras: extras, progress: progress),
          ]))],
        )),
        Card(clipBehavior: Clip.antiAlias, child: ExpansionTile(
          leading: const Icon(Icons.cloud_done_outlined),
          title: const Text('Сохранения и сброс прогресса', style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text('Выбрать категории, сбросить уроки, игры и награды'),
          children: [Padding(padding: const EdgeInsets.all(16),
            child: SaveSettings(extras: extras, progress: progress, showResets: true))],
        )),
        Card(clipBehavior: Clip.antiAlias, child: ExpansionTile(
          leading: const Icon(Icons.info_outline),
          title: Text(extras.tr('О проекте и управление'), style: const TextStyle(fontWeight: FontWeight.w800)),
          children: [Padding(padding: const EdgeInsets.all(16), child: Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => FeedbackPage(api: session.api))),
              icon: const Icon(Icons.rate_review_outlined), label: const Text('Отправить фидбек')),
            OutlinedButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreatorPage())),
              icon: const Icon(Icons.groups_2_outlined), label: Text(extras.tr('Создатели'))),
            OutlinedButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AdminPage(api: session.api))),
              icon: const Icon(Icons.admin_panel_settings_outlined), label: Text(extras.tr('Админ меню'))),
          ]))],
        )),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => showRecovery(context),
          icon: const Icon(Icons.key_outlined),
          label: const Text('Создать резервный код для восстановления пароля'),
        ),
        const SizedBox(height: 11),
         Text('Вход запоминается локально в этом браузере, пока не выйдешь из аккаунта. При смене пароля все устройства выйдут.',
          style: TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 15),
        OutlinedButton.icon(
          onPressed: session.signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Выйти из аккаунта'),
        ),
        const SizedBox(height: 17),
        TextButton.icon(
          onPressed: () => confirmReset(context),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Сбросить все сохранения'),
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
        ),
      ],
    ));
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.icon, required this.number, required this.title, required this.color});
  final IconData icon;
  final String number;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(19), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 9),
        Text(number, style:  TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.dark)),
        Text(title, style:  TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    );
  }
}

class _Achievement extends StatelessWidget {
  const _Achievement({required this.emoji, required this.title, required this.subtitle, required this.unlocked});
  final String emoji;
  final String title;
  final String subtitle;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Container(width: 48, height: 48, alignment: Alignment.center,
          decoration: BoxDecoration(color: unlocked ? AppColors.greenLight : const Color(0xFFF1F3F0), borderRadius: BorderRadius.circular(15)),
          child: unlocked ? Text(emoji, style: const TextStyle(fontSize: 25)) :  Icon(Icons.lock_outline_rounded, color: AppColors.muted)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style:  TextStyle(fontWeight: FontWeight.w800, color: AppColors.dark)),
          const SizedBox(height: 3),
          Text(subtitle, style:  TextStyle(fontSize: 12, color: AppColors.muted)),
        ])),
        if (unlocked)  Icon(Icons.check_circle_rounded, color: AppColors.green),
      ]),
    );
  }
}

void showApiMessage(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
}

Future<void> playSpeech(BuildContext context, SpeechPlayer speech, String text) async {
  try {
    await speech.speak(text);
  } catch (error) {
    if (context.mounted) showApiMessage(context, error);
  }
}


Future<void> showRecoveryCode(BuildContext context, String code) async {
  await showDialog<void>(context: context, barrierDismissible: false, builder: (dialogContext) => AlertDialog(
    title: const Text('Резервный код аккаунта'),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Сохрани код в безопасном месте. По нему можно восстановить пароль, если забудешь его.'),
      const SizedBox(height: 15),
      SelectableText(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
      const SizedBox(height: 10),
       Text('Код показывается один раз. Не отправляй его другим людям.',
        style: TextStyle(fontSize: 12, color: AppColors.muted)),
    ]),
    actions: [
      TextButton.icon(onPressed: () async {
        await Clipboard.setData(ClipboardData(text: code));
      }, icon: const Icon(Icons.copy_outlined), label: const Text('Копировать')),
      FilledButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Я сохранил код')),
    ],
  ));
}
