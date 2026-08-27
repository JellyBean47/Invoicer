import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_exception.dart';
import '../../../providers/app_providers.dart';
import '../../../shared/widgets/primary_button.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isChecking = false;
  bool _isResending = false;

  Future<void> _checkVerified() async {
    setState(() => _isChecking = true);
    try {
      final verified =
          await ref.read(authServiceProvider).refreshEmailVerification();
      if (!mounted) return;
      if (!verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Check your inbox.'),
          ),
        );
      }
      // Router redirect handles navigation once verified.
      ref.invalidate(authStateProvider);
      ref.invalidate(userProfileProvider);
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authServiceProvider).resendVerificationEmail();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent.')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          TextButton(
            onPressed: () => ref.read(authServiceProvider).signOut(),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.mark_email_unread_outlined, size: 64),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Confirm your email',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We sent a verification link to ${user?.email ?? 'your email'}. '
                'Open it, then tap the button below.',
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: "I've verified my email",
                isLoading: _isChecking,
                onPressed: _checkVerified,
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Resend verification email'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
