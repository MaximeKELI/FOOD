import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Central configuration for the backend API base URL.
///
/// Default: remote Heroku backend ([remoteBaseUrl]).
/// Local Docker: `--dart-define=USE_LOCAL_API=true`
/// Custom URL: `--dart-define=API_BASE_URL=https://api.example.com`
/// Physical phone (USB, local): `adb reverse tcp:8000` + `USE_LOCAL_API=true`
/// Physical phone (Wi‑Fi, local): `--dart-define=USE_LOCAL_API=true --dart-define=API_LAN_HOST=192.168.x.x`
class ApiConfig {
  ApiConfig._();

  static String? overrideBaseUrl;
  static late String _resolvedBaseUrl;
  static bool _initialized = false;

  static const int port = 8000;

  /// Deployed backend on Heroku (used by default).
  static const String remoteBaseUrl =
      'https://allcoders-5eced76bab42.herokuapp.com';

  /// Set via `--dart-define=API_BASE_URL=https://your-api.com`
  static const String envBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Local Docker backend — `--dart-define=USE_LOCAL_API=true`
  static const bool useLocalApi = bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: false,
  );

  /// Optional LAN IP for physical Android without adb reverse.
  static const String lanHost = String.fromEnvironment('API_LAN_HOST');

  static Future<void> init() async {
    if (_initialized) return;

    if (envBaseUrl.isNotEmpty) {
      _resolvedBaseUrl = envBaseUrl.replaceAll(RegExp(r'/+$'), '');
      _initialized = true;
      return;
    }
    if (overrideBaseUrl != null && overrideBaseUrl!.isNotEmpty) {
      _resolvedBaseUrl = overrideBaseUrl!.replaceAll(RegExp(r'/+$'), '');
      _initialized = true;
      return;
    }

    if (!useLocalApi) {
      _resolvedBaseUrl = remoteBaseUrl.replaceAll(RegExp(r'/+$'), '');
      _initialized = true;
      if (kDebugMode) {
        debugPrint('[ApiConfig] Using remote API at $_resolvedBaseUrl');
      }
      return;
    }

    final candidates = await _connectionCandidates();
    for (final url in candidates) {
      if (await _probeHealth(url)) {
        _resolvedBaseUrl = url;
        _initialized = true;
        if (kDebugMode) {
          debugPrint('[ApiConfig] API reachable at $url');
        }
        return;
      }
    }

    if (await _probeHealth(remoteBaseUrl)) {
      _resolvedBaseUrl = remoteBaseUrl.replaceAll(RegExp(r'/+$'), '');
      _initialized = true;
      if (kDebugMode) {
        debugPrint(
          '[ApiConfig] Local API unreachable; using remote at $_resolvedBaseUrl',
        );
      }
      return;
    }

    _resolvedBaseUrl = candidates.first;
    _initialized = true;
    if (kDebugMode) {
      debugPrint(
        '[ApiConfig] No /health/ probe succeeded; defaulting to $_resolvedBaseUrl',
      );
    }
  }

  static Future<List<String>> _connectionCandidates() async {
    final seen = <String>{};
    final ordered = <String>[];

    void push(String host) {
      final url = 'http://$host:$port';
      if (seen.add(url)) ordered.add(url);
    }

    if (kIsWeb) {
      push('127.0.0.1');
      return ordered;
    }

    if (Platform.isAndroid) {
      try {
        final info = await DeviceInfoPlugin()
            .androidInfo
            .timeout(const Duration(seconds: 3));
        if (info.isPhysicalDevice) {
          // USB + adb reverse is the most reliable on a plugged-in phone.
          push('127.0.0.1');
          if (lanHost.isNotEmpty) {
            push(lanHost);
          }
        } else {
          push('10.0.2.2');
          push('127.0.0.1');
        }
      } catch (_) {
        push('127.0.0.1');
        if (lanHost.isNotEmpty) push(lanHost);
      }
    } else {
      push('127.0.0.1');
    }

    return ordered;
  }

  static Future<bool> _probeHealth(String baseUrl) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      final res = await dio.get('$baseUrl/health/');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
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

  /// Same host as [baseUrl]; socket_io_client uses http(s) + path `/socket.io/`.
  static String get socketUrl => baseUrl;

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
