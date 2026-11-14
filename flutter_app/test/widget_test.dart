import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dualingo_bashkir/ui/main.dart';
import 'package:dualingo_bashkir/data/lessons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('The first screen asks users to sign in', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(find.text('Войти'), findsWidgets);
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Имя пользователя'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
  });

  testWidgets('Registration tab shows the create-account action', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Регистрация'));
    await tester.pumpAndSettle();
    expect(find.text('Создать аккаунт'), findsOneWidget);
  });

  test('Every exercise has content that can be pronounced', () {
    for (final lesson in lessons) {
      for (final question in lesson.exercises) {
        expect(question.spokenText.isNotEmpty, isTrue);
      }
    }
  });
}
