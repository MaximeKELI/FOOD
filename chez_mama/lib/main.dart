import 'package:flutter/material.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_service.dart';
import 'analytics/event_tracker.dart';
import 'analytics/tracked_widgets.dart';
import 'l10n/app_strings.dart';
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
      child: AnimatedBuilder(
        animation: Listenable.merge(
          [ThemeController.instance, LocaleController.instance],
        ),
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Food',
            theme: ChezMamaTheme.light(),
            darkTheme: ChezMamaTheme.dark(),
            themeMode: ThemeController.instance.mode,
            navigatorObservers: [TrackedNavigatorObserver()],
            home: const AuthGate(),
          );
        },
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
    ThemeController.instance.load();
    LocaleController.instance.load();
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
