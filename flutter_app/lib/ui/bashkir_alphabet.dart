import 'package:flutter/material.dart';
import '../data/extras_controller.dart';
import '../services/speech_player.dart';

/// All 42 letters of the modern Bashkir Cyrillic alphabet. The speech model
/// hears an example word rather than an isolated glyph, whose pronunciation
/// can be ambiguous for a generic TTS engine.
class BashkirLetter {
  const BashkirLetter(this.letter, this.example, this.meaning, this.note, {this.special = false});
  final String letter, example, meaning, note;
  final bool special;
}

const _englishLetterExamples = <String>[
  'apple', 'mother', 'child', 'wagon', 'flower', 'scholar', 'friend', 'wind', 'spruce', 'magazine', 'time', 'big', 'bread', 'year', 'book', 'sun', 'lamp', 'school', 'ray', 'lonely', 'socks', 'house', 'desk', 'thank you', 'flower', 'short', 'mountain', 'forest', 'plant', 'science', 'people', 'water', 'circus', 'suitcase', 'spring', 'cabbage soup', 'object', 'dew', 'album', 'work', 'road', 'spring',
];

const bashkirLetters = <BashkirLetter>[
  BashkirLetter('А', 'алма', 'яблоко', 'Гласный звук'),
  BashkirLetter('Ә', 'әсәй', 'мама', 'Передний гласный; не равен русскому «э»', special: true),
  BashkirLetter('Б', 'бала', 'ребёнок', 'Согласный звук'),
  BashkirLetter('В', 'вагон', 'вагон', 'Чаще встречается в заимствованных словах'),
  BashkirLetter('Г', 'гөл', 'цветок', 'Согласный звук'),
  BashkirLetter('Ғ', 'ғалим', 'учёный', 'Глубокий звонкий заднеязычный звук', special: true),
  BashkirLetter('Д', 'дуҫ', 'друг', 'Согласный звук'),
  BashkirLetter('Е', 'ел', 'ветер', 'Гласная буква'),
  BashkirLetter('Ё', 'ёлка', 'ёлка', 'Встречается в заимствованиях'),
  BashkirLetter('Ж', 'журнал', 'журнал', 'Встречается в заимствованиях'),
  BashkirLetter('З', 'заман', 'время', 'Согласный звук'),
  BashkirLetter('Ҙ', 'ҙур', 'большой', 'Звонкий межзубный согласный', special: true),
  BashkirLetter('И', 'икмәк', 'хлеб', 'Гласный звук'),
  BashkirLetter('Й', 'йыл', 'год', 'Краткий согласный звук'),
  BashkirLetter('К', 'китап', 'книга', 'Согласный звук'),
  BashkirLetter('Ҡ', 'ҡояш', 'солнце', 'Глубокий заднеязычный согласный', special: true),
  BashkirLetter('Л', 'лампа', 'лампа', 'Согласный звук'),
  BashkirLetter('М', 'мәктәп', 'школа', 'Согласный звук'),
  BashkirLetter('Н', 'нур', 'луч', 'Согласный звук'),
  BashkirLetter('Ң', 'яңғыҙ', 'одинокий', 'Носовой звук «ң»; в примере стоит в середине слова', special: true),
  BashkirLetter('О', 'ойоҡ', 'носки', 'Гласный звук'),
  BashkirLetter('Ө', 'өй', 'дом', 'Передний огублённый гласный', special: true),
  BashkirLetter('П', 'парта', 'парта', 'Согласный звук'),
  BashkirLetter('Р', 'рәхмәт', 'спасибо', 'Согласный звук'),
  BashkirLetter('С', 'сәскә', 'цветок', 'Согласный звук'),
  BashkirLetter('Ҫ', 'ҡыҫҡа', 'короткий', 'Глухой межзубный согласный', special: true),
  BashkirLetter('Т', 'тау', 'гора', 'Согласный звук'),
  BashkirLetter('У', 'урман', 'лес', 'Гласный звук'),
  BashkirLetter('Ү', 'үҫемлек', 'растение', 'Передний огублённый гласный', special: true),
  BashkirLetter('Ф', 'фән', 'наука', 'Согласный звук'),
  BashkirLetter('Х', 'халыҡ', 'народ', 'Заднеязычный согласный'),
  BashkirLetter('Һ', 'һыу', 'вода', 'Гортанный согласный', special: true),
  BashkirLetter('Ц', 'цирк', 'цирк', 'Встречается в заимствованиях'),
  BashkirLetter('Ч', 'чемодан', 'чемодан', 'Согласный звук'),
  BashkirLetter('Ш', 'шишмә', 'родник', 'Согласный звук'),
  BashkirLetter('Щ', 'щи', 'щи', 'Встречается в заимствованиях'),
  BashkirLetter('Ъ', 'объект', 'объект', 'Разделительный знак, отдельного звука нет'),
  BashkirLetter('Ы', 'ысыҡ', 'роса', 'Гласный звук'),
  BashkirLetter('Ь', 'альбом', 'альбом', 'Разделительный / мягкий знак, отдельного звука нет'),
  BashkirLetter('Э', 'эш', 'работа', 'Гласный звук'),
  BashkirLetter('Ю', 'юл', 'дорога', 'Гласная буква'),
  BashkirLetter('Я', 'яҙ', 'весна', 'Гласная буква'),
];

class BashkirAlphabetPanel extends StatelessWidget {
  const BashkirAlphabetPanel({super.key, required this.speech, required this.extras});
  final SpeechPlayer speech;
  final ExtrasController extras;

  Future<void> _play(BuildContext context, BashkirLetter entry) async {
    try {
      await speech.speak(entry.example, language: 'bak', speaker: 'bak_aigul');
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${extras.tr('Озвучка недоступна')}: $error')));
      }
    }
  }

  void _open(BuildContext context, BashkirLetter entry) {
    showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true,
      builder: (sheet) => SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 82, height: 82, alignment: Alignment.center,
                decoration: BoxDecoration(color: Theme.of(sheet).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20)),
                child: Text(entry.letter, style: const TextStyle(fontSize: 49, fontWeight: FontWeight.w900))),
              const SizedBox(width: 17),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${extras.tr('Буква')} ${entry.letter}', style: Theme.of(sheet).textTheme.titleLarge),
                Text(entry.special ? extras.tr('Особый башкирский звук') : extras.tr('Буква башкирского алфавита'),
                  style: Theme.of(sheet).textTheme.bodyMedium),
              ])),
            ]),
            const SizedBox(height: 18),
            Text('${extras.tr('Пример')}: ${entry.example}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            Text(extras.baseLanguage == 'en'
              ? 'English: ${_englishLetterExamples[bashkirLetters.indexOf(entry)]}'
              : '${extras.tr('По-русски')}: ${entry.meaning}',
              style: Theme.of(sheet).textTheme.bodyMedium),
            const SizedBox(height: 10),
            if (extras.baseLanguage == 'ru') Text(entry.note, style: Theme.of(sheet).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(extras.tr('Нейросеть произнесёт слово-пример, а не отдельную букву.'),
              style: Theme.of(sheet).textTheme.bodySmall),
            const SizedBox(height: 19),
            FilledButton.icon(onPressed: () => _play(sheet, entry),
              icon: const Icon(Icons.volume_up_rounded),
              label: Text(extras.tr('Послушать произношение'))),
          ],
        )))));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final width = constraints.maxWidth;
    final count = width < 320 ? 4 : width < 550 ? 5 : 7;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(3, 9, 3, 28),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count, mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: 1),
      itemCount: bashkirLetters.length,
      itemBuilder: (context, i) {
        final letter = bashkirLetters[i];
        return Material(color: letter.special ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(onTap: () => _open(context, letter), borderRadius: BorderRadius.circular(16),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(letter.letter, style: TextStyle(fontSize: width < 400 ? 25 : 30, fontWeight: FontWeight.w900,
                color: Theme.of(context).colorScheme.onSurface)),
              if (letter.special) Icon(Icons.volume_up_rounded, size: 14,
                color: Theme.of(context).colorScheme.primary),
            ]))));
      });
  });
}
