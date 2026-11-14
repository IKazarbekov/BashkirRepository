import 'package:flutter/material.dart';
import '../data/lessons.dart';

/// A small offline teacher script for every lesson. The learning content comes
/// from the actual lesson examples; the explanations use the chosen UI language.
class LessonDialogue {
  static const _copy = <String, List<String>>{
    'ru': [
      'Привет! Сегодня разберём тему «{topic}». {subtitle}',
      'Перед вопросами познакомимся с примерами. Внимательно прочитай и попробуй произнести: {examples}',
      'Эти выражения пригодятся в обычном общении. Не торопись: можно переслушивать, открывать подсказки и задавать вопросы учителю. Теперь проверим, что запомнилось!',
    ],
    'en': [
      'Hello! Today we will study “{topic}”. This topic is part of your Bashkir course.',
      'Let us start with useful Bashkir expressions. Read and try saying: {examples}',
      'You can use these expressions in everyday conversations. Listen again or ask your tutor if anything is unclear. Ready to practise?',
    ],
    'tt': [
      'Сәләм! Бүген «{topic}» темасын өйрәнәбез. Бу — башкорт теле дәресе.',
      'Башта сүзләр һәм мисаллар белән танышыйк. Укып, әйтеп кара: {examples}',
      'Бу сүзләр көндәлек сөйләшүдә кирәк. Аңлашылмаса, кабат тыңла яки укытучыдан сора. Хәзер биремнәрне үтик!',
    ],
    'kk': [
      'Сәлем! Бүгін «{topic}» тақырыбын үйренеміз. Бұл — башқұрт тілі сабағы.',
      'Алдымен сөздер мен мысалдарды оқып көр. Дауыстап айтып көр: {examples}',
      'Бұл сөздер күнделікті әңгімеде қажет болады. Түсінбесең, қайта тыңда немесе мұғалімнен сұра. Енді тапсырмаға көшейік!',
    ],
    'ba': [
      'Һаумы! Бөгөн «{topic}» темаһын өйрәнәбеҙ.',
      'Башта һүҙҙәр һәм миҫалдар менән танышайыҡ. Уҡып, әйтеп ҡара: {examples}',
      'Был һүҙҙәр көндәлек һөйләшеүҙә кәрәк. Аңлашылмаһа, тағы тыңла йәки уҡытыусынан һора. Хәҙер күнегеүҙәргә күсәйек!',
    ],
  };

  static String sample(Exercise q, String language) {
    final match = RegExp(r'«([^»]+)»').firstMatch(q.prompt);
    final quote = match?.group(1);
    if (q.type == ExerciseType.arrange) {
      return q.correctAnswer;
    }
    if (language != 'ru') {
      final translation = q.meaningByLanguage[language];
      return translation == null ? q.spokenText : '${q.correctAnswer} — $translation';
    }
    if (quote == null) return q.correctAnswer;
    if (q.prompt.startsWith('Что значит') || q.prompt.startsWith('Что означает')) {
      return '$quote — ${q.correctAnswer}';
    }
    return '${q.correctAnswer} — $quote';
  }

  static String message(Lesson lesson, int stage, String language, {String Function(String)? adapt}) {
    final examples = lesson.exercises.take(3).map((q) => sample(q, language)).join(' • ');
    final phrases = _copy[language] ?? _copy['ru']!;
    final message = phrases[stage.clamp(0, phrases.length - 1).toInt()]
      .replaceAll('{topic}', lesson.titleFor(language))
      .replaceAll('{subtitle}', lesson.subtitleFor(language))
      .replaceAll('{examples}', examples);
    return adapt == null ? message : adapt(message);
  }

  /// Approximate Russian-letter reading, explicitly marked as an aid only.
  /// Bashkir sounds such as ҡ, ғ, ҙ, ҫ cannot be represented exactly this way.
  static String russianReading(String bashkir) {
    const sounds = <String, String>{
      'ә':'э','Ә':'Э','ө':'ё','Ө':'Ё','ү':'ю','Ү':'Ю',
      'ҡ':'к','Ҡ':'К','ғ':'г','Ғ':'Г','ҙ':'з','Ҙ':'З',
      'ҫ':'с','Ҫ':'С','ң':'нг','Ң':'Нг','һ':'х','Һ':'Х',
    };
    return bashkir.split('').map((c) => sounds[c] ?? c).join();
  }
}

class MascotDialogue extends StatelessWidget {
  const MascotDialogue({super.key, required this.name, required this.text});
  final String name;
  final String text;
  @override Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 320),
    transitionBuilder: (child, animation) => FadeTransition(opacity: animation,
      child: SlideTransition(position: Tween(begin: const Offset(.06, .08), end: Offset.zero).animate(animation), child: child)),
    child: Container(key: ValueKey(text), width: double.infinity,
      padding: const EdgeInsets.all(15), decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .18)),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(20), bottomRight: Radius.circular(20), bottomLeft: Radius.circular(20))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15,
          color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 7),
        TweenAnimationBuilder<int>(key: ValueKey(text), tween: IntTween(begin: 0, end: text.length),
          duration: Duration(milliseconds: (text.length * 16).clamp(500, 2700).toInt()),
          builder: (context, count, _) => Text(text.substring(0, count),
            style: const TextStyle(fontSize: 15, height: 1.48))),
      ])),
  );
}
