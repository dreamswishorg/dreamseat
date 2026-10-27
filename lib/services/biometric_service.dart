import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';
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
  static const String _keyBiometricPrompted = 'biometric_prompted_once';

  /// Check if the user has already made an enrollment choice (accepted or declined)
  static Future<bool> hasPromptedEnrollment() async {
    try {
      final value = await _secureStorage.read(key: _keyBiometricPrompted);
      return value == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Mark that the user has made an enrollment decision so they are not repeatedly interrupted
  static Future<void> setPromptedEnrollment([bool prompted = true]) async {
    try {
      await _secureStorage.write(
        key: _keyBiometricPrompted,
        value: prompted ? 'true' : 'false',
      );
    } catch (_) {}
  }

  /// Check if the device has biometrics actually enrolled and usable (iOS & Android).
  /// `canCheckBiometrics` only reports hardware presence (still true with nothing
  /// enrolled on Android), so the enrolled-biometrics list is the source of truth.
  static Future<bool> isBiometricAvailable() async {
    try {
      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      debugPrint("Biometric availability error: $e");
      try {
        return await _auth.canCheckBiometrics;
      } catch (_) {
        return false;
      }
    }
  }

  static final ValueNotifier<bool> enabledNotifier = ValueNotifier<bool>(false);

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
      return defaultTargetPlatform == TargetPlatform.iOS ? "Face ID" : "Fingerprint";
    } catch (_) {
      return defaultTargetPlatform == TargetPlatform.iOS ? "Face ID" : "Biometric Sign-In";
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
      final isEnabled = value == 'true';
      if (enabledNotifier.value != isEnabled) {
        enabledNotifier.value = isEnabled;
      }
      return isEnabled;
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
    enabledNotifier.value = enabled;
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

  /// Shows the native biometric sheet (Face ID / Touch ID / fingerprint) exactly once.
  /// The OS sheet itself allows several scan attempts before dismissing.
  /// There is deliberately NO automatic fallback to the device passcode/PIN:
  /// on failure or cancel the caller shows the app's own password form,
  /// matching how mainstream apps handle biometric sign-in.
  static Future<BiometricResult> authenticateWithDetails({
    String? reason,
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) {
        return const BiometricResult(
          status: BiometricStatus.notAvailable,
          message: 'No biometrics are set up on this device. Add Face ID or a fingerprint in your device Settings first.',
        );
      }

      final label = await getBiometricLabel();
      final authReason = reason ?? 'Please scan your $label to continue';

      // Setting localizedFallbackTitle to '' hides the "Enter Passcode" fallback button
      // from the native iOS HUD, ensuring only the biometric scan runs.
      const iosAuthMessages = IOSAuthMessages(
        cancelButton: 'Cancel',
        localizedFallbackTitle: '',
      );

      final didAuth = await _auth.authenticate(
        localizedReason: authReason,
        authMessages: const [iosAuthMessages],
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );

      if (didAuth) {
        return const BiometricResult(status: BiometricStatus.success);
      }
      return BiometricResult(
        status: BiometricStatus.notRecognized,
        message: "$label didn't recognize you. Please try again.",
      );
    } on LocalAuthException catch (e) {
      debugPrint("Biometric auth error: ${e.code} - ${e.description}");
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.userRequestedFallback:
          return const BiometricResult(status: BiometricStatus.userCancelled);
        case LocalAuthExceptionCode.temporaryLockout:
        case LocalAuthExceptionCode.biometricLockout:
          return const BiometricResult(
            status: BiometricStatus.lockedOut,
            message: 'Biometrics temporarily locked after too many attempts. Use your password or try again later.',
          );
        case LocalAuthExceptionCode.noBiometricsEnrolled:
        case LocalAuthExceptionCode.noBiometricHardware:
        case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
          return const BiometricResult(
            status: BiometricStatus.notAvailable,
            message: "Biometrics aren't available on this device. Enable Face ID or fingerprint in Settings, then try again.",
          );
        default:
          return BiometricResult(
            status: BiometricStatus.error,
            message: e.description ?? 'Biometric authentication failed.',
          );
      }
    } on PlatformException catch (e) {
      final codeLower = e.code.toLowerCase();
      if (codeLower.contains('cancel')) {
        return const BiometricResult(status: BiometricStatus.userCancelled);
      }
      return BiometricResult(status: BiometricStatus.error, message: e.message);
    } catch (e) {
      return BiometricResult(status: BiometricStatus.error, message: e.toString());
    }
  }

  /// Convenience wrapper returning boolean
  static Future<bool> authenticate({String? reason}) async {
    final res = await authenticateWithDetails(reason: reason);
    return res.isSuccess;
  }
}
