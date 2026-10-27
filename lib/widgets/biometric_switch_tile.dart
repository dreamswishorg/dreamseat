import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
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

    if (!bioState.isSupported && bioState.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Biometrics not supported or enrolled on this device.")),
      );
      return;
    }

    if (!value) {
      await ref.read(biometricStateProvider.notifier).setEnabled(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label sign-in disabled.")),
      );
      return;
    }

    final user = ref.read(appStateProvider).currentUser;
    if (user == null) return;

    final existingCreds = await BiometricService.getSavedCredentials();
    if (existingCreds != null &&
        existingCreds['email'] == user.email &&
        existingCreds['password'] != null &&
        existingCreds['password']!.isNotEmpty) {
      final authenticated = await BiometricService.authenticate(
        reason: "Scan your $label to enable instant sign-in",
        biometricOnly: false,
      );
      if (!mounted) return;
      if (authenticated) {
        await ref.read(biometricStateProvider.notifier).setEnabled(true);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $label enabled successfully!"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } else {
      await _promptPasswordAndEnable(user, label);
    }
  }

  Future<void> _promptPasswordAndEnable(AppUser user, String label) async {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    bool isVerifying = false;
    String? errorText;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
            final textCol = isDark ? Colors.white : AppTheme.charcoal;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: AppTheme.lightGreenBg,
                        shape: BoxShape.circle,
                      ),
                      child: DynamicBiometricIcon(
                        size: 36,
                        color: AppTheme.primaryGreen,
                        biometricLabel: label,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Enable $label",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Enter your password once to securely link biometric login",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.mutedGrey),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      autofocus: true,
                      style: TextStyle(color: textCol, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Account Password",
                        hintText: "Enter your password",
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGreen),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppTheme.mutedGrey,
                          ),
                          onPressed: () => setModalState(() => obscure = !obscure),
                        ),
                        errorText: errorText,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) {
                        if (!isVerifying) {
                          // trigger verification
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isVerifying
                          ? null
                          : () async {
                              final pwd = passwordCtrl.text;
                              if (pwd.isEmpty) {
                                setModalState(() => errorText = "Please enter your password");
                                return;
                              }

                              setModalState(() {
                                isVerifying = true;
                                errorText = null;
                              });

                              final err = await ref.read(appStateProvider.notifier).validateCurrentPassword(
                                    email: user.email,
                                    password: pwd,
                                  );

                              if (err != null) {
                                setModalState(() {
                                  isVerifying = false;
                                  errorText = "Incorrect password. Please try again.";
                                });
                                return;
                              }

                              // Dismiss keyboard to release UI focus before native iOS/Android biometric prompt
                              if (!context.mounted) return;
                              FocusScope.of(context).unfocus();
                              await Future.delayed(const Duration(milliseconds: 350));

                              final authResult = await BiometricService.authenticateWithDetails(
                                reason: "Scan your $label to link this device",
                                biometricOnly: false,
                              );

                              if (!authResult.isSuccess) {
                                setModalState(() {
                                  isVerifying = false;
                                  errorText = authResult.message ?? "$label scan cancelled or failed.";
                                });
                                return;
                              }

                              await BiometricService.saveCredentials(user.email, pwd);
                              await ref.read(biometricStateProvider.notifier).setEnabled(true);
                              await BiometricService.setPromptedEnrollment(true);

                              if (context.mounted) {
                                Navigator.pop(ctx, true);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ $label enabled successfully!"),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
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
