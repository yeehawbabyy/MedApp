
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'secure_storage_service.dart';


class BiometricService {
  BiometricService._internal();
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;

  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();

  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException catch (e) {
      print('Error checking device support: $e');
      return false;
    }
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Error checking biometrics availability: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<BiometricAvailability> checkAvailability() async {
    final isSupported = await isDeviceSupported();
    if (!isSupported) {
      return BiometricAvailability.notSupported;
    }

    final canCheck = await canCheckBiometrics();
    if (!canCheck) {
      return BiometricAvailability.notEnrolled;
    }

    final types = await getAvailableBiometrics();
    if (types.isEmpty) {
      return BiometricAvailability.notEnrolled;
    }

    return BiometricAvailability.available;
  }

  Future<String> getBiometricTypeDescription() async {
    final types = await getAvailableBiometrics();

    if (types.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (types.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (types.contains(BiometricType.iris)) {
      return 'Iris Scanner';
    } else if (types.contains(BiometricType.strong)) {
      return 'Biometric Authentication';
    } else if (types.contains(BiometricType.weak)) {
      return 'Biometric Authentication';
    }

    return 'Biometric Authentication';
  }

  Future<BiometricResult> authenticate({
    String reason = 'Proszę zweryfikować swoją tożsamość',
    bool allowDeviceCredentials = true,
  }) async {
    try {
      final availability = await checkAvailability();
      if (availability != BiometricAvailability.available) {
        return BiometricResult(
          success: false,
          error: BiometricError.notAvailable,
          message: 'Biometria nie jest dostępna na tym urządzeniu',
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !allowDeviceCredentials,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.updateLastActivity();

        return BiometricResult(
          success: true,
          error: null,
          message: 'Uwierzytelnienie pomyślne',
        );
      } else {
        return BiometricResult(
          success: false,
          error: BiometricError.failed,
          message: 'Uwierzytelnienie nie powiodło się',
        );
      }
    } on PlatformException catch (e) {
      return _handlePlatformException(e);
    }
  }

  BiometricResult _handlePlatformException(PlatformException e) {
    print('Biometric authentication error: ${e.code} - ${e.message}');

    switch (e.code) {
      case 'NotAvailable':
        return BiometricResult(
          success: false,
          error: BiometricError.notAvailable,
          message: 'Biometria nie jest dostępna',
        );
      case 'NotEnrolled':
        return BiometricResult(
          success: false,
          error: BiometricError.notEnrolled,
          message: 'Brak zarejestrowanych danych biometrycznych',
        );
      case 'LockedOut':
        return BiometricResult(
          success: false,
          error: BiometricError.lockedOut,
          message: 'Zbyt wiele nieudanych prób. Spróbuj później',
        );
      case 'PermanentlyLockedOut':
        return BiometricResult(
          success: false,
          error: BiometricError.permanentlyLockedOut,
          message: 'Biometria jest zablokowana. Użyj kodu PIN',
        );
      case 'PasscodeNotSet':
        return BiometricResult(
          success: false,
          error: BiometricError.passcodeNotSet,
          message: 'Nie ustawiono kodu blokady urządzenia',
        );
      default:
        return BiometricResult(
          success: false,
          error: BiometricError.unknown,
          message: 'Wystąpił nieoczekiwany błąd: ${e.message}',
        );
    }
  }

  Future<bool> enableBiometric() async {
    final result = await authenticate(
      reason: 'Zweryfikuj tożsamość, aby włączyć biometrię',
    );

    if (result.success) {
      await _secureStorage.setBiometricEnabled(true);
      print('Biometric authentication enabled');
      return true;
    }

    print('Failed to enable biometric: ${result.message}');
    return false;
  }

  Future<void> disableBiometric() async {
    await _secureStorage.setBiometricEnabled(false);
    print('Biometric authentication disabled');
  }

  Future<bool> isBiometricEnabled() async {
    return await _secureStorage.isBiometricEnabled();
  }

  Future<bool> toggleBiometric() async {
    final isEnabled = await isBiometricEnabled();
    if (isEnabled) {
      await disableBiometric();
      return false;
    } else {
      return await enableBiometric();
    }
  }

  Future<bool> shouldRequireBiometric() async {
    final isEnabled = await isBiometricEnabled();
    if (!isEnabled) return false;

    final isTimedOut = await _secureStorage.isSessionTimedOut();
    return isTimedOut;
  }

  Future<BiometricResult> authenticateForAppAccess() async {
    final shouldRequire = await shouldRequireBiometric();
    if (!shouldRequire) {
      await _secureStorage.updateLastActivity();
      return BiometricResult(
        success: true,
        error: null,
        message: 'Brak wymaganej weryfikacji',
      );
    }

    return await authenticate(
      reason: 'Zweryfikuj tożsamość, aby uzyskać dostęp do aplikacji',
    );
  }

  Future<void> stopAuthentication() async {
    await _localAuth.stopAuthentication();
  }
}

enum BiometricAvailability {
  available,
  notSupported,
  notEnrolled,
}

enum BiometricError {
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  passcodeNotSet,
  failed,
  cancelled,
  unknown,
}

class BiometricResult {
  final bool success;
  final BiometricError? error;
  final String message;

  BiometricResult({
    required this.success,
    required this.error,
    required this.message,
  });

  @override
  String toString() {
    return 'BiometricResult(success: $success, error: $error, message: $message)';
  }
}
