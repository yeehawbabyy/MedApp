import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._internal();
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'medpharm_secure_prefs',
      preferencesKeyPrefix: 'medpharm_',
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      accountName: 'MedPharmApp',
    ),
  );

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyTokenExpiry = 'token_expiry';
  static const String _keyDatabaseKey = 'database_encryption_key';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyStudyId = 'study_id';
  static const String _keyLastActivity = 'last_activity';
  static const String _keySessionId = 'session_id';

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
    print('Access token saved securely');
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
    print('Refresh token saved securely');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(
      key: _keyTokenExpiry,
      value: expiry.toIso8601String(),
    );
  }

  Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _storage.read(key: _keyTokenExpiry);
    if (expiryStr == null) return null;
    return DateTime.tryParse(expiryStr);
  }

  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    final bufferTime = expiry.subtract(const Duration(minutes: 5));
    return DateTime.now().isAfter(bufferTime);
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required DateTime expiry,
  }) async {
    await saveAccessToken(accessToken);
    await saveRefreshToken(refreshToken);
    await saveTokenExpiry(expiry);
    print('All tokens saved securely');
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyTokenExpiry);
    print('All tokens cleared');
  }

  Future<void> saveDatabaseKey(String key) async {
    await _storage.write(key: _keyDatabaseKey, value: key);
    print('Database encryption key saved');
  }

  Future<String?> getDatabaseKey() async {
    return await _storage.read(key: _keyDatabaseKey);
  }

  Future<String> generateDatabaseKey() async {
    final key = _generateSecureKey(32);
    await saveDatabaseKey(key);
    return key;
  }

  String _generateSecureKey(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(chars[(random + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
    print('Biometric setting saved: $enabled');
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  Future<void> saveStudyId(String studyId) async {
    await _storage.write(key: _keyStudyId, value: studyId);
  }

  Future<String?> getStudyId() async {
    return await _storage.read(key: _keyStudyId);
  }

  Future<void> updateLastActivity() async {
    await _storage.write(
      key: _keyLastActivity,
      value: DateTime.now().toIso8601String(),
    );
  }

  Future<DateTime?> getLastActivity() async {
    final value = await _storage.read(key: _keyLastActivity);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  Future<bool> isSessionTimedOut({int timeoutMinutes = 30}) async {
    final lastActivity = await getLastActivity();
    if (lastActivity == null) return true;

    final timeout = lastActivity.add(Duration(minutes: timeoutMinutes));
    return DateTime.now().isAfter(timeout);
  }

  Future<void> saveSessionId(String sessionId) async {
    await _storage.write(key: _keySessionId, value: sessionId);
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: _keySessionId);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
    print('All secure storage cleared');
  }

  Future<void> clearSession() async {
    await clearTokens();
    await _storage.delete(key: _keyStudyId);
    await _storage.delete(key: _keyLastActivity);
    await _storage.delete(key: _keySessionId);
    print('Session data cleared');
  }

  Future<bool> hasValidSession() async {
    final accessToken = await getAccessToken();
    if (accessToken == null) return false;

    final isExpired = await isTokenExpired();
    if (isExpired) {
      final refreshToken = await getRefreshToken();
      return refreshToken != null;
    }

    return true;
  }

  Future<bool> isAvailable() async {
    try {
      await _storage.write(key: '_test', value: 'test');
      await _storage.delete(key: '_test');
      return true;
    } catch (e) {
      print('Secure storage not available: $e');
      return false;
    }
  }
}
