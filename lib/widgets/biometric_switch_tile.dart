import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import '../providers/biometric_provider.dart';
import '../services/biometric_service.dart';
import 'face_id_icon.dart';

class BiometricSwitchTile extends ConsumerStatefulWidget {
  const BiometricSwitchTile({super.key});

  @override
  ConsumerState<BiometricSwitchTile> createState() => _BiometricSwitchTileState();
}

class _BiometricSwitchTileState extends ConsumerState<BiometricSwitchTile> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(biometricStateProvider.notifier).refresh();
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    final bioState = ref.read(biometricStateProvider);
    final label = bioState.label;

    if (!value) {
      await ref.read(biometricStateProvider.notifier).setEnabled(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label sign-in disabled.")),
      );
      return;
    }

    if (!bioState.isSupported && bioState.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Set up Face ID or a fingerprint in your device Settings first.")),
      );
      return;
    }

    final user = ref.read(appStateProvider).currentUser;
    if (user == null) return;

    // Like mainstream apps: toggling on immediately shows the native biometric scan.
    final authResult = await BiometricService.authenticateWithDetails(
      reason: "Confirm it's you — scan your $label to enable instant sign-in",
    );
    if (!mounted) return;
    if (!authResult.isSuccess) {
      if (!authResult.isCancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authResult.message ?? "$label scan failed. Please try again.")),
        );
      }
      return;
    }

    // Scan passed: link the current Supabase session to biometrics.
    // No account password is ever requested or stored.
    final refreshToken = Supabase.instance.client.auth.currentSession?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your session has expired. Sign in again, then re-enable biometrics.")),
      );
      return;
    }

    await BiometricService.saveUnlockAccount(
      email: user.email,
      refreshToken: refreshToken,
    );
    await ref.read(biometricStateProvider.notifier).setEnabled(true);
    await BiometricService.setPromptedEnrollment(true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("✅ $label enabled successfully!"),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bioState = ref.watch(biometricStateProvider);

    if (!bioState.isSupported && bioState.isInitialized) {
      return const SizedBox.shrink();
    }

    final label = bioState.label;

    return Material(
      color: Colors.transparent,
      child: SwitchListTile(
        value: bioState.isEnabled,
        onChanged: _toggleBiometrics,
        activeThumbColor: AppTheme.primaryGreen,
        activeTrackColor: AppTheme.primaryGreen.withValues(alpha: 0.5),
        contentPadding: EdgeInsets.zero,
        title: Text(
          "$label Sign-In",
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.charcoal),
        ),
        subtitle: Text(
          "Use $label to unlock and sign in instantly without typing your password",
          style: const TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
        ),
        secondary: DynamicBiometricIcon(
          size: 26,
          color: AppTheme.primaryGreen,
          biometricLabel: label,
        ),
      ),
    );
  }
}
