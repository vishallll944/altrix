import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../widgets/app_buttons.dart';
import '../../../../widgets/app_text_field.dart';
import '../../../patient/presentation/providers/patient_providers.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_layout.dart';
import 'sign_in_screen.dart';

class InviteAcceptScreen extends ConsumerStatefulWidget {
  const InviteAcceptScreen({
    super.key,
    required this.inviteToken,
  });

  final String inviteToken;

  @override
  ConsumerState<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends ConsumerState<InviteAcceptScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).acceptInvite(
          token: widget.inviteToken,
          password: _passwordController.text,
        );
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password set. Sign in with your email.'),
        ),
      );
      return;
    }

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
    final previewAsync = ref.watch(invitePreviewProvider(widget.inviteToken));

    return AuthLayout(
      compactHeader: true,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          children: [
            const Text(
              'Set your password',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            previewAsync.when(
              loading: () => const Text(
                'Checking your invite link...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              error: (_, _) => const Text(
                'This invite link could not be verified. You can still try setting a password.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              data: (preview) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preview.valid
                          ? 'Create a password to finish setting up your account.'
                          : preview.message.isNotEmpty
                              ? preview.message
                              : 'This invite link is not valid.',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (preview.email.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        preview.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                    if (preview.clinicName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview.clinicName,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            PasswordField(
              label: 'Password',
              controller: _passwordController,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter a password';
                }
                if (value.length < 8 || value.length > 72) {
                  return 'Password must be 8-72 characters';
                }
                if (value.contains(' ')) {
                  return 'Password cannot contain spaces';
                }
                if (!RegExp(r'[A-Za-z]').hasMatch(value) ||
                    !RegExp(r'[0-9]').hasMatch(value)) {
                  return 'Use at least 1 letter and 1 number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            PasswordField(
              label: 'Confirm password',
              controller: _confirmController,
              textInputAction: TextInputAction.done,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Save password',
              loading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                );
              },
              child: const Text(
                'Back to sign in',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const ClinicFooter(),
          ],
        ),
      ),
    );
  }
}
