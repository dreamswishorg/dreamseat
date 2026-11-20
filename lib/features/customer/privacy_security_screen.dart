import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/ds_kit.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../core/ui_utils.dart';
import '../../providers/app_state.dart';
import '../../providers/biometric_provider.dart';
import '../common/legal_screens.dart';
import '../../widgets/biometric_switch_tile.dart';
import '../auth/welcome_screen.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSavingPassword = false;

  String _locationStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!mounted) return;
    setState(() {
      if (!serviceEnabled) {
        _locationStatus = 'GPS Turned Off';
      } else if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        _locationStatus = 'Allowed';
      } else if (permission == LocationPermission.deniedForever) {
        _locationStatus = 'Denied Permanently';
      } else {
        _locationStatus = 'Not Granted';
      }
    });
  }

  Future<void> _handleLocationPermissionTap() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showAdaptiveDialog(
        context: context,
        builder: (ctx) => AlertDialog.adaptive(
          title: const Text("Location Permission"),
          content: const Text("Location access is currently disabled. Please enable location permissions in Settings to find meals nearby."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              child: const Text("Open Settings", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      showAdaptiveDialog(
        context: context,
        builder: (ctx) => AlertDialog.adaptive(
          title: const Text("GPS / Location Services"),
          content: const Text("Location Services are turned off on your device. Please turn on Location in Settings."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openLocationSettings();
              },
              child: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    _checkLocationPermission();
  }

  Future<void> _changePassword() async {
    final currentPw = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

    if (currentPw.isEmpty) {
      _showSnackBar('Please enter your current password', isError: true);
      return;
    }
    if (newPw.isEmpty) {
      _showSnackBar('Please enter a new password', isError: true);
      return;
    }
    if (newPw.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }
    if (newPw != confirmPw) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    setState(() => _isSavingPassword = true);

    // Prove it's really the account owner before changing anything.
    final user = ref.read(appStateProvider).currentUser;
    if (user != null) {
      final wrong = await ref.read(appStateProvider.notifier).validateCurrentPassword(
            email: user.email,
            password: currentPw,
          );
      if (wrong != null) {
        if (mounted) setState(() => _isSavingPassword = false);
        _showSnackBar('Your current password is incorrect', isError: true);
        return;
      }
    }

    final error = await ref.read(appStateProvider.notifier).updatePassword(newPw);
    if (mounted) setState(() => _isSavingPassword = false);

    if (!mounted) return;
    if (error != null) {
      _showSnackBar(error, isError: true);
    } else {
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _currentPasswordController.clear();
      _showSnackBar('Password updated successfully!');
    }
  }

  void _showSnackBar(String text, {bool isError = false}) {
    if (isError) {
      AppToast.error(context, text);
    } else {
      AppToast.success(context, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationOk = _locationStatus == 'Allowed';
    final showBiometrics = ref.watch(biometricStateProvider.select((b) => b.isSupported || !b.isInitialized));
    const sectionPad = EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.xxl, AppSpace.xs, AppSpace.md);

    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: dsScreenBar(context, title: 'Privacy & Security'),
      body: ResponsiveCenter(
        maxWidth: 720,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.x4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Device permissions ──────────────────────────────────────
              const DsSectionHeader(title: 'Device Permissions', padding: EdgeInsets.fromLTRB(AppSpace.xs, AppSpace.md, AppSpace.xs, AppSpace.md)),
              DsMenuGroup(
                margin: EdgeInsets.zero,
                children: [
                  DsMenuTile(
                    icon: Icons.location_on_rounded,
                    tone: locationOk ? DsTone.brand : DsTone.warn,
                    label: 'GPS & Location Access',
                    subtitle: 'Status: $_locationStatus',
                    onTap: _handleLocationPermissionTap,
                    trailing: DsPill(
                      label: locationOk ? 'Verify' : 'Enable',
                      tone: locationOk ? DsTone.neutral : DsTone.brand,
                      solid: !locationOk,
                      compact: true,
                    ),
                  ),
                ],
              ),

              // ── Biometrics ──────────────────────────────────────────────
              if (showBiometrics) ...[
                const DsSectionHeader(title: 'Biometrics Security', padding: sectionPad),
                const DsMenuGroup(
                  margin: EdgeInsets.zero,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
                      child: BiometricSwitchTile(),
                    ),
                  ],
                ),
              ],

              // ── Password ────────────────────────────────────────────────
              const DsSectionHeader(title: 'Password Security', padding: sectionPad),
              DsCard(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _passwordField(
                      controller: _currentPasswordController,
                      label: 'Current Password',
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    _passwordField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    _passwordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: AppSpace.xl),
                    DsButton(
                      label: 'Update password',
                      icon: Icons.lock_reset_rounded,
                      variant: DsButtonVariant.dark,
                      loading: _isSavingPassword,
                      onPressed: _isSavingPassword ? null : _changePassword,
                    ),
                  ],
                ),
              ),

              // ── Data protection & legal ────────────────────────────────
              const DsSectionHeader(title: 'Data Protection & Legal', padding: sectionPad),
              DsMenuGroup(
                margin: EdgeInsets.zero,
                children: [
                  DsMenuTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    subtitle: 'Read how we protect and manage your data',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                  ),
                  DsMenuTile(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    subtitle: 'Understand your rights and user agreement',
                    tone: DsTone.info,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                  ),
                  DsMenuTile(
                    icon: Icons.delete_forever_outlined,
                    label: 'Delete Account',
                    subtitle: 'Permanently delete your profile and account data',
                    tone: DsTone.danger,
                    onTap: _showDeleteAccountConfirmation,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isDeleting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
                SizedBox(width: AppSpace.md),
                Expanded(child: Text("Delete Account")),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "WARNING: This action is permanent. All your profile data, orders history, reward points, and credits will be permanently deleted and cannot be recovered.",
                    style: TextStyle(fontSize: 14, height: 1.45, color: AppTheme.charcoal, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  DsTextField(
                    controller: passwordCtrl,
                    label: "Enter your password to confirm",
                    hint: "••••••••",
                    icon: Icons.lock_outline_rounded,
                    obscureText: true,
                    validator: (v) => (v == null || v.isEmpty) ? "Password is required" : null,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey)),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final user = ref.read(appStateProvider).currentUser;
                        if (user == null) return;

                        setModalState(() => isDeleting = true);
                        
                        // 1. Verify password
                        final error = await ref.read(appStateProvider.notifier).validateCurrentPassword(
                          email: user.email,
                          password: passwordCtrl.text,
                        );

                        if (!context.mounted || !ctx.mounted) return;

                        if (error != null) {
                          setModalState(() => isDeleting = false);
                          AppToast.error(context, "Incorrect password: $error");
                          return;
                        }

                        // 2. Execute deletion
                        final success = await ref.read(appStateProvider.notifier).deleteAccount();
                        
                        if (!context.mounted || !ctx.mounted) return;
                        setModalState(() => isDeleting = false);

                        if (success) {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                            (route) => false,
                          );
                          AppToast.success(context, "Your account has been deleted successfully.");
                        } else {
                          AppToast.error(context, "Failed to delete account. Please try again later.");
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: AppTheme.pureWhite,
                ),
                child: isDeleting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppTheme.pureWhite, strokeWidth: 2))
                    : const Text("Delete Permanently"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return DsTextField(
      controller: controller,
      label: label,
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
      obscureText: obscure,
      suffix: DsObscureToggle(obscured: obscure, onToggle: onToggle),
    );
  }
}
