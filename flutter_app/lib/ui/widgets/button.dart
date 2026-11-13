import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/dimens.dart';
import '../../core/text_styles.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? AppDimens.buttonPaddingDefault;

    final shape = RoundedRectangleBorder(
      borderRadius: AppDimens.buttonBorderRadius,
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: AppStyles.buttonText,
        ),
        if (icon != null) ...[
          const SizedBox(width: AppDimens.space10),
          Icon(icon, size: AppDimens.iconSizeSmall),
        ],
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          padding: effectivePadding,
          side: const BorderSide(
            color: AppColors.primaryBlue,
            width: AppDimens.borderThin,
          ),
          shape: shape,
        ),
        child: content,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.pureWhite,
        padding: effectivePadding,
        shape: shape,
        elevation: 0,
      ),
      child: content,
    );
  }
}
