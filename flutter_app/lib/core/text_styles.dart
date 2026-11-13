import 'package:flutter/material.dart';
import 'colors.dart';

class AppStyles {
  // Понятные словесные константы для начертаний шрифта
  static const FontWeight regular = FontWeight.normal;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.bold;
  static const FontWeight extraBold = FontWeight.w800;

  // ExtraBold — самые крупные акценты
  static const TextStyle heroTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 42,
    height: 1.2,
    fontWeight: extraBold,
  );

  static const TextStyle authTitle = TextStyle(
    color: AppColors.textDark,
    fontSize: 28,
    fontWeight: extraBold,
  );

  // Bold — заголовки карточек, логотип, кнопки
  static const TextStyle brandTitle = TextStyle(
    fontSize: 20,
    fontWeight: bold,
    color: AppColors.textDark,
  );

  static const TextStyle illustrationTitle = TextStyle(
    color: AppColors.pureWhite,
    fontSize: 27,
    fontWeight: bold,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 15,
    fontWeight: bold,
  );

  static const TextStyle badgeText = TextStyle(
    color: AppColors.primaryBlue,
    fontSize: 12,
    fontWeight: bold,
    letterSpacing: 1,
  );

  // SemiBold — подзаголовки, ссылки, подписи полей
  static const TextStyle heroSubtitle = TextStyle(
    color: AppColors.accentGreen,
    fontSize: 23,
    fontWeight: semiBold,
  );

  static const TextStyle navLink = TextStyle(
    color: AppColors.textDark,
    fontSize: 15,
    fontWeight: semiBold,
  );

  static const TextStyle inputLabel = TextStyle(
    color: AppColors.textDark,
    fontSize: 14,
    fontWeight: semiBold,
  );

  static const TextStyle illustrationSubtitle = TextStyle(
    color: AppColors.pureWhite,
    fontSize: 14,
    fontWeight: semiBold,
  );

  // Regular — основной текст и описания
  static const TextStyle bodyDescription = TextStyle(
    color: AppColors.textMuted,
    fontSize: 17,
    height: 1.7,
    fontWeight: regular,
  );

  static const TextStyle authSubtitle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 15,
    height: 1.5,
    fontWeight: regular,
  );

  static const TextStyle captionMuted = TextStyle(
    color: AppColors.textMuted,
    fontSize: 14,
    fontWeight: regular,
  );

  static const TextStyle placeholderText = TextStyle(
    fontSize: 22,
    color: AppColors.textDark,
    fontWeight: regular,
  );

  // Градиенты
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      AppColors.primaryBlue,
      Color(0xFF00559B),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
