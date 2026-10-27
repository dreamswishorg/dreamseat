import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../models/models.dart';
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

    final user = ref.read(appStateProvider).currentUser;
    if (user == null) return;

    final existingCreds = await BiometricService.getSavedCredentials();
    if (existingCreds != null &&
        existingCreds['email'] == user.email &&
        existingCreds['password'] != null &&
        existingCreds['password']!.isNotEmpty) {
      final authenticated = await BiometricService.authenticate(
        reason: "Scan your $_biometricLabel to enable instant sign-in",
      );
      if (!mounted) return;
      if (authenticated) {
        await BiometricService.setBiometricEnabled(true);
        setState(() => _isEnabled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $_biometricLabel enabled successfully!"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } else {
      await _promptPasswordAndEnable(user);
    }
  }

  Future<void> _promptPasswordAndEnable(AppUser user) async {
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppTheme.lightGreenBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.fingerprint_rounded, color: AppTheme.primaryGreen, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Enable $_biometricLabel",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textCol,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                "Enter your password once to securely link biometric login",
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.mutedGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: obscure,
                      autofocus: true,
                      style: TextStyle(color: textCol, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: "Account Password",
                        errorText: errorText,
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryGreen),
                        suffixIcon: IconButton(
                          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setModalState(() => obscure = !obscure),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isVerifying
                          ? null
                          : () async {
                              final pwd = passwordCtrl.text;
                              if (pwd.isEmpty) {
                                setModalState(() => errorText = "Password cannot be empty");
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
                              FocusScope.of(context).unfocus();
                              await Future.delayed(const Duration(milliseconds: 300));

                              final authResult = await BiometricService.authenticateWithDetails(
                                reason: "Scan your $_biometricLabel to link this device",
                              );

                              if (!authResult.isSuccess) {
                                setModalState(() {
                                  isVerifying = false;
                                  errorText = authResult.message ?? "$_biometricLabel scan cancelled or failed.";
                                });
                                return;
                              }

                              await BiometricService.saveCredentials(user.email, pwd);
                              await BiometricService.setBiometricEnabled(true);
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
                          : Text("Confirm & Link $_biometricLabel", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
      setState(() => _isEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ $_biometricLabel enabled successfully!"),
          backgroundColor: AppTheme.primaryGreen,
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

