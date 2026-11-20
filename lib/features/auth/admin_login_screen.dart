import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../admin/admin_dashboard.dart';
import 'auth_shell.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscure = true;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await ref.read(appStateProvider.notifier).signIn(
      identifier: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      AppToast.error(context, "Access Denied: $error");
      return;
    }

    final role = ref.read(appStateProvider).currentUser?.role;
    if (role != 'admin' && role != 'super_admin') {
      await ref.read(appStateProvider.notifier).signOut();
      if (!mounted) return;
      AppToast.error(context, "Unauthorized: Admin Access Required");
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Staff only',
      eyebrowIcon: Icons.admin_panel_settings_outlined,
      headline: 'DreamEats Management',
      description: 'Centralized administration portal for Ghana operations.',
      showHeadlineOnCompact: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text('Admin Portal', style: Theme.of(context).textTheme.headlineLarge),
            ),
            const SizedBox(height: AppSpace.xs),
            Text('Sign in to manage DreamEats', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpace.xxl),
            DsTextField(
              controller: _emailCtrl,
              label: 'Email Address',
              hint: 'e.g. admin@dreameats.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpace.lg),
            DsTextField(
              controller: _passCtrl,
              label: 'Security Key',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_isLoading) _handleLogin();
              },
              suffix: DsObscureToggle(obscured: _obscure, onToggle: () => setState(() => _obscure = !_obscure)),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: AppSpace.xxl),
            DsButton(
              label: 'Authorize & Enter',
              variant: DsButtonVariant.dark,
              loading: _isLoading,
              onPressed: _isLoading ? null : _handleLogin,
            ),
          ],
        ),
      ),
    );
  }
}
