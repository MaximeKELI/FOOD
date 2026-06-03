import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/weather_api.dart';
import '../auth/auth_service.dart';

/// Suggestions météo (jus si chaud, foutou si froid…).
///
/// Intervalle entre 2 notifs météo (défaut 5 h = 18000 s).
/// Test uniquement : `--dart-define=WEATHER_NUDGE_INTERVAL_SECONDS=10`
class WeatherNudgeService {
  WeatherNudgeService._();
  static final WeatherNudgeService instance = WeatherNudgeService._();

  static const _prefsKey = 'weather_nudge_last_ms';
  static const _defaultIntervalSeconds = 18000;

  static int get intervalMs {
    const seconds = int.fromEnvironment(
      'WEATHER_NUDGE_INTERVAL_SECONDS',
      defaultValue: _defaultIntervalSeconds,
    );
    return seconds * 1000;
  }

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  Timer? _testTimer;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    final androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    _ready = true;
    if (kDebugMode) {
      debugPrint('WeatherNudge: interval ${intervalMs ~/ 1000}s');
    }
  }

  /// Timer périodique seulement si l'intervalle est court (mode test explicite).
  void startPeriodicChecks({required AuthService auth}) {
    _testTimer?.cancel();
    if (intervalMs > 60 * 1000) return;
    _testTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => maybeNotify(auth: auth),
    );
  }

  void stopPeriodicChecks() {
    _testTimer?.cancel();
    _testTimer = null;
  }

  Future<void> maybeNotify({AuthService? auth}) async {
    if (!_ready) await init();

    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_prefsKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < intervalMs) return;

    double? lat;
    double? lon;
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 8),
          ),
        );
        lat = pos.latitude;
        lon = pos.longitude;
      }
    } catch (e) {
      debugPrint('WeatherNudge: location skipped ($e)');
    }

    try {
      final suggestion = await WeatherApi.instance.fetchSuggestion(
        latitude: lat,
        longitude: lon,
      );
      if (suggestion.message.isEmpty) return;

      await _showLocal(
        _plainText(suggestion.title),
        _plainText(suggestion.message),
      );
      debugPrint('WeatherNudge: ${suggestion.title} | ${suggestion.message}');

      if (auth != null && auth.isAuthed) {
        final ok = await WeatherApi.instance.requestServerNotify();
        debugPrint('WeatherNudge: server notify ${ok ? "ok" : "skipped/throttled"}');
      }

      await prefs.setInt(_prefsKey, now);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final path = e.requestOptions.uri;
      debugPrint('WeatherNudge error: HTTP $status $path');
      if (status == 404) {
        debugPrint(
          'WeatherNudge: redémarre le backend → docker compose restart django',
        );
      }
    } catch (e) {
      debugPrint('WeatherNudge error: $e');
    }
  }

  String _plainText(String raw) {
    return raw
        .replaceAll('\u2014', ', ')
        .replaceAll('\u2013', ', ')
        .replaceAll('\u2212', ', ');
  }

  Future<void> _showLocal(String title, String body) async {
    const android = AndroidNotificationDetails(
      'weather_nudges',
      'Météo Chez Mama',
      channelDescription: 'Suggestions selon la météo (chaud, froid, soleil)',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: android, iOS: ios),
    );
  }
}
