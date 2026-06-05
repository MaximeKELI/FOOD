import 'dart:io';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Collects device, location and environment data for analytics.
class DeviceContext {
  DeviceContext._();

  static final DeviceContext instance = DeviceContext._();

  static const _sessionKey = 'analytics_session_id';

  String? _sessionId;
  String? _platform;
  String? _deviceModel;
  String? _appVersion;

  Future<String> sessionId() async {
    if (_sessionId != null) return _sessionId!;
    final prefs = await SharedPreferences.getInstance();
    var stored = prefs.getString(_sessionKey);
    if (stored == null || stored.isEmpty) {
      stored = _newUuid();
      await prefs.setString(_sessionKey, stored);
    }
    _sessionId = stored;
    return stored;
  }

  static String _newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> warmUp() async {
    if (_platform != null) return;
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        _platform = 'android';
        _deviceModel = '${android.brand} ${android.model}';
        _appVersion = android.version.release;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        _platform = 'ios';
        _deviceModel = ios.utsname.machine;
        _appVersion = ios.systemVersion;
      } else if (Platform.isLinux) {
        final linux = await info.linuxInfo;
        _platform = 'linux';
        _deviceModel = linux.prettyName;
        _appVersion = linux.version ?? '';
      } else {
        _platform = Platform.operatingSystem;
        _deviceModel = 'unknown';
      }
    } catch (_) {
      _platform = Platform.operatingSystem;
    }
  }

  Future<Map<String, dynamic>> collect({
    BuildContext? context,
    LatLng? location,
  }) async {
    await warmUp();
    final sid = await sessionId();

    double? lat = location?.latitude;
    double? lng = location?.longitude;
    if (lat == null || lng == null) {
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      } catch (_) {}
    }

    String connectionType = 'unknown';
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isNotEmpty) {
        connectionType = results.first.name;
      }
    } catch (_) {}

    double? brightness;
    if (context != null && context.mounted) {
      final mode = MediaQuery.platformBrightnessOf(context);
      brightness = mode == Brightness.dark ? 0.25 : 0.85;
    }

    final now = DateTime.now();
    return {
      'session_id': sid,
      'latitude': lat,
      'longitude': lng,
      'device_time': now.toUtc().toIso8601String(),
      'timezone': now.timeZoneName,
      'brightness': brightness,
      'platform': _platform ?? Platform.operatingSystem,
      'device_model': _deviceModel ?? '',
      'app_version': _appVersion ?? '1.0.0',
      'connection_type': connectionType,
    };
  }
}
