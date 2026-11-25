import 'dart:async';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../auth/auth_service.dart';

/// FCM push registration stub — wire [firebase_messaging] when Firebase config is added.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;
  AuthService? _auth;
  VoidCallback? _authListener;
  String? _lastToken;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    // When google-services.json / GoogleService-Info.plist are provided:
    // 1. Firebase.initializeApp()
    // 2. FirebaseMessaging.instance.requestPermission()
    // 3. final token = await FirebaseMessaging.instance.getToken()
    // 4. await _registerToken(token)
  }

  /// Connect push registration to login / logout (dev token on desktop/Linux).
  void bindAuth(AuthService auth) {
    if (_auth == auth) return;
    if (_auth != null && _authListener != null) {
      _auth!.removeListener(_authListener!);
    }
    _auth = auth;
    _authListener = () {
      if (auth.isAuthed && auth.userId != null) {
        unawaited(_registerDevToken(auth.userId!));
      } else {
        unawaited(_unregisterDevToken());
      }
    };
    auth.addListener(_authListener!);
    if (auth.isAuthed && auth.userId != null) {
      unawaited(_registerDevToken(auth.userId!));
    }
  }

  Future<void> _registerDevToken(int userId) async {
    final token = 'linux-dev-$userId';
    if (_lastToken == token) return;
    _lastToken = token;
    try {
      await registerToken(token, platform: 'linux');
    } catch (e) {
      debugPrint('PushService register: $e');
    }
  }

  Future<void> _unregisterDevToken() async {
    final token = _lastToken;
    _lastToken = null;
    if (token == null) return;
    try {
      await unregisterToken(token);
    } catch (_) {}
  }

  Future<void> registerToken(String token, {String platform = ''}) async {
    if (token.isEmpty) return;
    await ApiClient.instance.dio.post(
      '/notifications/push/register/',
      data: {'token': token, 'platform': platform},
    );
  }

  Future<void> unregisterToken(String token) async {
    if (token.isEmpty) return;
    await ApiClient.instance.dio.delete(
      '/notifications/push/register/',
      data: {'token': token},
    );
  }
}