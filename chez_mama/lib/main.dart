import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'analytics/event_tracker.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_service.dart';
import 'cart/cart_service.dart';
import 'l10n/app_strings.dart';
import 'notifications/push_service.dart';
import 'payments/payment_pending_service.dart';
import 'services/weather_nudge_service.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/api_reachability_service.dart';
import 'services/connectivity_service.dart';
import 'services/deep_link_service.dart';
import 'ui/chezmama_theme.dart';
import 'ui/theme_controller.dart';
import 'widgets/offline_banner_host.dart';

late final AuthService _authService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.merchantIdentifier = 'merchant.com.chez_mama';
  await ApiConfig.init();
  ApiClient.instance.updateBaseUrl();
  _authService = AuthService();
  runApp(
    ProviderScope(
      overrides: [authServiceProvider.overrideWithValue(_authService)],
      child: const ChezMamaApp(),
    ),
  );
}

class ChezMamaApp extends ConsumerStatefulWidget {
  const ChezMamaApp({super.key});

  @override
  ConsumerState<ChezMamaApp> createState() => _ChezMamaAppState();
}

class _ChezMamaAppState extends ConsumerState<ChezMamaApp> {
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    EventTracker.instance.init();
    ThemeController.instance.load();
    LocaleController.instance.load();
    PushService.instance.init();
    WeatherNudgeService.instance.init();
    CartService.instance.init();
    ConnectivityService.instance.init();
    DeepLinkService.instance.init();
    ApiReachabilityService.instance.check();
    _authService.init();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        PaymentPendingService.instance.onAppResume();
        WeatherNudgeService.instance.maybeNotify(auth: _authService);
        ApiReachabilityService.instance.check();
      },
    );
    WeatherNudgeService.instance.maybeNotify(auth: _authService);
    WeatherNudgeService.instance.startPeriodicChecks(auth: _authService);
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    WeatherNudgeService.instance.stopPeriodicChecks();
    ConnectivityService.instance.dispose();
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return AuthScope(
      service: _authService,
      child: AnimatedBuilder(
        animation: Listenable.merge(
          [ThemeController.instance, LocaleController.instance],
        ),
        builder: (context, _) {
          return MaterialApp.router(
            routerConfig: router,
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
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final scale = mq.textScaler.scale(1).clamp(0.85, 1.35);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(scale)),
                child: OfflineBannerHost(
                  child: child ?? const SizedBox.shrink(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
