import '../api/api_client.dart';

/// FCM push registration stub — wire [firebase_messaging] when Firebase config is added.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    // When google-services.json / GoogleService-Info.plist are provided:
    // 1. Firebase.initializeApp()
    // 2. FirebaseMessaging.instance.requestPermission()
    // 3. final token = await FirebaseMessaging.instance.getToken()
    // 4. await _registerToken(token)
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
