import 'package:flutter/foundation.dart';

import '../api/chat_api.dart';

/// Tracks the number of unread chat messages so the shell can show a badge.
class ChatUnreadNotifier extends ChangeNotifier {
  ChatUnreadNotifier._();
  static final ChatUnreadNotifier instance = ChatUnreadNotifier._();

  int _unread = 0;
  int get unread => _unread;

  Future<void> refresh() async {
    try {
      _unread = await ChatApi.instance.unreadCount();
      notifyListeners();
    } catch (_) {
      // Ignore transient errors.
    }
  }

  void clear() {
    _unread = 0;
    notifyListeners();
  }
}
