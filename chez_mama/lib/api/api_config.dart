import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Central configuration for the backend API base URL.
///
/// - Android emulator reaches the host machine via 10.0.2.2
/// - iOS simulator / desktop use localhost
/// - For a real device, set [overrideBaseUrl] to http://<PC_IP>:8000
class ApiConfig {
  static String? overrideBaseUrl;

  static const int port = 8000;

  static String get baseUrl {
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      return overrideBaseUrl!;
    }
    if (kIsWeb) return 'http://127.0.0.1:$port';
    if (Platform.isAndroid) return 'http://10.0.2.2:$port';
    return 'http://127.0.0.1:$port';
  }

  static String get apiUrl => '$baseUrl/api';
}
