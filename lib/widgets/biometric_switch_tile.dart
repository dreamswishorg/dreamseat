import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import '../services/biometric_service.dart';

class BiometricSwitchTile extends ConsumerStatefulWidget {
  const BiometricSwitchTile({super.key});

  @override
  ConsumerState<BiometricSwitchTile> createState() => _BiometricSwitchTileState();
}

class _BiometricSwitchTileState extends ConsumerState<BiometricSwitchTile> {
  bool _isEnabled = false;
  bool _isSupported = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final supported = await BiometricService.isBiometricAvailable();
    final enabled = await BiometricService.isBiometricEnabled();
    setState(() {
      _isSupported = supported;
      _isEnabled = enabled;
    });
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
        const SnackBar(content: Text("Biometric login disabled successfully.")),
      );
      return;
    }

    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.fingerprint_rounded, color: AppTheme.primaryGreen),
                SizedBox(width: 12),
                Text("Enable Biometrics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.charcoal)),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please confirm your account password to secure biometric credentials on this device.",
                    style: TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Account Password",
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Password is required" : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(ctx),
                child: const Text("Cancel", style: TextStyle(color: AppTheme.mutedGrey)),
              ),
              ElevatedButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final user = ref.read(appStateProvider).currentUser;
                        if (user == null) return;
                        
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);

                        setModalState(() => isVerifying = true);
                        final error = await ref.read(appStateProvider.notifier).validateCurrentPassword(
                          email: user.email,
                          password: passwordCtrl.text,
                        );
                        
                        if (context.mounted && ctx.mounted) {
                          setModalState(() => isVerifying = false);
                          if (error == null) {
                            await BiometricService.setBiometricEnabled(true);
                            await BiometricService.saveCredentials(user.email, passwordCtrl.text);
                            setState(() => _isEnabled = true);
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(content: Text("✅ Biometric login enabled successfully!"), backgroundColor: AppTheme.primaryGreen),
                            );
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text("Incorrect password: $error"), backgroundColor: AppTheme.errorRed),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.charcoal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isVerifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Confirm"),
              ),
            ],
          );
        }
      ),
    );
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
      title: const Text(
        "Biometric Sign-In",
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.charcoal),
      ),
      subtitle: const Text(
        "Use Face ID or Touch ID to unlock and sign in instantly",
        style: TextStyle(fontSize: 12, color: AppTheme.mutedGrey),
      ),
      secondary: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryGreen, size: 28),
    );
  }
}
