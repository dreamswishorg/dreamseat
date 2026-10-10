import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/theme.dart';
import '../../core/responsive.dart';
import '../../providers/app_state.dart';
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
    final newPw = _newPasswordController.text;
    final confirmPw = _confirmPasswordController.text;

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
    final error = await ref.read(appStateProvider.notifier).updatePassword(newPw);
    setState(() => _isSavingPassword = false);

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: isError ? AppTheme.errorRed : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.charcoal, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy & Security',
          style: TextStyle(color: AppTheme.charcoal, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.4),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ResponsiveCenter(
            maxWidth: 760,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // ── Section: Device Permissions ─────────────────────────
              const Text(
                "Device Permissions",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _locationStatus == 'Allowed' ? AppTheme.lightGreenBg : AppTheme.warningOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _locationStatus == 'Allowed' ? AppTheme.primaryGreen : AppTheme.warningOrange,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("GPS & Location Access", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.charcoal)),
                          const SizedBox(height: 4),
                          Text(
                            "Status: $_locationStatus",
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _locationStatus == 'Allowed' ? AppTheme.primaryGreen : AppTheme.mutedGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _handleLocationPermissionTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _locationStatus == 'Allowed' ? const Color(0xFFF1F5F9) : AppTheme.primaryGreen,
                        foregroundColor: _locationStatus == 'Allowed' ? AppTheme.charcoal : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(_locationStatus == 'Allowed' ? "Verify" : "Enable", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section: Biometrics Security ────────────────────────
              const Text(
                "Biometrics Security",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: const BiometricSwitchTile(),
              ),
              const SizedBox(height: 28),

              // ── Section: Account Password Security ──────────────────
              const Text(
                "Password Security",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildPasswordField(
                      controller: _currentPasswordController,
                      label: 'Current Password',
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    Divider(height: 28, color: AppTheme.charcoal.withValues(alpha: 0.06)),
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'New Password',
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    Divider(height: 28, color: AppTheme.charcoal.withValues(alpha: 0.06)),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirm New Password',
                      obscure: _obscureConfirm,
                      onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _isSavingPassword ? null : _changePassword,
                        icon: _isSavingPassword
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Icon(Icons.lock_reset_rounded, size: 20),
                        label: Text(
                          _isSavingPassword ? "UPDATING PASSWORD..." : "UPDATE PASSWORD",
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section: Data Protection & Legal ──────────────────
              const Text(
                "Data Protection & Legal",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.charcoal, letterSpacing: -0.3),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.charcoal.withValues(alpha: 0.06)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildLegalTile(
                      icon: Icons.privacy_tip_outlined,
                      title: "Privacy Policy",
                      subtitle: "Read how we protect and manage your data",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    ),
                    Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.06)),
                    _buildLegalTile(
                      icon: Icons.description_outlined,
                      title: "Terms of Service",
                      subtitle: "Understand your rights and user agreement",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                    ),
                    Divider(height: 1, color: AppTheme.charcoal.withValues(alpha: 0.06)),
                    _buildLegalTile(
                      icon: Icons.delete_forever_outlined,
                      title: "Delete Account",
                      subtitle: "Permanently delete your profile and account data",
                      onTap: _showDeleteAccountConfirmation,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
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
          final messenger = ScaffoldMessenger.of(context);
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed, size: 28),
                SizedBox(width: 12),
                Text("Delete Account", style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.charcoal)),
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
                    style: TextStyle(fontSize: 13, height: 1.4, color: AppTheme.charcoal, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Please enter your password to confirm account deletion:",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.mutedGrey),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
                    decoration: InputDecoration(
                      hintText: "••••••••",
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGreen, size: 20),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? "Password is required" : null,
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            actions: [
              TextButton(
                onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey, fontWeight: FontWeight.bold)),
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
                          messenger.showSnackBar(
                            SnackBar(content: Text("Incorrect password: $error"), backgroundColor: AppTheme.errorRed),
                          );
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
                          messenger.showSnackBar(
                            const SnackBar(content: Text("Your account has been deleted successfully."), backgroundColor: AppTheme.primaryGreen),
                          );
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(content: Text("Failed to delete account. Please try again later."), backgroundColor: AppTheme.errorRed),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isDeleting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Delete Permanently", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.charcoal),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTheme.charcoal),
          decoration: InputDecoration(
            hintText: 'Enter $label',
            hintStyle: const TextStyle(fontSize: 13.5, color: AppTheme.mutedGrey, fontWeight: FontWeight.normal),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGreen, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.mutedGrey, size: 20),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppTheme.charcoal.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegalTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreenBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.charcoal)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.mutedGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
