import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_service.dart';
import 'analytics/event_tracker.dart';
import 'analytics/tracked_widgets.dart';
import 'cart/cart_service.dart';
import 'l10n/app_strings.dart';
import 'services/connectivity_service.dart';
import 'services/deep_link_service.dart';
import 'ui/chezmama_theme.dart';
import 'ui/theme_controller.dart';
import 'notifications/push_service.dart';
import 'navigation/root_navigator.dart';
import 'payments/payment_pending_service.dart';
import 'widgets/offline_banner_host.dart';
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
            navigatorKey: rootNavigatorKey,
            debugShowCheckedModeBanner: false,
            title: tr('app.name'),
            locale: LocaleController.instance.locale,
            supportedLocales: AppLang.values.map((l) => Locale(l.code)),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ChezMamaTheme.light(),
            darkTheme: ChezMamaTheme.dark(),
            themeMode: ThemeController.instance.mode,
            navigatorObservers: [TrackedNavigatorObserver()],
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final scale = mq.textScaler.scale(1).clamp(0.85, 1.35);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(scale)),
                child: OfflineBannerHost(child: child ?? const SizedBox.shrink()),
              );
            },
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
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    EventTracker.instance.init();
    ThemeController.instance.load();
    LocaleController.instance.load();
    PushService.instance.init();
    CartService.instance.init();
    ConnectivityService.instance.init();
    DeepLinkService.instance.init();
    service.init();
    _lifecycle = AppLifecycleListener(
      onResume: () => PaymentPendingService.instance.onAppResume(),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    ConnectivityService.instance.dispose();
    service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(service: service, child: widget.child);
  }
}
