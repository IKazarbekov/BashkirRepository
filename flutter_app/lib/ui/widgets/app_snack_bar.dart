import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/dimens.dart';
import '../../core/text_styles.dart';

class AppSnackBar {
  static void showSuccess(
      BuildContext context, {
        required String title,
        String? message,
      }) {
    _show(
      context,
      title: title,
      message: message,
      backgroundColor: AppColors.accentGreen,
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(
      BuildContext context, {
        required String message,
      }) {
    _show(
      context,
      title: message,
      backgroundColor: Colors.redAccent,
      icon: Icons.error_outline_rounded,
    );
  }

  static void _show(
      BuildContext context, {
        required String title,
        String? message,
        required Color backgroundColor,
        required IconData icon,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: AppDimens.buttonBorderRadius,
          ),
          margin: AppDimens.headerPaddingMobile,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(
                icon,
                color: AppColors.pureWhite,
                size: AppDimens.iconSizeLogo,
              ),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppStyles.buttonText.copyWith(
                        color: AppColors.pureWhite,
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppDimens.space4),
                      Text(
                        message,
                        style: AppStyles.illustrationSubtitle,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
