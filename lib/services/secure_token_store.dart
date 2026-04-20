import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SecureTokenStore backs the auth bearer token and other credential-grade
/// values with platform secure storage (Keychain on iOS, Keystore on Android).
///
/// The legacy build persisted these in SharedPreferences as plain strings,
/// which is unacceptable for a payments app. On first call, any legacy
/// token is migrated into secure storage and then deleted from prefs.
class SecureTokenStore {
  SecureTokenStore._();
  static final SecureTokenStore instance = SecureTokenStore._();

  static const _tokenKey = 'authToken';
  static const _userIdKey = 'userId';
  static const _accountTypeKey = 'accountType';
  static const _mobileKey = 'mobile';

  final _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> writeToken(String? token) async {
    if (token == null) return _secure.delete(key: _tokenKey);
    await _secure.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() async {
    final v = await _secure.read(key: _tokenKey);
    if (v != null) return v;
    // One-time migration from the old plaintext location.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_tokenKey);
    if (legacy != null) {
      await _secure.write(key: _tokenKey, value: legacy);
      await prefs.remove(_tokenKey);
      return legacy;
    }
    return null;
  }

  Future<void> writeIdentity({String? userId, String? accountType, String? mobile}) async {
    if (userId != null) await _secure.write(key: _userIdKey, value: userId);
    if (accountType != null) await _secure.write(key: _accountTypeKey, value: accountType);
    if (mobile != null) await _secure.write(key: _mobileKey, value: mobile);
  }

  Future<Map<String, String?>> readIdentity() async {
    return {
      'userId': await _secure.read(key: _userIdKey),
      'accountType': await _secure.read(key: _accountTypeKey),
      'mobile': await _secure.read(key: _mobileKey),
    };
  }

  Future<void> clear() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _userIdKey);
    await _secure.delete(key: _accountTypeKey);
    await _secure.delete(key: _mobileKey);
  }
}
