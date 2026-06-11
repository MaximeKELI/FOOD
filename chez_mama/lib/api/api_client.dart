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

  /// Call after [ApiConfig.init] when the base URL was probed at runtime.
  void updateBaseUrl() {
    _dio.options.baseUrl = ApiConfig.apiUrl;
  }

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

/// Simple, user-facing message for API and network errors (never raw Dio text).
String apiErrorMessage(Object error) {
  if (error is! DioException) {
    return tr('error.generic');
  }

  if (isNetworkError(error)) {
    return tr('error.network');
  }

  final status = error.response?.statusCode;
  if (status != null) {
    if (status >= 500) return tr('error.serverUnavailable');
    if (status == 401) {
      return _apiDetailOr(error, tr('error.unauthorized'));
    }
    if (status == 403) {
      return _apiDetailOr(error, tr('error.forbidden'));
    }
    if (status == 404) return tr('error.notFound');
    if (status >= 400) {
      final detail = _extractApiDetail(error.response?.data);
      if (detail != null) return detail;
    }
  }

  final detail = _extractApiDetail(error.response?.data);
  if (detail != null) return detail;

  return tr('error.generic');
}

String _apiDetailOr(DioException error, String fallback) {
  final detail = _extractApiDetail(error.response?.data);
  if (detail != null) return detail;
  return fallback;
}

String? _extractApiDetail(Object? data) {
  if (data is! Map) return null;

  final detail = data['detail'];
  if (detail != null) {
    final text = detail.toString().trim();
    if (text.isNotEmpty && !_looksTechnical(text)) return text;
  }

  for (final value in data.values) {
    if (value is List && value.isNotEmpty) {
      final text = value.first.toString().trim();
      if (text.isNotEmpty && !_looksTechnical(text)) return text;
    }
    if (value is String && value.isNotEmpty && !_looksTechnical(value)) {
      return value;
    }
  }

  return null;
}

bool _looksTechnical(String message) {
  final lower = message.toLowerCase();
  return lower.contains('dioexception') ||
      lower.contains('socketexception') ||
      lower.contains('connection refused') ||
      lower.contains('connection errored') ||
      lower.contains('connection reset') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('errno') ||
      lower.contains('os error') ||
      lower.contains('handshake exception');
}

bool isNetworkError(Object error) {
  if (error is! DioException) return false;
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return true;
    case DioExceptionType.unknown:
      final inner = error.error?.toString().toLowerCase() ?? '';
      return inner.contains('socket') ||
          inner.contains('connection') ||
          inner.contains('network') ||
          inner.contains('host lookup');
    default:
      return false;
  }
}

/// @deprecated Use [apiErrorMessage] — kept for call sites not yet migrated.
String networkErrorDetail() => tr('error.network');
