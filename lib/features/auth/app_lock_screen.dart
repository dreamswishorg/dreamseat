import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ds_kit.dart';
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
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppTheme.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: AppSpace.x4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DsCard(
                  padding: const EdgeInsets.all(AppSpace.x3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(color: AppTheme.lightGreenBg, shape: BoxShape.circle),
                          child: Center(
                            child: DynamicBiometricIcon(size: 48, color: AppTheme.primaryGreen, biometricLabel: _biometricLabel),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      Semantics(
                        header: true,
                        child: Text(
                          'DreamEats is Locked',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        'Scan your $_biometricLabel to resume your active session.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpace.lg),
                        Semantics(
                          liveRegion: true,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                            decoration: BoxDecoration(color: const Color(0xFFFEECEC), borderRadius: AppRadius.rSm),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpace.xxl),
                      DsButton(
                        label: 'Unlock with $_biometricLabel',
                        loading: _isPrompting,
                        leading: DynamicBiometricIcon(size: 22, color: AppTheme.pureWhite, biometricLabel: _biometricLabel),
                        onPressed: _isPrompting ? null : _unlock,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      TextButton(
                        onPressed: _handleLogout,
                        style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
                        child: const Text('Log Out of Session'),
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
