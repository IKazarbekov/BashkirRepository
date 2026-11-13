import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/dimens.dart';
import '../core/routes.dart';
import '../core/strings.dart';
import '../core/text_styles.dart';
import 'widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _navigateTo(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < AppDimens.mobileBreakpoint;

            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(context, isMobile),
                  isMobile
                      ? _buildMobileContent(context)
                      : _buildDesktopContent(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Верхняя панель
  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Padding(
      padding: isMobile
          ? AppDimens.headerPaddingMobile
          : AppDimens.headerPaddingDesktop,
      child: Row(
        children: [
          const Icon(
            Icons.school_rounded,
            color: AppColors.primaryBlue,
            size: AppDimens.iconSizeLogo,
          ),
          const SizedBox(width: AppDimens.space12),
          const Text(
            AppStrings.brandName,
            style: AppStyles.brandTitle,
          ),
          const Spacer(),
          if (!isMobile) ...[
            TextButton(
              onPressed: () => _navigateTo(context, AppRoutes.login),
              child: const Text(
                AppStrings.login,
                style: AppStyles.navLink,
              ),
            ),
            const SizedBox(width: AppDimens.space12),
            AppButton(
              text: AppStrings.register,
              onPressed: () => _navigateTo(context, AppRoutes.register),
              padding: AppDimens.buttonPaddingSmall,
            ),
          ],
        ],
      ),
    );
  }

  // Контент для компьютера
  Widget _buildDesktopContent(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AppDimens.desktopMaxWidth),
      padding: AppDimens.contentPaddingDesktop,
      child: Row(
        children: [
          Expanded(flex: 6, child: _buildWelcomeText(context)),
          const SizedBox(width: AppDimens.space50),
          Expanded(flex: 5, child: _buildIllustration()),
        ],
      ),
    );
  }

  // Контент для телефона
  Widget _buildMobileContent(BuildContext context) {
    return Padding(
      padding: AppDimens.contentPaddingMobile,
      child: Column(
        children: [
          _buildIllustration(),
          const SizedBox(height: AppDimens.space40),
          _buildWelcomeText(context),
        ],
      ),
    );
  }

  // Приветственный текст
  Widget _buildWelcomeText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: AppDimens.badgePadding,
          decoration: BoxDecoration(
            color: AppColors.softBlue,
            borderRadius: AppDimens.badgeBorderRadius,
          ),
          child: const Text(
            AppStrings.badgeText,
            style: AppStyles.badgeText,
          ),
        ),
        const SizedBox(height: AppDimens.space25),
        const Text(
          AppStrings.welcomeTitle,
          style: AppStyles.heroTitle,
        ),
        const SizedBox(height: AppDimens.space20),
        const Text(
          AppStrings.welcomeSubtitle,
          style: AppStyles.heroSubtitle,
        ),
        const SizedBox(height: AppDimens.space20),
        const Text(
          AppStrings.welcomeDescription,
          style: AppStyles.bodyDescription,
        ),
        const SizedBox(height: AppDimens.space35),
        Wrap(
          spacing: AppDimens.space14,
          runSpacing: AppDimens.space14,
          children: [
            AppButton(
              text: AppStrings.startLearning,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _navigateTo(context, AppRoutes.register),
            ),
            AppButton(
              text: AppStrings.haveAccount,
              isOutlined: true,
              onPressed: () => _navigateTo(context, AppRoutes.login),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space35),
        const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.accentGreen,
              size: AppDimens.iconSizeMedium,
            ),
            SizedBox(width: AppDimens.space10),
            Expanded(
              child: Text(
                AppStrings.featurePace,
                style: AppStyles.captionMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Иллюстрация в стиле флага
  Widget _buildIllustration() {
    return Container(
      height: AppDimens.illustrationHeight,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppStyles.primaryGradient,
        borderRadius: AppDimens.cardBorderRadius,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: AppDimens.space25,
            right: AppDimens.space35,
            child: _decorationCircle(AppDimens.decorCircleSmall),
          ),
          Positioned(
            bottom: AppDimens.space30,
            left: AppDimens.space25,
            child: _decorationCircle(AppDimens.decorCircleLarge),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: AppDimens.iconBoxSize,
                height: AppDimens.iconBoxSize,
                decoration: BoxDecoration(
                  color: AppColors.pureWhite,
                  borderRadius: AppDimens.iconBoxBorderRadius,
                  border: Border.all(
                    color: AppColors.kuraiGold,
                    width: AppDimens.borderThick,
                  ),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primaryBlue,
                  size: AppDimens.iconSizeHero,
                ),
              ),
              const SizedBox(height: AppDimens.space30),
              const Text(
                AppStrings.illustrationTitle,
                style: AppStyles.illustrationTitle,
              ),
              const SizedBox(height: AppDimens.space10),
              Container(
                padding: AppDimens.captionBadgePadding,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  borderRadius: AppDimens.badgeBorderRadius,
                ),
                child: const Text(
                  AppStrings.illustrationSubtitle,
                  style: AppStyles.illustrationSubtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decorationCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
    );
  }
}
