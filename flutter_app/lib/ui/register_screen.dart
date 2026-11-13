import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/dimens.dart';
import '../core/routes.dart';
import '../core/strings.dart';
import '../core/text_styles.dart';
import 'widgets/app_button.dart';
import 'widgets/app_text_field.dart';

// ... остальной код RegisterScreen без изменений ...

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.welcomeUserPrefix}${_nameController.text}!',
          ),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppDimens.headerPaddingMobile,
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: AppDimens.mobileBreakpoint,
              ),
              padding: AppDimens.contentPaddingMobile,
              decoration: BoxDecoration(
                color: AppColors.pureWhite,
                borderRadius: AppDimens.cardBorderRadius,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppDimens.space30),
                    AppTextField(
                      label: AppStrings.nameLabel,
                      hint: AppStrings.nameHint,
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _nameController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.errorEmptyField;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),
                    AppTextField(
                      label: AppStrings.emailLabel,
                      hint: AppStrings.emailHint,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.errorEmptyField;
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return AppStrings.errorInvalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),
                    AppTextField(
                      label: AppStrings.passwordLabel,
                      hint: AppStrings.passwordHint,
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value == null || value.length < 6) {
                          return AppStrings.errorShortPassword;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space16),
                    AppTextField(
                      label: AppStrings.confirmPasswordLabel,
                      hint: AppStrings.confirmPasswordHint,
                      prefixIcon: Icons.lock_reset_rounded,
                      isPassword: true,
                      controller: _confirmPasswordController,
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return AppStrings.errorPasswordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space28),
                    AppButton(
                      text: AppStrings.createAccountButton,
                      onPressed: _submitForm,
                    ),
                    const SizedBox(height: AppDimens.space20),
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: AppDimens.badgePadding,
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.school_rounded,
            color: AppColors.primaryBlue,
            size: AppDimens.iconSizeLogo,
          ),
        ),
        const SizedBox(height: AppDimens.space16),
        Text(
          AppStrings.registerTitle,
          style: AppStyles.illustrationTitle.copyWith(
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimens.space10),
        const Text(
          AppStrings.registerSubtitle,
          style: AppStyles.captionMuted,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          AppStrings.alreadyHaveAccount,
          style: AppStyles.captionMuted,
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          },
          child: const Text(
            AppStrings.login,
            style: AppStyles.badgeText,
          ),
        ),
      ],
    );
  }
}
