import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Central configuration for the backend API base URL.
///
/// Production: `--dart-define=API_BASE_URL=https://api.example.com`
/// Physical phone (USB): run `adb reverse tcp:8000 tcp:8000` then use 127.0.0.1
/// Physical phone (Wi‑Fi): `--dart-define=API_BASE_URL=http://192.168.x.x:8000`
class ApiConfig {
  ApiConfig._();

  static String? overrideBaseUrl;
  static late String _resolvedBaseUrl;
  static bool _initialized = false;

  static const int port = 8000;

  /// Set via `--dart-define=API_BASE_URL=https://your-api.com`
  static const String envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Optional LAN IP for physical Android without adb reverse.
  static const String lanHost = String.fromEnvironment('API_LAN_HOST');

  static Future<void> init() async {
    if (_initialized) return;
    if (envBaseUrl.isNotEmpty) {
      _resolvedBaseUrl = envBaseUrl.replaceAll(RegExp(r'/+$'), '');
    } else if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      _resolvedBaseUrl = overrideBaseUrl!.replaceAll(RegExp(r'/+$'), '');
    } else if (kIsWeb) {
      _resolvedBaseUrl = 'http://127.0.0.1:$port';
    } else if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin()
            .androidInfo
            .timeout(const Duration(seconds: 3));
        if (info.isPhysicalDevice) {
          if (lanHost.isNotEmpty) {
            _resolvedBaseUrl = 'http://$lanHost:$port';
          } else {
            // Works with: adb reverse tcp:8000 tcp:8000
            _resolvedBaseUrl = 'http://127.0.0.1:$port';
          }
        } else {
          _resolvedBaseUrl = 'http://10.0.2.2:$port';
        }
      } catch (_) {
        _resolvedBaseUrl = 'http://127.0.0.1:$port';
      }
    } else {
      _resolvedBaseUrl = 'http://127.0.0.1:$port';
    }
    _initialized = true;
  }

  static String get baseUrl {
    assert(
      _initialized || envBaseUrl.isNotEmpty,
      'Call ApiConfig.init() in main() before using the API',
    );
    if (!_initialized && envBaseUrl.isNotEmpty) {
      return envBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    return _resolvedBaseUrl;
  }

  static String get apiUrl => '$baseUrl/api';

  static bool get isProduction => baseUrl.startsWith('https://');

  /// Rewrites MinIO/localhost media URLs so images work on a physical phone.
  static String resolveMediaUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.tryParse(url);
      if (uri != null &&
          (uri.host == 'localhost' ||
              uri.host == '127.0.0.1' ||
              uri.host == '10.0.2.2') &&
          uri.port == 9000) {
        return '$baseUrl${uri.path}';
      }
      return url;
    }
    if (url.startsWith('/')) return '$baseUrl$url';
    return url;
  }
}
