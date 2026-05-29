import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Central configuration for the backend API base URL.
///
/// Production: pass `--dart-define=API_BASE_URL=https://api.example.com`
/// Dev Android emulator: 10.0.2.2 | iOS/desktop: 127.0.0.1
class ApiConfig {
  ApiConfig._();

  static String? overrideBaseUrl;

  static const int port = 8000;

  /// Set via `--dart-define=API_BASE_URL=https://your-api.com`
  static const String envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (envBaseUrl.isNotEmpty) return envBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!.replaceAll(RegExp(r'/+$'), '');
    }
    if (kIsWeb) return 'http://127.0.0.1:$port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port';
    return 'http://127.0.0.1:$port';
  }

  static String get apiUrl => '$baseUrl/api';

  static bool get isProduction => envBaseUrl.startsWith('https://');
}
