import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum BiometricStatus {
  success,
  userCancelled,
  notRecognized,
  lockedOut,
  notAvailable,
  error,
}

class BiometricResult {
  final BiometricStatus status;
  final String? message;

  const BiometricResult({required this.status, this.message});

  bool get isSuccess => status == BiometricStatus.success;
  bool get isCancelled => status == BiometricStatus.userCancelled;
  bool get isNotRecognized => status == BiometricStatus.notRecognized;
  bool get isLockedOut => status == BiometricStatus.lockedOut;
  bool get isNotAvailable => status == BiometricStatus.notAvailable;
}

class BiometricService {
  static final _auth = LocalAuthentication();
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyBiometricEmail = 'biometric_email';
  static const String _keyBiometricPassword = 'biometric_password';

  /// Check if the device is capable of biometric authentication (iOS & Android)
  static Future<bool> isBiometricAvailable() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return isDeviceSupported || canCheck || availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint("Biometric availability error: $e");
      return false;
    }
  }

  /// Returns friendly device-specific label ("Face ID", "Touch ID", "Fingerprint", or "Biometrics")
  static Future<String> getBiometricLabel() async {
    try {
      final biometrics = await _auth.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return "Face ID";
      } else if (biometrics.contains(BiometricType.fingerprint)) {
        return defaultTargetPlatform == TargetPlatform.iOS ? "Touch ID" : "Fingerprint";
      } else if (biometrics.contains(BiometricType.iris)) {
        return "Iris Scan";
      }
      return defaultTargetPlatform == TargetPlatform.iOS ? "Face ID / Touch ID" : "Fingerprint";
    } catch (_) {
      return "Biometric Sign-In";
    }
  }

  /// Returns appropriate icon for current platform biometric type
  static Future<IconData> getBiometricIcon() async {
    return Icons.fingerprint_rounded;
  }

  /// Check if the user has enabled biometric login
  static Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Enable or disable biometric login
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _keyBiometricEnabled,
      value: enabled ? 'true' : 'false',
    );
    if (!enabled) {
      await clearSavedCredentials();
    }
  }

  /// Securely save credentials
  static Future<void> saveCredentials(String email, String password) async {
    try {
      await _secureStorage.write(key: _keyBiometricEmail, value: email.trim());
      await _secureStorage.write(key: _keyBiometricPassword, value: password);
    } catch (e) {
      debugPrint("Error saving credentials: $e");
    }
  }

  /// Clear saved credentials
  static Future<void> clearSavedCredentials() async {
    try {
      await _secureStorage.delete(key: _keyBiometricEmail);
      await _secureStorage.delete(key: _keyBiometricPassword);
    } catch (_) {}
  }

  /// Retrieve saved credentials
  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: _keyBiometricEmail);
      final password = await _secureStorage.read(key: _keyBiometricPassword);
      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        return {'email': email, 'password': password};
      }
    } catch (e) {
      debugPrint("Error reading credentials: $e");
    }
    return null;
  }

  /// Prompt the user to authenticate using native device biometrics with detailed outcome classification.
  /// [biometricOnly] is strictly true by default so that declining or failing
  /// Face ID/Touch ID never falls back to the device PIN/passcode.
  static Future<BiometricResult> authenticateWithDetails({
    String? reason,
    bool biometricOnly = true,
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        return const BiometricResult(
          status: BiometricStatus.notAvailable,
          message: 'Biometric authentication is not supported or enrolled on this device.',
        );
      }

      final label = await getBiometricLabel();
      final didAuthenticate = await _auth.authenticate(
        localizedReason: reason ?? 'Please scan your $label to sign in securely',
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: false,
      );

      if (didAuthenticate) {
        return const BiometricResult(status: BiometricStatus.success);
      } else {
        return const BiometricResult(
          status: BiometricStatus.userCancelled,
          message: 'Authentication was cancelled.',
        );
      }
    } on LocalAuthException catch (e) {
      debugPrint("LocalAuthException: ${e.code} - ${e.description}");
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
          return const BiometricResult(status: BiometricStatus.userCancelled);
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricResult(
            status: BiometricStatus.lockedOut,
            message: 'Biometrics temporarily locked out due to multiple attempts.',
          );
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return const BiometricResult(
            status: BiometricStatus.notAvailable,
            message: 'Biometrics unavailable on this device.',
          );
        default:
          return BiometricResult(status: BiometricStatus.error, message: e.description);
      }
    } on PlatformException catch (e) {
      debugPrint("PlatformException in biometric auth: ${e.code} - ${e.message}");
      final codeLower = e.code.toLowerCase();
      if (codeLower.contains('cancel') || codeLower.contains('usercancel')) {
        return const BiometricResult(status: BiometricStatus.userCancelled);
      }
      if (codeLower.contains('locked') || codeLower.contains('lockout')) {
        return const BiometricResult(
          status: BiometricStatus.lockedOut,
          message: 'Biometrics temporarily locked out.',
        );
      }
      if (codeLower.contains('notavailable') || codeLower.contains('notenrolled')) {
        return const BiometricResult(
          status: BiometricStatus.notAvailable,
          message: 'Biometrics unavailable on this device.',
        );
      }
      return BiometricResult(status: BiometricStatus.error, message: e.message);
    } catch (e) {
      debugPrint("Unexpected biometric auth error: $e");
      final str = e.toString().toLowerCase();
      if (str.contains('cancel')) {
        return const BiometricResult(status: BiometricStatus.userCancelled);
      }
      return BiometricResult(status: BiometricStatus.error, message: e.toString());
    }
  }

  /// Convenience wrapper returning boolean
  static Future<bool> authenticate({String? reason, bool biometricOnly = true}) async {
    final res = await authenticateWithDetails(reason: reason, biometricOnly: biometricOnly);
    return res.isSuccess;
  }
}
