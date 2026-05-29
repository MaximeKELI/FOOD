import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../navigation/root_navigator.dart';
import '../screens/auth/login_screen.dart';

/// Shows session-expired UX when JWT refresh fails.
class SessionHandler {
  SessionHandler._();
  static final SessionHandler instance = SessionHandler._();

  bool _dialogVisible = false;

  void onSessionExpired() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || _dialogVisible) return;
    _dialogVisible = true;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text(tr('auth.sessionExpiredTitle')),
        content: Text(tr('auth.sessionExpiredBody')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _dialogVisible = false;
            },
            child: Text(tr('action.continueGuest')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              _dialogVisible = false;
              Navigator.of(ctx).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(tr('auth.login')),
          ),
        ],
      ),
    ).then((_) => _dialogVisible = false);
  }
}
