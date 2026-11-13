import 'package:flutter/material.dart';

class AppDimens {
  // Брейкпоинты и ограничения
  static const double mobileBreakpoint = 750.0;
  static const double desktopMaxWidth = 1250.0;

  // Базовые отступы (Spaces)
  static const double space4 = 4.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space18 = 18.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space25 = 25.0;
  static const double space28 = 28.0;
  static const double space30 = 30.0;
  static const double space35 = 35.0;
  static const double space40 = 40.0;
  static const double space50 = 50.0;
  static const double space60 = 60.0;
  static const double space75 = 75.0;

  // Готовые внутренние отступы (Paddings)
  static const EdgeInsets buttonPaddingDefault = EdgeInsets.symmetric(
    horizontal: space28,
    vertical: space18,
  );
  static const EdgeInsets buttonPaddingSmall = EdgeInsets.symmetric(
    horizontal: space24,
    vertical: space14,
  );
  static const EdgeInsets headerPaddingMobile = EdgeInsets.symmetric(
    horizontal: space20,
    vertical: space20,
  );
  static const EdgeInsets headerPaddingDesktop = EdgeInsets.symmetric(
    horizontal: space60,
    vertical: space20,
  );
  static const EdgeInsets contentPaddingDesktop = EdgeInsets.symmetric(
    horizontal: space40,
    vertical: space75,
  );
  static const EdgeInsets contentPaddingMobile = EdgeInsets.symmetric(
    horizontal: space24,
    vertical: space35,
  );
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: 9.0,
  );
  static const EdgeInsets captionBadgePadding = EdgeInsets.symmetric(
    horizontal: space14,
    vertical: space4,
  );

  // Радиусы скругления (Rounds)
  static const double radius14 = 14.0;
  static const double radius30 = 30.0;
  static const double radius35 = 35.0;
  static const double radius40 = 40.0;

  static final BorderRadius buttonBorderRadius = BorderRadius.circular(radius14);
  static final BorderRadius badgeBorderRadius = BorderRadius.circular(radius30);
  static final BorderRadius cardBorderRadius = BorderRadius.circular(radius35);
  static final BorderRadius iconBoxBorderRadius = BorderRadius.circular(radius40);

  // Размеры элементов и иконок
  static const double iconSizeSmall = 18.0;
  static const double iconSizeMedium = 20.0;
  static const double iconSizeLogo = 32.0;
  static const double iconSizeHero = 85.0;

  static const double illustrationHeight = 390.0;
  static const double iconBoxSize = 155.0;
  static const double decorCircleSmall = 75.0;
  static const double decorCircleLarge = 100.0;

  // Толщина рамок
  static const double borderThin = 1.5;
  static const double borderThick = 3.0;

  // Размеры форм
  static const double authCardMaxWidth = 460.0;
  static const double space8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius24 = 24.0;
  static const double blur24 = 24.0;
  static const double offset8 = 8.0;
  static const int minPasswordLength = 6;

  static final BorderRadius inputBorderRadius = BorderRadius.circular(radius12);
  static final BorderRadius authCardBorderRadius = BorderRadius.circular(radius24);

  static const EdgeInsets padding20 = EdgeInsets.all(space20);
  static const EdgeInsets padding14 = EdgeInsets.all(space14);
  static const EdgeInsets authCardPadding = EdgeInsets.all(space35);
  static const EdgeInsets inputContentPadding = EdgeInsets.symmetric(
    horizontal: space16,
    vertical: space16,
  );
}
