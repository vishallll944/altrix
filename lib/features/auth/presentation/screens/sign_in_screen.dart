import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/responsive.dart';
import '../../../../screens/main_shell.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_buttons.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../../widgets/exit_app_scope.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_handleEmailFocusChange);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_handleEmailFocusChange);
    _emailFocusNode.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    return email.isNotEmpty && email.contains('@') && email.contains('.');
  }

  void _enableInteractionValidation() {
    if (_autovalidateMode == AutovalidateMode.onUserInteraction) return;
    setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
  }

  void _handleEmailFocusChange() {
    if (_emailFocusNode.hasFocus) return;
    _enableInteractionValidation();
    _formKey.currentState?.validate();
  }

  void _handleEmailChanged(String value) {
    if (_isValidEmail(value)) {
      _enableInteractionValidation();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _enableInteractionValidation();
      return;
    }

    final success = await ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
      return;
    }

    _enableInteractionValidation();

    final error = ref.read(authProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;
    final responsive = context.responsive;

    return ExitAppScope(
      child: AuthLayout(
        child: AutofillGroup(
          child: Form(
            key: _formKey,
            autovalidateMode: _autovalidateMode,
            child: ListView(
              padding: responsive.authFormPadding,
              children: [
              Text(
                'Sign in',
                style: responsiveTextStyle(
                  context,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              SizedBox(height: responsive.rz(8)),
              Text(
                'Use the email your clinic has on file',
                style: responsiveTextStyle(
                  context,
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: responsive.rz(24)),
              AppTextField(
                label: 'Email',
                controller: _emailController,
                focusNode: _emailFocusNode,
                hint: 'patient@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                onChanged: _handleEmailChanged,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Enter your email';
                  if (!_isValidEmail(email)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: responsive.rz(16)),
              PasswordField(
                label: 'Password',
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _enableInteractionValidation(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: responsive.rz(24)),
              PrimaryButton(
                label: 'Sign in',
                loading: isLoading,
                onPressed: _submit,
              ),
              SizedBox(height: responsive.rz(20)),
              const ClinicFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
