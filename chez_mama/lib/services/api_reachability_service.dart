import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_config.dart';

/// Pings the backend `/health/` endpoint so we can warn when the API is unreachable.
class ApiReachabilityService extends ChangeNotifier {
  ApiReachabilityService._();
  static final ApiReachabilityService instance = ApiReachabilityService._();

  bool _checking = false;
  bool _reachable = true;
  String? _lastError;

  bool get checking => _checking;
  bool get reachable => _reachable;
  String? get lastError => _lastError;

  Future<void> check() async {
    if (_checking) return;
    _checking = true;
    notifyListeners();
    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final res = await dio.get('/health/');
      _reachable = res.statusCode == 200;
      _lastError = null;
    } catch (e) {
      _reachable = false;
      _lastError = e.toString();
    } finally {
      _checking = false;
      notifyListeners();
    }
  }
}
