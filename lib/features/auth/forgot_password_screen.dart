import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import 'auth_shell.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final error = await ref.read(appStateProvider.notifier).resetPassword(
          _emailController.text.trim(),
        );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.replaceAll('AuthException: ', '').trim()),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    } else {
      setState(() {
        _isSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      onBack: () => Navigator.of(context).pop(),
      backLabel: 'Back to Sign In',
      eyebrow: 'Account recovery',
      eyebrowIcon: Icons.shield_outlined,
      headline: 'Reset your password',
      subhead: 'swiftly and securely.',
      description:
          'Get back to saving money and rescuing fresh surplus food from your favorite spots. Enter your email and we\'ll send a direct reset link.',
      showHeadlineOnCompact: false,
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.slow,
        child: _isSuccess ? _buildSuccessContent() : _buildFormContent(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM & SUCCESS STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildFormContent() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form_content'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthStatusHeader(
            icon: Icons.lock_reset_rounded,
            title: 'Forgot Password?',
            subtitle:
                'Enter the email address associated with your account and we\'ll send you instructions to reset your password.',
          ),
          const SizedBox(height: AppSpace.x3),
          DsTextField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'you@example.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) {
              if (!_isLoading) _sendResetLink();
            },
            validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
                ? 'Enter a valid email address'
                : null,
          ),
          const SizedBox(height: AppSpace.xl),
          DsButton(
            label: 'Send Reset Link',
            loading: _isLoading,
            onPressed: _isLoading ? null : _sendResetLink,
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      key: const ValueKey('success_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthStatusHeader(
          icon: Icons.mark_email_read_rounded,
          title: 'Check Your Email',
          subtitle: 'We have sent password reset instructions to:\n${_emailController.text.trim()}',
        ),
        const SizedBox(height: AppSpace.lg),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
          decoration: BoxDecoration(
            color: AppTheme.lightGreenBg,
            borderRadius: AppRadius.rMd,
            border: Border.all(color: AppTheme.mintGreen),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.primaryGreen, size: 20),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: Text(
                  'Please check your inbox (and spam folder) for the link to set a new password.',
                  style: TextStyle(color: AppTheme.deepGreen, fontSize: 13, height: 1.4, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        DsButton(label: 'Back to Sign In', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
