import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists JWT tokens. Uses secure storage on iOS/Android; SharedPreferences elsewhere.
class TokenStorage {
  TokenStorage._();
  static final TokenStorage instance = TokenStorage._();

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _kMigrated = 'auth.secure_migrated';

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool get _useSecure =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> _migrateFromPrefsIfNeeded() async {
    if (!_useSecure) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kMigrated) == true) return;
    final access = prefs.getString(_kAccess);
    final refresh = prefs.getString(_kRefresh);
    if (access != null && access.isNotEmpty) {
      await _secure.write(key: _kAccess, value: access);
      await prefs.remove(_kAccess);
    }
    if (refresh != null && refresh.isNotEmpty) {
      await _secure.write(key: _kRefresh, value: refresh);
      await prefs.remove(_kRefresh);
    }
    await prefs.setBool(_kMigrated, true);
  }

  Future<String?> readAccess() async {
    await _migrateFromPrefsIfNeeded();
    if (_useSecure) return _secure.read(key: _kAccess);
    return (await SharedPreferences.getInstance()).getString(_kAccess);
  }

  Future<String?> readRefresh() async {
    await _migrateFromPrefsIfNeeded();
    if (_useSecure) return _secure.read(key: _kRefresh);
    return (await SharedPreferences.getInstance()).getString(_kRefresh);
  }

  Future<void> write({required String access, required String refresh}) async {
    if (_useSecure) {
      await _secure.write(key: _kAccess, value: access);
      await _secure.write(key: _kRefresh, value: refresh);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
  }

  Future<void> clear() async {
    if (_useSecure) {
      await _secure.delete(key: _kAccess);
      await _secure.delete(key: _kRefresh);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
  }

  Future<bool> hasToken() async {
    final token = await readAccess();
    return token != null && token.isNotEmpty;
  }
}
