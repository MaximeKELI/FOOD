import 'package:flutter/foundation.dart';

import '../api/notifications_api.dart';

class NotificationsNotifier extends ChangeNotifier {
  NotificationsNotifier._();
  static final NotificationsNotifier instance = NotificationsNotifier._();

  int _unread = 0;
  int get unread => _unread;

  Future<void> refresh() async {
    try {
      final res = await NotificationsApi.instance.fetch();
      _unread = res.unread;
      notifyListeners();
    } catch (_) {
      // Ignore (offline / not logged in).
    }
  }

  void clear() {
    _unread = 0;
    notifyListeners();
  }

  /// Optimistic update when one notification is opened locally.
  void markOneReadLocally() {
    if (_unread > 0) {
      _unread -= 1;
      notifyListeners();
    }
  }
}
