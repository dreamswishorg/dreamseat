import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import '../services/biometric_service.dart';
import 'face_id_icon.dart';

class BiometricSwitchTile extends ConsumerStatefulWidget {
  const BiometricSwitchTile({super.key});

  @override
  ConsumerState<BiometricSwitchTile> createState() => _BiometricSwitchTileState();
}

class _BiometricSwitchTileState extends ConsumerState<BiometricSwitchTile> {
  bool _isEnabled = false;
  bool _isSupported = false;
  String _biometricLabel = "Biometric Sign-In";

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    final label = await BiometricService.getBiometricLabel();
    if (mounted) {
      setState(() {
        _isSupported = supported;
        _isEnabled = enabled;
        _biometricLabel = label;
      });
    }
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (!_isSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometrics not supported or enrolled on this device.")),
      );
      return;
    }

    if (!value) {
      await BiometricService.setBiometricEnabled(false);
      if (!mounted) return;
      setState(() => _isEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$_biometricLabel sign-in disabled.")),
      );
      return;
    }

    // Direct native biometric authentication scan (No password modal needed)
    final messenger = ScaffoldMessenger.of(context);
    final authenticated = await BiometricService.authenticate(
      reason: "Scan your $_biometricLabel to enable instant sign-in on this device",
    );

    if (!mounted) return;

    if (authenticated) {
      await BiometricService.setBiometricEnabled(true);
      final user = ref.read(appStateProvider).currentUser;
      if (user != null) {
        final existingCreds = await BiometricService.getSavedCredentials();
        if (existingCreds == null || existingCreds['email'] != user.email) {
          await BiometricService.saveCredentials(user.email, '');
        }
      }
      setState(() => _isEnabled = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text("✅ $_biometricLabel enabled successfully!"),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Authentication cancelled or not recognized."),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported) {
      return const SizedBox.shrink();
    }

    return SwitchListTile(
      value: _isEnabled,
      onChanged: _toggleBiometrics,
      activeThumbColor: AppTheme.primaryGreen,
      activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
      contentPadding: EdgeInsets.zero,
      title: Text(
        "$_biometricLabel Sign-In",
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.charcoal),
      ),
      subtitle: Text(
        "Use $_biometricLabel to unlock and sign in instantly without typing your password",
        style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
      ),
      secondary: DynamicBiometricIcon(
        size: 26,
        color: AppTheme.primaryGreen,
        biometricLabel: _biometricLabel,
      ),
    );
  }
}

