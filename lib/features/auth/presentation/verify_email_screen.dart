import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/mr_button.dart';
import '../../../core/widgets/mr_card.dart';
import '../../../core/widgets/mr_text_field.dart';
import 'auth_controller.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({required this.email, super.key});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _resent = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _currentEmail();
    if (email.isEmpty) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .verifyEmail(email, _codeController.text.trim());
    if (success && mounted) context.go('/home');
  }

  Future<void> _resend() async {
    final email = _currentEmail();
    if (email.isEmpty) return;
    final success = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationCode(email);
    if (success && mounted) {
      setState(() => _resent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A new verification code was sent.')),
      );
    }
  }

  String _currentEmail() {
    if (widget.email.isNotEmpty) return widget.email;
    return ref.read(authControllerProvider).pendingVerificationEmail ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final theme = Theme.of(context);
    final email = widget.email.isNotEmpty
        ? widget.email
        : auth.pendingVerificationEmail ?? '';

    return Scaffold(
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_rounded,
                      color: AppColors.emerald,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Verify Email',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  email.isEmpty
                      ? 'Enter the 6-digit code sent to your email.'
                      : 'Enter the 6-digit code sent to $email.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                MRCard(
                  child: Column(
                    children: [
                      MRTextField(
                        label: 'Verification Code',
                        hint: '123456',
                        controller: _codeController,
                        icon: Icons.pin_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        validator: (value) {
                          final code = value?.trim() ?? '';
                          if (code.length != 6) {
                            return 'Enter the 6-digit code';
                          }
                          return null;
                        },
                      ),
                      if (_resent) ...[
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('Use the newest code in your inbox.'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    auth.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                MRButton(
                  label: 'Verify and Continue',
                  icon: Icons.verified_rounded,
                  isLoading: auth.isLoading,
                  onPressed: email.isEmpty ? null : _verify,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: auth.isLoading || email.isEmpty ? null : _resend,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Send a new code'),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
