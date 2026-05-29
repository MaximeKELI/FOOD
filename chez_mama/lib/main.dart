import 'package:flutter/material.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_service.dart';
import 'analytics/event_tracker.dart';
import 'analytics/tracked_widgets.dart';
import 'ui/chezmama_theme.dart';
import 'ui/theme_controller.dart';
import 'screens/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChezMamaApp());
}

class ChezMamaApp extends StatelessWidget {
  const ChezMamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _AuthBootstrap(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Food',
        theme: ChezMamaTheme.light(),
        navigatorObservers: [TrackedNavigatorObserver()],
        home: const AuthGate(),
      ),
    );
  }
}

class _AuthBootstrap extends StatefulWidget {
  const _AuthBootstrap({required this.child});
  final Widget child;

  @override
  State<_AuthBootstrap> createState() => _AuthBootstrapState();
}

class _AuthBootstrapState extends State<_AuthBootstrap> {
  final service = AuthService();

  @override
  void initState() {
    super.initState();
    EventTracker.instance.init();
    service.init();
  }

  @override
  void dispose() {
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(service: service, child: widget.child);
  }
}
