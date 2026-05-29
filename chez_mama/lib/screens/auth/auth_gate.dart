import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../splash/splash_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);

    if (!auth.ready) {
      return const SplashScreen();
    }

    // Guest browse: splash then AppShell for everyone.
    return const SplashScreen();
  }
}
