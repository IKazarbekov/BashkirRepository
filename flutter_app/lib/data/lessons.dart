import 'lesson_translations.dart';
import '../services/api_client.dart';

enum ExerciseType { choice, arrange }

class Exercise {
  const Exercise.choice({
    required this.prompt,
    required this.answers,
    required this.correctAnswer,
    this.note = '',
    this.meaningByLanguage = const {},
  })  : type = ExerciseType.choice,
        words = const [];

  const Exercise.arrange({
    required this.prompt,
    required this.words,
    required this.correctAnswer,
    this.note = '',
    this.meaningByLanguage = const {},
  })  : type = ExerciseType.arrange,
        answers = const [];

  final ExerciseType type;
  final String prompt;
  final List<String> answers;
  final List<String> words;
  final String correctAnswer;
  final String note;
  final Map<String, String> meaningByLanguage;

  String promptFor(String language) {
    if (language == 'ru') return prompt;
    final meaning = meaningByLanguage[language];
    if (meaning != null && meaning.isNotEmpty) {
      if (type == ExerciseType.arrange) {
        return {'en': 'Build the Bashkir sentence','tt':'Башкортча җөмлә төзе','kk':'Башқұртша сөйлем құрастыр','ba':'Башҡортса һөйләм төҙө'}[language] ?? prompt;
      }
      final direction = {'en': 'Choose the Bashkir word for','tt':'Башкортча сүзне сайла','kk':'Башқұртша сөзді таңда','ba':'Башҡортса һүҙҙе һайла'}[language] ?? 'Choose';
      return '$direction: “$meaning”';
    }
    // For old lessons lacking a reviewed translation, show a listening task
    // rather than inserting an untranslated Russian-only question.
    return type == ExerciseType.arrange
        ? ({'en':'Build the sentence you hear','tt':'Ишеткән җөмләне төзе','kk':'Естіген сөйлемді құрастыр','ba':'Ишеткән һөйләмде төҙө'}[language] ?? prompt)
        : ({'en':'Listen and choose the Bashkir answer','tt':'Тыңла һәм башкортча җавапны сайла','kk':'Тыңда да башқұртша жауапты таңда','ba':'Тыңла һәм башҡортса яуапты һайла'}[language] ?? prompt);
  }

  String noteFor(String language) {
    if (language == 'ru') return note;
    final meaning = meaningByLanguage[language];
    if (meaning != null && language == 'en') return '$correctAnswer — $meaning';
    return correctAnswer;
  }

  String get spokenText {
    if (prompt.startsWith('Что значит') || prompt.startsWith('Что означает')) {
      return RegExp(r'«([^»]+)»').firstMatch(prompt)?.group(1) ?? correctAnswer;
    }
    return correctAnswer;
  }
}

class Lesson {
  const Lesson({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.exercises,
    this.titleTranslations = const {},
    this.subtitleTranslations = const {},
  });

  final String title;
  final String subtitle;
  final String icon;
  final List<Exercise> exercises;
  final Map<String, String> titleTranslations;
  final Map<String, String> subtitleTranslations;
  String titleFor(String language) {
    if (language == 'ru') return title;
    final translated = titleTranslations[language];
    if (translated != null) return translated;
    final index = lessons.indexOf(this);
    return legacyLessonTitles[index]?[language] ?? title;
  }
  String subtitleFor(String language) => language == 'ru' ? subtitle : subtitleTranslations[language] ?? ({'en':'New Bashkir words and expressions','tt':'Яңа башкортча сүзләр','kk':'Жаңа башқұртша сөздер','ba':'Яңы башҡортса һүҙҙәр'}[language] ?? '');
}

// Lessons are loaded from the shared FastAPI/SQL catalog after sign-in.
// Stable indices match the legacy course, so old XP and completed lessons remain valid.
final List<Lesson> lessons = <Lesson>[];


class WordEntry {
  const WordEntry(this.bashkir, this.russian, this.category);
  final String bashkir;
  final String russian;
  final String category;
}

const dictionary = <WordEntry>[
  WordEntry('Сәләм', 'Привет', 'Общение'),
  WordEntry('Һаумыһығыҙ', 'Здравствуйте', 'Общение'),
  WordEntry('Рәхмәт', 'Спасибо', 'Общение'),
  WordEntry('Һау бул', 'До свидания', 'Общение'),
  WordEntry('Эйе', 'Да', 'Общение'),
  WordEntry('Юҡ', 'Нет', 'Общение'),
  WordEntry('Хәлдәр нисек?', 'Как дела?', 'Общение'),
  WordEntry('Мин', 'Я', 'Знакомство'),
  WordEntry('Минең исемем…', 'Меня зовут…', 'Знакомство'),
  WordEntry('Әсәй', 'Мама', 'Семья'),
  WordEntry('Атай', 'Папа', 'Семья'),
  WordEntry('Өләсәй', 'Бабушка', 'Семья'),
  WordEntry('Бер', 'Один', 'Числа'),
  WordEntry('Ике', 'Два', 'Числа'),
  WordEntry('Өс', 'Три', 'Числа'),
  WordEntry('Дүрт', 'Четыре', 'Числа'),
  WordEntry('Биш', 'Пять', 'Числа'),
  WordEntry('Аҡ', 'Белый', 'Цвета'),
  WordEntry('Ҡара', 'Чёрный', 'Цвета'),
  WordEntry('Ҡыҙыл', 'Красный', 'Цвета'),
  WordEntry('Күк', 'Синий', 'Цвета'),
  WordEntry('Йәшел', 'Зелёный', 'Цвета'),
  WordEntry('Һары', 'Жёлтый', 'Цвета'),
  WordEntry('Хәйерле иртә', 'Доброе утро', 'Каждый день'),
  WordEntry('Хәйерле көн', 'Добрый день', 'Каждый день'),
  WordEntry('Хәйерле кис', 'Добрый вечер', 'Каждый день'),
  WordEntry('Рәхим ит', 'Добро пожаловать / заходи', 'Каждый день'),
  WordEntry('Китап', 'Книга', 'Учёба'),
  WordEntry('Дәфтәр', 'Тетрадь', 'Учёба'),
  WordEntry('Мәктәп', 'Школа', 'Учёба'),
  WordEntry('Уҡыусы', 'Ученик', 'Учёба'),
  WordEntry('Уҡытыусы', 'Учитель', 'Учёба'),
  WordEntry('Һыу', 'Вода', 'Природа'),
  WordEntry('Урман', 'Лес', 'Природа'),
  WordEntry('Ҡояш', 'Солнце', 'Природа'),
  WordEntry('Икмәк', 'Хлеб', 'Еда'),
  WordEntry('Һөт', 'Молоко', 'Еда'),
  WordEntry('Алма', 'Яблоко', 'Еда'),
  WordEntry('Сәй', 'Чай', 'Еда'),
  WordEntry('Өй', 'Дом', 'Дом'),
  WordEntry('Ишек', 'Дверь', 'Дом'),
  WordEntry('Тәҙрә', 'Окно', 'Дом'),
  WordEntry('Бөгөн', 'Сегодня', 'Время'),
  WordEntry('Иртәгә', 'Завтра', 'Время'),
  WordEntry('Кисә', 'Вчера', 'Время'),
  WordEntry('Хәҙер', 'Сейчас', 'Время'),
  WordEntry('Бесәй', 'Кошка', 'Животные'),
  WordEntry('Эт', 'Собака', 'Животные'),
  WordEntry('Ҡош', 'Птица', 'Животные'),
  WordEntry('Ат', 'Лошадь', 'Животные'),
  WordEntry('Ҡала', 'Город', 'Город'),
  WordEntry('Урам', 'Улица', 'Город'),
  WordEntry('Ауыл', 'Деревня', 'Город'),
  WordEntry('Юл', 'Дорога', 'Город'),
  WordEntry('Яҙам', 'Пишу', 'Действия'),
  WordEntry('Барам', 'Иду', 'Действия'),
  WordEntry('Киләм', 'Прихожу', 'Действия'),
  WordEntry('Дуҫ', 'Друг', 'Люди'),
  WordEntry('Иптәш', 'Товарищ', 'Люди'),
  WordEntry('Ямғыр', 'Дождь', 'Природа'),
  WordEntry('Ҡар', 'Снег', 'Природа'),
  WordEntry('Йылы', 'Тёплый', 'Погода'),
  WordEntry('Һалҡын', 'Холодный', 'Погода'),
  WordEntry('Беләм', 'Знаю', 'Действия'),
  WordEntry('Күрәм', 'Вижу', 'Действия'),
  WordEntry('Башҡорт теле', 'Башкирский язык', 'Выражения'),
  // Vocabulary introduced in lessons 21–50.
  WordEntry('Баш', 'Голова', 'Тело и здоровье'),
  WordEntry('Ҡул', 'Рука', 'Тело и здоровье'),
  WordEntry('Аяҡ', 'Нога', 'Тело и здоровье'),
  WordEntry('Күҙ', 'Глаз', 'Тело и здоровье'),
  WordEntry('Ҡолаҡ', 'Ухо', 'Тело и здоровье'),
  WordEntry('Күлдәк', 'Платье', 'Одежда'),
  WordEntry('Салбар', 'Брюки', 'Одежда'),
  WordEntry('Бүрек', 'Шапка', 'Одежда'),
  WordEntry('Итек', 'Сапоги', 'Одежда'),
  WordEntry('Кейем', 'Одежда', 'Одежда'),
  WordEntry('Яҙ', 'Весна', 'Времена года'),
  WordEntry('Йәй', 'Лето', 'Времена года'),
  WordEntry('Көҙ', 'Осень', 'Времена года'),
  WordEntry('Ҡыш', 'Зима', 'Времена года'),
  WordEntry('Миҙгел', 'Время года', 'Времена года'),
  WordEntry('Дүшәмбе', 'Понедельник', 'Дни недели'),
  WordEntry('Шишәмбе', 'Вторник', 'Дни недели'),
  WordEntry('Шаршамбы', 'Среда', 'Дни недели'),
  WordEntry('Кесаҙна', 'Четверг', 'Дни недели'),
  WordEntry('Йома', 'Пятница', 'Дни недели'),
  WordEntry('Иртә', 'Утро', 'Время суток'),
  WordEntry('Көндөҙ', 'Днём', 'Время суток'),
  WordEntry('Кис', 'Вечер', 'Время суток'),
  WordEntry('Төн', 'Ночь', 'Время суток'),
  WordEntry('Таң', 'Рассвет', 'Время суток'),
  WordEntry('Табип', 'Врач', 'Кем работают люди'),
  WordEntry('Төҙөүсе', 'Строитель', 'Кем работают люди'),
  WordEntry('Йырсы', 'Певец', 'Кем работают люди'),
  WordEntry('Рәссам', 'Художник', 'Кем работают люди'),
  WordEntry('Ашнаҡсы', 'Повар', 'Кем работают люди'),
  WordEntry('Автобус', 'Автобус', 'Поездка по городу'),
  WordEntry('Поезд', 'Поезд', 'Поездка по городу'),
  WordEntry('Машина', 'Автомобиль', 'Поездка по городу'),
  WordEntry('Велосипед', 'Велосипед', 'Поездка по городу'),
  WordEntry('Туҡталыш', 'Остановка', 'Поездка по городу'),
  WordEntry('Уңға', 'Направо', 'Как пройти?'),
  WordEntry('Һулға', 'Налево', 'Как пройти?'),
  WordEntry('Алға', 'Вперёд', 'Как пройти?'),
  WordEntry('Артҡа', 'Назад', 'Как пройти?'),
  WordEntry('Өҫкә', 'Наверх', 'Как пройти?'),
  WordEntry('Аш', 'Суп', 'На кухне'),
  WordEntry('Тоҙ', 'Соль', 'На кухне'),
  WordEntry('Шәкәр', 'Сахар', 'На кухне'),
  WordEntry('Бал', 'Мёд', 'На кухне'),
  WordEntry('Май', 'Масло', 'На кухне'),
  WordEntry('Тау', 'Гора', 'Горы и реки'),
  WordEntry('Йылға', 'Река', 'Горы и реки'),
  WordEntry('Күл', 'Озеро', 'Горы и реки'),
  WordEntry('Дала', 'Степь', 'Горы и реки'),
  WordEntry('Сәскә', 'Цветок', 'Горы и реки'),
  WordEntry('Ҡарға', 'Ворона', 'Птицы Башкортостана'),
  WordEntry('Күгәрсен', 'Голубь', 'Птицы Башкортостана'),
  WordEntry('Сыйырсыҡ', 'Скворец', 'Птицы Башкортостана'),
  WordEntry('Торна', 'Журавль', 'Птицы Башкортостана'),
  WordEntry('Бөркөт', 'Орёл', 'Птицы Башкортостана'),
  WordEntry('Шатлыҡ', 'Радость', 'Чувства и эмоции'),
  WordEntry('Ҡурҡыу', 'Страх', 'Чувства и эмоции'),
  WordEntry('Ҡыуаныс', 'Удовольствие', 'Чувства и эмоции'),
  WordEntry('Һағыш', 'Тоска', 'Чувства и эмоции'),
  WordEntry('Мөхәббәт', 'Любовь', 'Чувства и эмоции'),
  WordEntry('Ағай', 'Старший брат', 'Родственники'),
  WordEntry('Апай', 'Старшая сестра', 'Родственники'),
  WordEntry('Ҡусты', 'Младший брат', 'Родственники'),
  WordEntry('Һеңле', 'Младшая сестра', 'Родственники'),
  WordEntry('Ҡыҙ', 'Дочь', 'Родственники'),
  WordEntry('Сынаяҡ', 'Чашка', 'Посуда'),
  WordEntry('Тәлинкә', 'Тарелка', 'Посуда'),
  WordEntry('Кәстрүл', 'Кастрюля', 'Посуда'),
  WordEntry('Бысаҡ', 'Нож', 'Посуда'),
  WordEntry('Сәнске', 'Вилка', 'Посуда'),
  WordEntry('Үлән', 'Трава', 'Деревья и растения'),
  WordEntry('Япраҡ', 'Лист', 'Деревья и растения'),
  WordEntry('Тамыр', 'Корень', 'Деревья и растения'),
  WordEntry('Орлоҡ', 'Семя', 'Деревья и растения'),
  WordEntry('Ҡайын', 'Берёза', 'Деревья и растения'),
  WordEntry('Һыйыр', 'Корова', 'На ферме'),
  WordEntry('Һарыҡ', 'Овца', 'На ферме'),
  WordEntry('Кәзә', 'Коза', 'На ферме'),
  WordEntry('Тауыҡ', 'Курица', 'На ферме'),
  WordEntry('Ҡаҙ', 'Гусь', 'На ферме'),
  WordEntry('Кем', 'Кто', 'Задаём вопросы'),
  WordEntry('Нимә', 'Что', 'Задаём вопросы'),
  WordEntry('Ҡайҙа', 'Где', 'Задаём вопросы'),
  WordEntry('Ҡасан', 'Когда', 'Задаём вопросы'),
  WordEntry('Нисек', 'Как', 'Задаём вопросы'),
  WordEntry('Был', 'Этот', 'Здесь и там'),
  WordEntry('Теге', 'Тот', 'Здесь и там'),
  WordEntry('Бында', 'Здесь', 'Здесь и там'),
  WordEntry('Тегендә', 'Там', 'Здесь и там'),
  WordEntry('Анауҙа', 'Вот там', 'Здесь и там'),
  WordEntry('Тиҙ', 'Быстро', 'Как часто?'),
  WordEntry('Әкрен', 'Медленно', 'Как часто?'),
  WordEntry('Йыш', 'Часто', 'Как часто?'),
  WordEntry('Һирәк', 'Редко', 'Как часто?'),
  WordEntry('Һәр ваҡыт', 'Всегда', 'Как часто?'),
  WordEntry('Йүгерәм', 'Я бегу', 'Движение'),
  WordEntry('Атлайым', 'Я шагаю', 'Движение'),
  WordEntry('Йөҙәм', 'Я плаваю', 'Движение'),
  WordEntry('Осам', 'Я летаю', 'Движение'),
  WordEntry('Туҡтайым', 'Я останавливаюсь', 'Движение'),
  WordEntry('Математика', 'Математика', 'Любимые предметы'),
  WordEntry('Тарих', 'История', 'Любимые предметы'),
  WordEntry('География', 'География', 'Любимые предметы'),
  WordEntry('Әҙәбиәт', 'Литература', 'Любимые предметы'),
  WordEntry('Биология', 'Биология', 'Любимые предметы'),
  WordEntry('Ҙур', 'Большой', 'Сравниваем предметы'),
  WordEntry('Бәләкәй', 'Маленький', 'Сравниваем предметы'),
  WordEntry('Оҙон', 'Длинный', 'Сравниваем предметы'),
  WordEntry('Ҡыҫҡа', 'Короткий', 'Сравниваем предметы'),
  WordEntry('Ауыр', 'Тяжёлый', 'Сравниваем предметы'),
  WordEntry('Хаҡ', 'Цена', 'На рынке'),
  WordEntry('Аҡса', 'Деньги', 'На рынке'),
  WordEntry('Ҡиммәт', 'Дорогой', 'На рынке'),
  WordEntry('Арзан', 'Дешёвый', 'На рынке'),
  WordEntry('Һатыусы', 'Продавец', 'На рынке'),
  WordEntry('Ярҙәм', 'Помощь', 'Нужна помощь'),
  WordEntry('Хәүеф', 'Опасность', 'Нужна помощь'),
  WordEntry('Һаҡ', 'Осторожный', 'Нужна помощь'),
  WordEntry('Ҡотҡарыусы', 'Спасатель', 'Нужна помощь'),
  WordEntry('Хәүефһеҙлек', 'Безопасность', 'Нужна помощь'),
  WordEntry('Йыр', 'Песня', 'Песни и инструменты'),
  WordEntry('Көй', 'Мелодия', 'Песни и инструменты'),
  WordEntry('Ҡурай', 'Курай', 'Песни и инструменты'),
  WordEntry('Бейеү', 'Танец', 'Песни и инструменты'),
  WordEntry('Думбыра', 'Думбыра', 'Песни и инструменты'),
  WordEntry('Уйын', 'Игра', 'Спорт и соревнования'),
  WordEntry('Туп', 'Мяч', 'Спорт и соревнования'),
  WordEntry('Йүгереү', 'Бег', 'Спорт и соревнования'),
  WordEntry('Ярыш', 'Соревнование', 'Спорт и соревнования'),
  WordEntry('Еңеү', 'Победа', 'Спорт и соревнования'),
  WordEntry('Телефон', 'Телефон', 'Технологии'),
  WordEntry('Компьютер', 'Компьютер', 'Технологии'),
  WordEntry('Интернет', 'Интернет', 'Технологии'),
  WordEntry('Экран', 'Экран', 'Технологии'),
  WordEntry('Көйләүҙәр', 'Настройки', 'Технологии'),
  WordEntry('Ил', 'Страна', 'Культура и язык'),
  WordEntry('Халыҡ', 'Народ', 'Культура и язык'),
  WordEntry('Мәҙәниәт', 'Культура', 'Культура и язык'),
  WordEntry('Тел', 'Язык', 'Культура и язык'),
  WordEntry('Йола', 'Традиция', 'Культура и язык'),
  WordEntry('Һауа', 'Воздух', 'Погода вокруг нас'),
  WordEntry('Ел', 'Ветер', 'Погода вокруг нас'),
  WordEntry('Болот', 'Облако', 'Погода вокруг нас'),
  WordEntry('Яҡты', 'Светлый', 'Погода вокруг нас'),
  WordEntry('Ҡараңғы', 'Тёмный', 'Погода вокруг нас'),
  WordEntry('Һөйләшеү', 'Разговор', 'Я говорю по-башкирски'),
  WordEntry('Аңлау', 'Понимание', 'Я говорю по-башкирски'),
  WordEntry('Өйрәнеү', 'Обучение', 'Я говорю по-башкирски'),
  WordEntry('Күнегеү', 'Упражнение', 'Я говорю по-башкирски'),
  WordEntry('Ҡаҙаныш', 'Достижение', 'Я говорю по-башкирски'),

  // Vocabulary added for lessons 51–100.
  WordEntry('Зинһар', 'Пожалуйста', 'Вежливые просьбы'),
  WordEntry('Үтенес', 'Просьба', 'Вежливые просьбы'),
  WordEntry('Рөхсәт', 'Разрешение', 'Вежливые просьбы'),
  WordEntry('Яуап', 'Ответ', 'Вежливые просьбы'),
  WordEntry('Кәрәк', 'Нужно', 'Вежливые просьбы'),
  WordEntry('Саҡырыу', 'Приглашение', 'Приглашения'),
  WordEntry('Ҡунаҡ', 'Гость', 'Приглашения'),
  WordEntry('Бергә', 'Вместе', 'Приглашения'),
  WordEntry('Осрашыу', 'Встреча', 'Приглашения'),
  WordEntry('Килегеҙ', 'Приходите', 'Приглашения'),
  WordEntry('Уяныу', 'Пробуждение', 'Распорядок утра'),
  WordEntry('Тороу', 'Вставание', 'Распорядок утра'),
  WordEntry('Иртән', 'Утром', 'Распорядок утра'),
  WordEntry('Юйыныу', 'Умывание', 'Распорядок утра'),
  WordEntry('Иртәнге аш', 'Завтрак', 'Распорядок утра'),
  WordEntry('Сабын', 'Мыло', 'Личная гигиена'),
  WordEntry('Таҫтамал', 'Полотенце', 'Личная гигиена'),
  WordEntry('Теш', 'Зуб', 'Личная гигиена'),
  WordEntry('Таҙалыҡ', 'Чистота', 'Личная гигиена'),
  WordEntry('Тараҡ', 'Расчёска', 'Личная гигиена'),
  WordEntry('Шат', 'Радостный', 'Настроение'),
  WordEntry('Борсоулы', 'Обеспокоенный', 'Настроение'),
  WordEntry('Тыныс', 'Спокойный', 'Настроение'),
  WordEntry('Арыған', 'Уставший', 'Настроение'),
  WordEntry('Кәйеф', 'Настроение', 'Настроение'),
  WordEntry('Оҡшай', 'Нравится', 'Вкусы и предпочтения'),
  WordEntry('Яратам', 'Люблю', 'Вкусы и предпочтения'),
  WordEntry('Теләйем', 'Хочу', 'Вкусы и предпочтения'),
  WordEntry('Һайлайым', 'Выбираю', 'Вкусы и предпочтения'),
  WordEntry('Файҙалы', 'Полезный', 'Вкусы и предпочтения'),
  WordEntry('Уңайлы', 'Удобный', 'Свойства вещей'),
  WordEntry('Йомшаҡ', 'Мягкий', 'Свойства вещей'),
  WordEntry('Ҡаты', 'Твёрдый', 'Свойства вещей'),
  WordEntry('Еңел', 'Лёгкий', 'Свойства вещей'),
  WordEntry('Ныҡ', 'Прочный', 'Свойства вещей'),
  WordEntry('Өҫтәл', 'Стол', 'Где лежат вещи'),
  WordEntry('Аҫтында', 'Под', 'Где лежат вещи'),
  WordEntry('Өҫтөндә', 'На', 'Где лежат вещи'),
  WordEntry('Эсендә', 'Внутри', 'Где лежат вещи'),
  WordEntry('Янында', 'Рядом', 'Где лежат вещи'),
  WordEntry('Урам', 'Улица', 'По улицам города'),
  WordEntry('Сат', 'Перекрёсток', 'По улицам города'),
  WordEntry('Йәйәү', 'Пешком', 'По улицам города'),
  WordEntry('Светофор', 'Светофор', 'По улицам города'),
  WordEntry('Борола', 'Поворачивает', 'По улицам города'),
  WordEntry('Вокзал', 'Вокзал', 'Железная дорога'),
  WordEntry('Вагон', 'Вагон', 'Железная дорога'),
  WordEntry('Рельс', 'Рельс', 'Железная дорога'),
  WordEntry('Китә', 'Отправляется', 'Железная дорога'),
  WordEntry('Килә', 'Прибывает', 'Железная дорога'),
  WordEntry('Билет', 'Билет', 'Билеты и документы'),
  WordEntry('Паспорт', 'Паспорт', 'Билеты и документы'),
  WordEntry('Документ', 'Документ', 'Билеты и документы'),
  WordEntry('Урын', 'Место', 'Билеты и документы'),
  WordEntry('Тикшереү', 'Проверка', 'Билеты и документы'),
  WordEntry('Сәйәхәт', 'Путешествие', 'Путешествие зимой'),
  WordEntry('Юлсы', 'Путник', 'Путешествие зимой'),
  WordEntry('Сумка', 'Сумка', 'Путешествие зимой'),
  WordEntry('Чемодан', 'Чемодан', 'Путешествие зимой'),
  WordEntry('Ҡунаҡхана', 'Гостиница', 'Путешествие зимой'),
  WordEntry('Еләк', 'Ягода', 'Лесные ягоды'),
  WordEntry('Ҡурай еләге', 'Малина', 'Лесные ягоды'),
  WordEntry('Бөрлөгән', 'Брусника', 'Лесные ягоды'),
  WordEntry('Ҡарағат', 'Смородина', 'Лесные ягоды'),
  WordEntry('Емеш', 'Плод', 'Лесные ягоды'),
  WordEntry('Баҡса', 'Сад', 'Цветущий сад'),
  WordEntry('Сәскәләр', 'Цветы', 'Цветущий сад'),
  WordEntry('Һыуғара', 'Поливает', 'Цветущий сад'),
  WordEntry('Үҫә', 'Растёт', 'Цветущий сад'),
  WordEntry('Түтәл', 'Грядка', 'Цветущий сад'),
  WordEntry('Бесәй', 'Кошка', 'Домашние питомцы'),
  WordEntry('Эт', 'Собака', 'Домашние питомцы'),
  WordEntry('Ашау', 'Еда', 'Домашние питомцы'),
  WordEntry('Эсә', 'Пьёт', 'Домашние питомцы'),
  WordEntry('Йоҡлай', 'Спит', 'Домашние питомцы'),
  WordEntry('Ауырта', 'Болит', 'Описание боли'),
  WordEntry('Баш ауыртыуы', 'Головная боль', 'Описание боли'),
  WordEntry('Тән', 'Тело', 'Описание боли'),
  WordEntry('Температура', 'Температура', 'Описание боли'),
  WordEntry('Сир', 'Болезнь', 'Описание боли'),
  WordEntry('Ҡабул итеү', 'Приём', 'На приёме у врача'),
  WordEntry('Табипхана', 'Поликлиника', 'На приёме у врача'),
  WordEntry('Анализ', 'Анализ', 'На приёме у врача'),
  WordEntry('Дауалау', 'Лечение', 'На приёме у врача'),
  WordEntry('Сәләмәтлек', 'Здоровье', 'На приёме у врача'),
  WordEntry('Дарыухана', 'Аптека', 'В аптеке'),
  WordEntry('Дарыу', 'Лекарство', 'В аптеке'),
  WordEntry('Рецепт', 'Рецепт', 'В аптеке'),
  WordEntry('Таблетка', 'Таблетка', 'В аптеке'),
  WordEntry('Файҙаланыу', 'Использование', 'В аптеке'),
  WordEntry('Йәшелсә', 'Овощ', 'Овощная лавка'),
  WordEntry('Кишер', 'Морковь', 'Овощная лавка'),
  WordEntry('Кәбеҫтә', 'Капуста', 'Овощная лавка'),
  WordEntry('Бәрәңге', 'Картофель', 'Овощная лавка'),
  WordEntry('Һуған', 'Лук', 'Овощная лавка'),
  WordEntry('Кило', 'Килограмм', 'Количество и вес'),
  WordEntry('Грамм', 'Грамм', 'Количество и вес'),
  WordEntry('Ярты', 'Половина', 'Количество и вес'),
  WordEntry('Үлсәү', 'Весы', 'Количество и вес'),
  WordEntry('Күпме', 'Сколько', 'Количество и вес'),
  WordEntry('Бешерәм', 'Готовлю', 'Готовим вместе'),
  WordEntry('Ҡайнатам', 'Кипячу', 'Готовим вместе'),
  WordEntry('Турайым', 'Нарезаю', 'Готовим вместе'),
  WordEntry('Ҡабартам', 'Разогреваю', 'Готовим вместе'),
  WordEntry('Болғатам', 'Перемешиваю', 'Готовим вместе'),
  WordEntry('Бишбармаҡ', 'Бешбармак', 'Башкирская кухня'),
  WordEntry('Ҡыҫтыбый', 'Кыстыбый', 'Башкирская кухня'),
  WordEntry('Өсбосмаҡ', 'Треугольный пирожок', 'Башкирская кухня'),
  WordEntry('Ҡымыҙ', 'Кумыс', 'Башкирская кухня'),
  WordEntry('Ҡорот', 'Корот', 'Башкирская кухня'),
  WordEntry('Меню', 'Меню', 'В кафе'),
  WordEntry('Заказ', 'Заказ', 'В кафе'),
  WordEntry('Официант', 'Официант', 'В кафе'),
  WordEntry('Кафе', 'Кафе', 'В кафе'),
  WordEntry('Түләү', 'Оплата', 'В кафе'),
  WordEntry('Табын', 'Застолье', 'За праздничным столом'),
  WordEntry('Һый', 'Угощение', 'За праздничным столом'),
  WordEntry('Теләктәр', 'Пожелания', 'За праздничным столом'),
  WordEntry('Ҡунаҡсыл', 'Гостеприимный', 'За праздничным столом'),
  WordEntry('Тәмле', 'Вкусный', 'За праздничным столом'),
  WordEntry('Буш ваҡыт', 'Свободное время', 'Свободное время'),
  WordEntry('Рәсем', 'Рисунок', 'Свободное время'),
  WordEntry('Төшөрәм', 'Рисую', 'Свободное время'),
  WordEntry('Мауығыу', 'Увлечение', 'Свободное время'),
  WordEntry('Йыйынам', 'Собираюсь', 'Свободное время'),
  WordEntry('Еп', 'Нить', 'Рукоделие'),
  WordEntry('Энә', 'Игла', 'Рукоделие'),
  WordEntry('Тегеү', 'Шитьё', 'Рукоделие'),
  WordEntry('Бәйләү', 'Вязание', 'Рукоделие'),
  WordEntry('Биҙәк', 'Узор', 'Рукоделие'),
  WordEntry('Әкиәт', 'Сказка', 'Читаем сказки'),
  WordEntry('Герой', 'Герой', 'Читаем сказки'),
  WordEntry('Башланыш', 'Начало', 'Читаем сказки'),
  WordEntry('Аҙаҡ', 'Конец', 'Читаем сказки'),
  WordEntry('Ваҡиға', 'Событие', 'Читаем сказки'),
  WordEntry('Театр', 'Театр', 'В театре'),
  WordEntry('Сәхнә', 'Сцена', 'В театре'),
  WordEntry('Тамаша', 'Представление', 'В театре'),
  WordEntry('Актёр', 'Актёр', 'В театре'),
  WordEntry('Тамашасы', 'Зритель', 'В театре'),
  WordEntry('Музыка', 'Музыка', 'Музыкальный вечер'),
  WordEntry('Моң', 'Напев', 'Музыкальный вечер'),
  WordEntry('Сығыш', 'Выступление', 'Музыкальный вечер'),
  WordEntry('Тыңлайым', 'Слушаю', 'Музыкальный вечер'),
  WordEntry('Бейеүсе', 'Танцор', 'Музыкальный вечер'),
  WordEntry('Байрам', 'Праздник', 'Праздники'),
  WordEntry('Ҡотлау', 'Поздравление', 'Праздники'),
  WordEntry('Бүләк', 'Подарок', 'Праздники'),
  WordEntry('Йыйылыш', 'Собрание', 'Праздники'),
  WordEntry('Һөйөнөс', 'Радость', 'Праздники'),
  WordEntry('Риүәйәт', 'Легенда', 'Легенды народа'),
  WordEntry('Батыр', 'Богатырь', 'Легенды народа'),
  WordEntry('Аҡһаҡал', 'Старейшина', 'Легенды народа'),
  WordEntry('Борон', 'Давным-давно', 'Легенды народа'),
  WordEntry('Хәтер', 'Память', 'Легенды народа'),
  WordEntry('Тарихсы', 'Историк', 'Память и история'),
  WordEntry('Үткән', 'Прошлое', 'Память и история'),
  WordEntry('Хәтирә', 'Воспоминание', 'Память и история'),
  WordEntry('Һәйкәл', 'Памятник', 'Память и история'),
  WordEntry('Музей', 'Музей', 'Память и история'),
  WordEntry('Тәбиғәт', 'Природа', 'Берегём природу'),
  WordEntry('Һаҡлау', 'Защита', 'Берегём природу'),
  WordEntry('Таҙа', 'Чистый', 'Берегём природу'),
  WordEntry('Бысраҡ', 'Грязный', 'Берегём природу'),
  WordEntry('Ҡалдыҡ', 'Отходы', 'Берегём природу'),
  WordEntry('Ҡағыҙ', 'Бумага', 'Раздельный сбор'),
  WordEntry('Пластик', 'Пластик', 'Раздельный сбор'),
  WordEntry('Быяла', 'Стекло', 'Раздельный сбор'),
  WordEntry('Айырым', 'Отдельно', 'Раздельный сбор'),
  WordEntry('Йыйыу', 'Сбор', 'Раздельный сбор'),
  WordEntry('Эш', 'Работа', 'На работе'),
  WordEntry('Хеҙмәткәр', 'Сотрудник', 'На работе'),
  WordEntry('Бүлек', 'Отдел', 'На работе'),
  WordEntry('Эш урыны', 'Рабочее место', 'На работе'),
  WordEntry('Етәксе', 'Руководитель', 'На работе'),
  WordEntry('Ултырыш', 'Заседание', 'Рабочая встреча'),
  WordEntry('Кәңәшмә', 'Совещание', 'Рабочая встреча'),
  WordEntry('Ваҡыт', 'Время', 'Рабочая встреча'),
  WordEntry('Башлана', 'Начинается', 'Рабочая встреча'),
  WordEntry('Тәмамлана', 'Заканчивается', 'Рабочая встреча'),
  WordEntry('Хат', 'Письмо', 'Пишем письмо'),
  WordEntry('Ебәрәм', 'Отправляю', 'Пишем письмо'),
  WordEntry('Адрес', 'Адрес', 'Пишем письмо'),
  WordEntry('Хәбәр', 'Сообщение', 'Пишем письмо'),
  WordEntry('Ҡултамға', 'Подпись', 'Пишем письмо'),
  WordEntry('Пароль', 'Пароль', 'Безопасность в интернете'),
  WordEntry('Мәғлүмәт', 'Информация', 'Безопасность в интернете'),
  WordEntry('Хәүефһеҙ', 'Безопасный', 'Безопасность в интернете'),
  WordEntry('Сер', 'Секрет', 'Безопасность в интернете'),
  WordEntry('Һаҡлыҡ', 'Осторожность', 'Безопасность в интернете'),
  WordEntry('Яңылыҡ', 'Новость', 'Читаем новости'),
  WordEntry('Сығанаҡ', 'Источник', 'Читаем новости'),
  WordEntry('Мәҡәлә', 'Статья', 'Читаем новости'),
  WordEntry('Хәбәрсе', 'Корреспондент', 'Читаем новости'),
  WordEntry('Ысын', 'Правдивый', 'Читаем новости'),
  WordEntry('Фекер', 'Мнение', 'Выражаем мнение'),
  WordEntry('Килешәм', 'Согласен', 'Выражаем мнение'),
  WordEntry('Килешмәйем', 'Не согласен', 'Выражаем мнение'),
  WordEntry('Иғтибар', 'Внимание', 'Выражаем мнение'),
  WordEntry('Мөһим', 'Важный', 'Выражаем мнение'),
  WordEntry('Дәрес', 'Урок', 'В классе'),
  WordEntry('Һорау', 'Вопрос', 'В классе'),
  WordEntry('Таҡта', 'Доска', 'В классе'),
  WordEntry('Баһа', 'Оценка', 'В классе'),
  WordEntry('Яуап бирәм', 'Отвечаю', 'В классе'),
  WordEntry('Имтихан', 'Экзамен', 'Подготовка к экзамену'),
  WordEntry('Студент', 'Студент', 'Подготовка к экзамену'),
  WordEntry('Университет', 'Университет', 'Подготовка к экзамену'),
  WordEntry('Әҙерләнәм', 'Готовлюсь', 'Подготовка к экзамену'),
  WordEntry('Билет алам', 'Беру билет', 'Подготовка к экзамену'),
  WordEntry('Ҡушыу', 'Сложение', 'Решаем задачи'),
  WordEntry('Алым', 'Приём', 'Решаем задачи'),
  WordEntry('Мәсьәлә', 'Задача', 'Решаем задачи'),
  WordEntry('Тигеҙ', 'Равно', 'Решаем задачи'),
  WordEntry('Һан', 'Число', 'Решаем задачи'),
  WordEntry('Фән', 'Наука', 'Научный опыт'),
  WordEntry('Тәжрибә', 'Эксперимент', 'Научный опыт'),
  WordEntry('Һөҙөмтә', 'Результат', 'Научный опыт'),
  WordEntry('Үлсәйем', 'Измеряю', 'Научный опыт'),
  WordEntry('Асыш', 'Открытие', 'Научный опыт'),
  WordEntry('Күнекмә', 'Навык', 'Спортивная тренировка'),
  WordEntry('Шөғөл', 'Занятие', 'Спортивная тренировка'),
  WordEntry('Ҡатнашам', 'Участвую', 'Спортивная тренировка'),
  WordEntry('Көслө', 'Сильный', 'Спортивная тренировка'),
  WordEntry('Һаулыҡ', 'Здоровье', 'Спортивная тренировка'),
  WordEntry('Команда', 'Команда', 'Командная игра'),
  WordEntry('Ҡапҡа', 'Ворота', 'Командная игра'),
  WordEntry('Һөжүм', 'Атака', 'Командная игра'),
  WordEntry('Һаҡсы', 'Защитник', 'Командная игра'),
  WordEntry('Етәкләй', 'Ведёт', 'Командная игра'),
  WordEntry('Киләсәк', 'Будущее', 'Планы на завтра'),
  WordEntry('Маҡсат', 'Цель', 'Планы на завтра'),
  WordEntry('Ниәт', 'Намерение', 'Планы на завтра'),
  WordEntry('План', 'План', 'Планы на завтра'),
  WordEntry('Башлайым', 'Начинаю', 'Планы на завтра'),
  WordEntry('Хыял', 'Мечта', 'Мечта о путешествии'),
  WordEntry('Сафары', 'Поездка', 'Мечта о путешествии'),
  WordEntry('Барырға', 'Поехать', 'Мечта о путешествии'),
  WordEntry('Теләк', 'Желание', 'Мечта о путешествии'),
  WordEntry('Ғорурлыҡ', 'Гордость', 'Мечта о путешествии'),
  WordEntry('Кисә', 'Вчера', 'Рассказываем о вчера'),
  WordEntry('Уҡыным', 'Я прочитал', 'Рассказываем о вчера'),
  WordEntry('Был', 'Был', 'Рассказываем о вчера'),
  WordEntry('Күрҙем', 'Я увидел', 'Рассказываем о вчера'),
  WordEntry('Һөйләнем', 'Я рассказал', 'Рассказываем о вчера'),
  WordEntry('Дауам итәм', 'Продолжаю', 'Путь продолжается'),
  WordEntry('Иркен', 'Свободно', 'Путь продолжается'),
  WordEntry('Ышаныс', 'Уверенность', 'Путь продолжается'),
  WordEntry('Һөйләшәм', 'Разговариваю', 'Путь продолжается'),
  WordEntry('Белем', 'Знание', 'Путь продолжается'),
];


List<String> _strings(dynamic data) =>
    data is List ? data.map((value) => value.toString()).toList() : <String>[];

Map<String, String> _translations(dynamic data) {
  if (data is! Map) return <String, String>{};
  return data.map((key, value) => MapEntry(key.toString(), value.toString()));
}

Exercise exerciseFromApi(Map<String, dynamic> item) {
  final correct = item['correct_answer']?.toString() ?? '';
  final prompt = item['prompt']?.toString() ?? '';
  final meanings = _translations(item['meaning_by_language']);
  if (item['type'] == 'arrange') {
    return Exercise.arrange(prompt: prompt, words: _strings(item['words']),
      correctAnswer: correct, note: item['note']?.toString() ?? '',
      meaningByLanguage: meanings);
  }
  return Exercise.choice(prompt: prompt, answers: _strings(item['answers']),
    correctAnswer: correct, note: item['note']?.toString() ?? '',
    meaningByLanguage: meanings);
}

Lesson lessonFromApi(Map<String, dynamic> item) => Lesson(
  title: item['title']?.toString() ?? '',
  subtitle: item['subtitle']?.toString() ?? '',
  icon: item['icon']?.toString() ?? '📚',
  titleTranslations: _translations(item['title_translations']),
  subtitleTranslations: _translations(item['subtitle_translations']),
  exercises: (item['exercises'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>().map(exerciseFromApi).toList(),
);

/// Single source of truth for web, iOS and Android; never cache answers in the bundle.
Future<void> refreshLessonCatalog(ApiClient api) async {
  final payload = await api.request('GET', '/course/lessons',
      timeout: const Duration(seconds: 30));
  final records = (payload['lessons'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>().toList();
  if (records.isEmpty) throw const ApiError('Сервер не вернул учебный курс');
  records.sort((a, b) => (a['index'] as num).compareTo(b['index'] as num));
  final incoming = records.map(lessonFromApi).toList();
  if (incoming.any((lesson) => lesson.exercises.isEmpty)) {
    throw const ApiError('Некорректный учебный курс на сервере');
  }
  lessons..clear()..addAll(incoming);
}
