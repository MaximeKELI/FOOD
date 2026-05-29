import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

bool get _useSecureStorage {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
}

/// Thin wrapper around Dio that injects the JWT access token and
/// transparently refreshes it on a 401 response.
class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _readAccess();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final response = error.response;
          final isAuthEndpoint =
              error.requestOptions.path.contains('/auth/login') ||
                  error.requestOptions.path.contains('/auth/token/refresh');
          if (response?.statusCode == 401 && !isAuthEndpoint) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              try {
                final clone = await _retry(error.requestOptions);
                return handler.resolve(clone);
              } catch (_) {
                // fall through
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  static const _kAccess = 'auth.access';
  static const _kRefresh = 'auth.refresh';
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  late final Dio _dio;

  Dio get dio => _dio;

  Future<String?> _read(String key) async {
    if (_useSecureStorage) return _secure.read(key: key);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _write(String key, String value) async {
    if (_useSecureStorage) {
      await _secure.write(key: key, value: value);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _delete(String key) async {
    if (_useSecureStorage) {
      await _secure.delete(key: key);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<String?> _readAccess() => _read(_kAccess);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _write(_kAccess, access);
    await _write(_kRefresh, refresh);
  }

  Future<void> clearTokens() async {
    await _delete(_kAccess);
    await _delete(_kRefresh);
  }

  Future<bool> hasToken() async {
    final token = await _readAccess();
    return token != null && token.isNotEmpty;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _read(_kRefresh);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: ApiConfig.apiUrl)).post(
        '/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final access = res.data['access'] as String?;
      if (access == null) return false;
      await _write(_kAccess, access);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _readAccess();
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

/// Extracts a human-readable message from a Dio error / API response.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      for (final value in data.values) {
        if (value is List && value.isNotEmpty) return value.first.toString();
        if (value is String && value.isNotEmpty) return value;
      }
      final first = data.values.first;
      if (first is List && first.isNotEmpty) return first.first.toString();
      return first.toString();
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Impossible de joindre le serveur. Vérifie ta connexion.';
    }
    return error.message ?? 'Erreur réseau';
  }
  return error.toString();
}
