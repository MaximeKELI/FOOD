import 'package:flutter/foundation.dart';

import '../api/orders_api.dart';

/// Tracks the number of "active" received orders so the shell can show a badge.
class ReceivedOrdersNotifier extends ChangeNotifier {
  ReceivedOrdersNotifier._();
  static final ReceivedOrdersNotifier instance = ReceivedOrdersNotifier._();

  static const _activeStatuses = {'pending', 'preparing', 'on_the_way'};

  int _activeCount = 0;
  int get activeCount => _activeCount;

  Future<void> refresh() async {
    try {
      final orders = await OrdersApi.instance.fetchReceivedOrders();
      _activeCount =
          orders.where((o) => _activeStatuses.contains(o.status)).length;
      notifyListeners();
    } catch (_) {
      // Silently ignore (e.g. not logged in / offline): keep previous value.
    }
  }

  void clear() {
    _activeCount = 0;
    notifyListeners();
  }
}
