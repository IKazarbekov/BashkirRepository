import 'package:flutter/material.dart';
import '../core/colors.dart';
import '../core/dimens.dart';
import '../core/routes.dart';
import '../core/strings.dart';
import '../core/text_styles.dart';
import '../services/auth_service.dart';
import 'widgets/app_button.dart';
import 'widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.login(
      login: _loginController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.loginSuccess),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.redAccent,
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
                      label: AppStrings.loginLabel,
                      hint: AppStrings.loginHint,
                      prefixIcon: Icons.person_outline_rounded,
                      controller: _loginController,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppStrings.errorEmptyField;
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
                        if (value == null || value.isEmpty) {
                          return AppStrings.errorEmptyField;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppDimens.space28),
                    _isLoading
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    )
                        : AppButton(
                      text: AppStrings.login,
                      onPressed: _submitLogin,
                    ),
                    const SizedBox(height: AppDimens.space20),
                    _buildRegisterLink(),
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
            Icons.login_rounded,
            color: AppColors.primaryBlue,
            size: AppDimens.iconSizeLogo,
          ),
        ),
        const SizedBox(height: AppDimens.space16),
        Text(
          AppStrings.authTitle,
          style: AppStyles.illustrationTitle.copyWith(
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          AppStrings.noAccount,
          style: AppStyles.captionMuted,
        ),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacementNamed(context, AppRoutes.register);
          },
          child: const Text(
            AppStrings.register,
            style: AppStyles.badgeText,
          ),
        ),
      ],
    );
  }
}
