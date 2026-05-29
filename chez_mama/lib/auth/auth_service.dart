import 'package:flutter/foundation.dart';

import '../api/api_client.dart';

/// Authenticates against the Django backend and keeps the session in memory.
/// Tokens are persisted securely by [ApiClient].
class AuthService extends ChangeNotifier {
  bool _ready = false;
  bool _isAuthed = false;
  int? _userId;
  String? _userName;
  String? _email;
  int _loyaltyPoints = 0;
  int _mealsCount = 0;
  bool _isSeller = false;

  bool get ready => _ready;
  bool get isAuthed => _isAuthed;
  int? get userId => _userId;
  String? get userName => _userName;
  String? get email => _email;
  int get loyaltyPoints => _loyaltyPoints;
  int get mealsCount => _mealsCount;
  bool get isSeller => _isSeller;

  final _client = ApiClient.instance;

  Future<void> init() async {
    try {
      if (await _client.hasToken()) {
        await _loadMe();
        _isAuthed = true;
      }
    } catch (_) {
      // Token invalid or server unreachable: stay logged out.
      _isAuthed = false;
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _loadMe() async {
    final res = await _client.dio.get('/auth/me/');
    final data = res.data as Map<String, dynamic>;
    _userId = data['id'] as int?;
    _userName = (data['name'] ?? data['display_name']) as String?;
    _email = data['email'] as String?;
    _loyaltyPoints = data['loyalty_points'] as int? ?? 0;
    _mealsCount = data['meals_count'] as int? ?? 0;
    final profile = data['seller_profile'] as Map<String, dynamic>?;
    final shopName = profile?['shop_name'] as String? ?? '';
    _isSeller = _mealsCount > 0 || shopName.trim().isNotEmpty;
  }

  /// Re-fetches the current user (e.g. to refresh loyalty points).
  Future<void> refreshMe() async {
    try {
      await _loadMe();
      notifyListeners();
    } catch (_) {
      // ignore transient errors
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.dio.post(
      '/auth/login/',
      data: {'email': email.trim(), 'password': password},
    );
    await _client.saveTokens(
      access: res.data['access'] as String,
      refresh: res.data['refresh'] as String,
    );
    await _loadMe();
    _isAuthed = true;
    notifyListeners();
  }

  /// Registers a new seller. [profile] carries the optional business fields
  /// matching the backend RegisterSerializer (snake_case keys).
  Future<void> register({
    required String name,
    required String email,
    required String password,
    Map<String, dynamic>? profile,
  }) async {
    final payload = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'name': name.trim(),
      ...?profile,
    };
    final res = await _client.dio.post('/auth/register/', data: payload);
    final tokens = res.data['tokens'] as Map<String, dynamic>;
    await _client.saveTokens(
      access: tokens['access'] as String,
      refresh: tokens['refresh'] as String,
    );
    final user = res.data['user'] as Map<String, dynamic>;
    _userId = user['id'] as int?;
    _userName = (user['name'] ?? user['display_name']) as String?;
    _email = user['email'] as String?;
    _mealsCount = user['meals_count'] as int? ?? 0;
    final sellerProfile = user['seller_profile'] as Map<String, dynamic>?;
    final shopName = sellerProfile?['shop_name'] as String? ?? '';
    _isSeller = _mealsCount > 0 || shopName.trim().isNotEmpty;
    _isAuthed = true;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _client.clearTokens();
    _isAuthed = false;
    _userId = null;
    _userName = null;
    _email = null;
    _loyaltyPoints = 0;
    _mealsCount = 0;
    _isSeller = false;
    notifyListeners();
  }
}
