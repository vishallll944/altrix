import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AuthSessionStorage {
  Future<void> saveToken(String token);
  Future<String?> readToken();
  Future<void> clearToken();
}

class SecureAuthSessionStorage implements AuthSessionStorage {
  const SecureAuthSessionStorage(this._storage);

  static const _tokenKey = 'auth_token';

  final FlutterSecureStorage _storage;

  @override
  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } on MissingPluginException {
      // Native plugin is unavailable until a full app restart/rebuild.
    }
  }

  @override
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _tokenKey);
    } on MissingPluginException {
      // Native plugin is unavailable until a full app restart/rebuild.
    }
  }
}

class PersistentAuthSessionStorage implements AuthSessionStorage {
  PersistentAuthSessionStorage({
    required this._secure,
    required this._prefs,
  });

  static const _tokenKey = 'auth_token';

  final SecureAuthSessionStorage _secure;
  final SharedPreferences _prefs;

  @override
  Future<void> saveToken(String token) async {
    await _secure.saveToken(token);
    await _prefs.setString(_tokenKey, token);
  }

  @override
  Future<String?> readToken() async {
    final secureToken = await _secure.readToken();
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    final prefsToken = _prefs.getString(_tokenKey);
    if (prefsToken != null && prefsToken.isNotEmpty) {
      return prefsToken;
    }

    return null;
  }

  @override
  Future<void> clearToken() async {
    await _secure.clearToken();
    await _prefs.remove(_tokenKey);
  }
}
