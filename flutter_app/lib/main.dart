import 'package:flutter/material.dart';
import 'core/colors.dart';
import 'core/routes.dart';
import 'core/strings.dart';
import '../ui/login_screen.dart';
import '../ui/register_screen.dart';
import '../ui/welcome_screen.dart';

void main() {
  runApp(const LanguageSchoolApp());
}

class LanguageSchoolApp extends StatelessWidget {
  const LanguageSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Nunito',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          secondary: AppColors.accentGreen,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const WelcomeScreen(),
      routes: {
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
      },
    );
  }
}
