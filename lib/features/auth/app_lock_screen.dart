import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/app_state.dart';
import '../../services/biometric_service.dart';
import '../../widgets/face_id_icon.dart';

/// Screen displayed when the app is locked following backgrounding or cold-boot
/// while a valid user session is active and biometric quick-unlock is enabled.
class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;
  const AppLockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _biometricLabel = 'Face ID';
  bool _isPrompting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLabelAndPrompt();
  }

  Future<void> _loadLabelAndPrompt() async {
    final label = await BiometricService.getBiometricLabel();
    if (mounted) {
      setState(() => _biometricLabel = label);
      _unlock();
    }
  }

  Future<void> _unlock() async {
    if (_isPrompting) return;
    setState(() {
      _isPrompting = true;
      _errorMessage = null;
    });

    final result = await BiometricService.authenticateWithDetails(
      reason: 'Scan your $_biometricLabel to unlock DreamEats',
    );

    if (!mounted) return;
    setState(() => _isPrompting = false);

    if (result.isSuccess) {
      widget.onUnlocked();
    } else if (result.isLockedOut || result.isNotAvailable) {
      // Biometrics are exhausted or no longer usable - send the user back to
      // sign in so they can re-enter their credentials. The signedOut event
      // in main.dart routes to the Welcome screen with this message.
      await ref.read(appStateProvider.notifier).signOut(
            errorMessage: result.isLockedOut
                ? 'Too many failed biometric attempts. Please sign in again.'
                : 'Biometrics are no longer available on this device. Please sign in again.',
          );
    } else if (!result.isCancelled) {
      setState(() => _errorMessage = '$_biometricLabel not recognized. Please try again.');
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(appStateProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryText = isDark ? Colors.white : AppTheme.charcoal;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: const BoxDecoration(
                          color: AppTheme.lightGreenBg,
                          shape: BoxShape.circle,
                        ),
                        child: DynamicBiometricIcon(
                          size: 48,
                          color: AppTheme.primaryGreen,
                          biometricLabel: _biometricLabel,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'DreamEats is Locked',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: primaryText,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scan your $_biometricLabel to resume your active session.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedGrey,
                          height: 1.4,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isPrompting ? null : _unlock,
                          icon: _isPrompting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : DynamicBiometricIcon(
                                  size: 20,
                                  color: Colors.white,
                                  biometricLabel: _biometricLabel,
                                ),
                          label: Text(
                            'Unlock with $_biometricLabel',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _handleLogout,
                        child: const Text(
                          'Log Out of Session',
                          style: TextStyle(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
