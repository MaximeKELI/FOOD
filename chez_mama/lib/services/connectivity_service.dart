import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks online/offline state for a global banner.
class ConnectivityService extends ChangeNotifier {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _online = true;

  bool get isOnline => _online;

  Future<void> init() async {
    final results = await _connectivity.checkConnectivity();
    _online = _hasConnection(results);
    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final next = _hasConnection(results);
      if (next != _online) {
        _online = next;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );
  }

  void dispose() {
    _sub?.cancel();
  }
}
