import 'package:flutter_test/flutter_test.dart';
import 'package:dreameats/services/biometric_service.dart';

void main() {
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
}
