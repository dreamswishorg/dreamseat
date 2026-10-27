import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dreameats/services/biometric_service.dart';
import 'package:dreameats/providers/biometric_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BiometricResult Outcome Classification Tests', () {
    test('Success outcome correctly reports isSuccess and not cancelled', () {
      const res = BiometricResult(status: BiometricStatus.success);
      expect(res.isSuccess, isTrue);
      expect(res.isCancelled, isFalse);
      expect(res.isLockedOut, isFalse);
      expect(res.isNotAvailable, isFalse);
    });

    test('User cancellation outcome reports isCancelled without being success or lockout', () {
      const res = BiometricResult(
        status: BiometricStatus.userCancelled,
        message: 'Authentication was cancelled.',
      );
      expect(res.isSuccess, isFalse);
      expect(res.isCancelled, isTrue);
      expect(res.isLockedOut, isFalse);
      expect(res.isNotRecognized, isFalse);
    });

    test('Locked out outcome correctly reports isLockedOut', () {
      const res = BiometricResult(
        status: BiometricStatus.lockedOut,
        message: 'Biometrics temporarily locked out.',
      );
      expect(res.isSuccess, isFalse);
      expect(res.isCancelled, isFalse);
      expect(res.isLockedOut, isTrue);
    });

    test('Not recognized outcome reports isNotRecognized', () {
      const res = BiometricResult(
        status: BiometricStatus.notRecognized,
        message: 'Face ID not recognized.',
      );
      expect(res.isSuccess, isFalse);
      expect(res.isCancelled, isFalse);
      expect(res.isNotRecognized, isTrue);
    });

    test('Unavailable outcome correctly reports isNotAvailable', () {
      const res = BiometricResult(
        status: BiometricStatus.notAvailable,
        message: 'Biometrics unavailable on this device.',
      );
      expect(res.isSuccess, isFalse);
      expect(res.isNotAvailable, isTrue);
    });
  });

  group('BiometricState & Provider Cross-Screen Sync Tests', () {
    test('BiometricState copyWith updates attributes predictably', () {
      const initial = BiometricState(
        isSupported: true,
        isEnabled: false,
        label: 'Face ID',
        isInitialized: true,
      );

      final updated = initial.copyWith(isEnabled: true);
      expect(updated.isEnabled, isTrue);
      expect(updated.isSupported, isTrue);
      expect(updated.label, 'Face ID');
    });

    test('Provider reflects enabledNotifier updates immediately across subscribers', () async {
      final container = ProviderContainer();

      final initialState = container.read(biometricStateProvider);
      expect(initialState.isEnabled, isFalse);

      // Simulate service updating enabled preference
      BiometricService.enabledNotifier.value = true;
      final updatedState = container.read(biometricStateProvider);
      expect(updatedState.isEnabled, isTrue);

      BiometricService.enabledNotifier.value = false;
      final revertedState = container.read(biometricStateProvider);
      expect(revertedState.isEnabled, isFalse);

      await Future.delayed(const Duration(milliseconds: 20));
      container.dispose();
    });
  });
}
