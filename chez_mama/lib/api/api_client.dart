import 'package:dio/dio.dart';

import '../l10n/app_strings.dart';
import '../storage/token_storage.dart';
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
          final token = await TokenStorage.instance.readAccess();
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
            } else {
              await _invalidateSession();
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  void Function()? onSessionExpired;

  Dio get dio => _dio;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await TokenStorage.instance.write(access: access, refresh: refresh);
  }

  Future<void> clearTokens() async {
    await TokenStorage.instance.clear();
  }

  Future<bool> hasToken() async {
    return TokenStorage.instance.hasToken();
  }

  Future<void> _invalidateSession() async {
    await clearTokens();
    onSessionExpired?.call();
  }

  Future<bool> _tryRefresh() async {
    final refresh = await TokenStorage.instance.readRefresh();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: ApiConfig.apiUrl)).post(
        '/auth/token/refresh/',
        data: {'refresh': refresh},
      );
      final access = res.data['access'] as String?;
      if (access == null) return false;
      await TokenStorage.instance.write(access: access, refresh: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final token = await TokenStorage.instance.readAccess();
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
      return tr('error.network');
    }
    return error.message ?? tr('error.generic');
  }
  return error.toString();
}
