import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_config.dart';

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
          final token = await _storage.read(key: _kAccess);
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

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  Dio get dio => _dio;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _kAccess);
    return token != null && token.isNotEmpty;
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _storage.read(key: _kRefresh);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: ApiConfig.apiUrl)).post(
        '/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final access = res.data['access'] as String?;
      if (access == null) return false;
      await _storage.write(key: _kAccess, value: access);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await _storage.read(key: _kAccess);
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
      // First field error
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
