import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/auth/login_screen.dart';
import 'auth_scope.dart';

/// Returns true if the user is authenticated; otherwise opens [LoginScreen].
Future<bool> requireAuth(BuildContext context) async {
  if (AuthScope.of(context).isAuthed) return true;
  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  if (!context.mounted) return false;
  return AuthScope.of(context).isAuthed;
}

/// SnackBar helper when an action needs login.
void showLoginRequiredSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(tr('auth.loginRequiredAction'))),
  );
}
