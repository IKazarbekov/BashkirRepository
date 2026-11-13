import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/dimens.dart';
import '../../core/text_styles.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppStyles.navLink,
        ),
        const SizedBox(height: AppDimens.space10),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppStyles.captionMuted,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: AppDimens.badgePadding,
            prefixIcon: Icon(
              widget.prefixIcon,
              color: AppColors.primaryBlue,
              size: AppDimens.iconSizeMedium,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
              icon: Icon(
                _obscureText
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: AppColors.textMuted,
                size: AppDimens.iconSizeMedium,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: AppDimens.buttonBorderRadius,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppDimens.buttonBorderRadius,
              borderSide: const BorderSide(color: AppColors.softBlue),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppDimens.buttonBorderRadius,
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: AppDimens.borderThin,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppDimens.buttonBorderRadius,
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}