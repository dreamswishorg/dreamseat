import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import 'auth_shell.dart';
import 'welcome_screen.dart';
import '../customer/customer_navigation.dart';
import '../merchant/merchant_dashboard.dart';
import '../admin/admin_dashboard.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitNewPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final error = await ref.read(appStateProvider.notifier).updatePassword(
          _passwordController.text,
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
      
      // Deliberate pause to let user see success, then route to their dashboard.
      Timer(const Duration(milliseconds: 1800), _navigateToDashboard);
    }
  }

  void _navigateToDashboard() {
    if (!mounted) return;

    final user = ref.read(appStateProvider).currentUser;
    final Widget destination;

    if (user == null) {
      destination = const WelcomeScreen();
    } else if (user.role == 'merchant') {
      destination = const MerchantDashboardScreen();
    } else if (user.role == 'admin' || user.role == 'super_admin') {
      destination = const AdminDashboardScreen();
    } else {
      destination = const CustomerNavigation();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destination),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AuthShell(
        eyebrow: 'Password security',
        eyebrowIcon: Icons.shield_outlined,
        headline: 'Set your new',
        subhead: 'secure password.',
        description:
            'Create a strong password to safeguard your account, saved payment methods, and favorite rescued meals.',
        showHeadlineOnCompact: false,
        child: AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.slow,
          child: _isSuccess ? _buildSuccessContent() : _buildFormContent(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM & SUCCESS CONTENT
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
            icon: Icons.vpn_key_rounded,
            title: 'Reset Password',
            subtitle: 'Create a strong, new password for your account to secure it.',
          ),
          const SizedBox(height: AppSpace.x3),
          DsTextField(
            controller: _passwordController,
            label: 'New Password',
            hint: 'Min. 6 characters',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            suffix: DsObscureToggle(
              obscured: _obscurePassword,
              onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) =>
                (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
          const SizedBox(height: AppSpace.lg),
          DsTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hint: 'Re-enter your password',
            icon: Icons.lock_reset_rounded,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) {
              if (!_isLoading) _submitNewPassword();
            },
            suffix: DsObscureToggle(
              obscured: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordController.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: AppSpace.xxl),
          DsButton(
            label: 'Save & Continue',
            loading: _isLoading,
            onPressed: _isLoading ? null : _submitNewPassword,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent() {
    return const Column(
      key: ValueKey('success_content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthStatusHeader(
          icon: Icons.check_circle_outline_rounded,
          title: 'Password Updated',
          subtitle: 'Your password has been successfully updated.',
        ),
        SizedBox(height: AppSpace.xxl),
        Center(
          child: Column(
            children: [
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
              SizedBox(height: AppSpace.lg),
              Text(
                'Redirecting to your dashboard...',
                style: TextStyle(color: AppTheme.mutedGrey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
