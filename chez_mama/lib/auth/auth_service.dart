import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static const _kIsAuthed = 'auth.isAuthed';
  static const _kUserName = 'auth.userName';
  static const _kEmail = 'auth.email';

  bool _ready = false;
  bool _isAuthed = false;
  String? _userName;
  String? _email;

  bool get ready => _ready;
  bool get isAuthed => _isAuthed;
  String? get userName => _userName;
  String? get email => _email;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthed = prefs.getBool(_kIsAuthed) ?? false;
    _userName = prefs.getString(_kUserName);
    _email = prefs.getString(_kEmail);
    _ready = true;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // Demo auth: replace with real backend/Firebase later.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final prefs = await SharedPreferences.getInstance();
    _isAuthed = true;
    _email = email.trim();
    _userName = _userName ?? 'Vendeur';
    await prefs.setBool(_kIsAuthed, true);
    await prefs.setString(_kEmail, _email!);
    await prefs.setString(_kUserName, _userName!);
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final prefs = await SharedPreferences.getInstance();
    _isAuthed = true;
    _userName = name.trim().isEmpty ? 'Vendeur' : name.trim();
    _email = email.trim();
    await prefs.setBool(_kIsAuthed, true);
    await prefs.setString(_kEmail, _email!);
    await prefs.setString(_kUserName, _userName!);
    notifyListeners();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthed = false;
    await prefs.setBool(_kIsAuthed, false);
    notifyListeners();
  }
}

