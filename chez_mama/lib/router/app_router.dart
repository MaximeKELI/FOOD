import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/bootstrap_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/cart/orders_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/profile/seller_dashboard_screen.dart';
import '../screens/shell/app_shell.dart';
import '../navigation/root_navigator.dart';
import '../screens/splash/splash_screen.dart';

/// GoRouter instance is created once; [refreshListenable] re-runs [redirect]
/// without resetting navigation (recreating GoRouter was causing an infinite splash).
final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authServiceProvider);
  final bootstrap = ref.read(bootstrapProvider);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: Listenable.merge([auth, bootstrap]),
    redirect: (context, state) {
      final boot = ref.read(bootstrapProvider);
      final authSvc = ref.read(authServiceProvider);
      final loc = state.matchedLocation;

      if (!boot.done) {
        return loc == '/' ? null : '/';
      }

      if (loc == '/') {
        return boot.onboardingComplete ? '/home' : '/onboarding';
      }

      if (!authSvc.ready) return null;

      final loggingIn = loc == '/login';
      if (!authSvc.isAuthed && loc.startsWith('/vendor') && !loggingIn) {
        return '/login?from=${Uri.encodeComponent(loc)}';
      }
      if (!authSvc.isAuthed && loc == '/checkout') {
        return '/login?from=${Uri.encodeComponent('/checkout')}';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const AppShell(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) {
          final from = state.uri.queryParameters['from'];
          return LoginScreen(redirectAfterLogin: from);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, __) => CartScreen(
          onSeeOrders: () => context.push('/orders'),
        ),
      ),
      GoRoute(
        path: '/orders',
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, __) => CartScreen(
          onSeeOrders: () => context.push('/orders'),
        ),
      ),
      GoRoute(
        path: '/vendor',
        builder: (_, __) => const SellerDashboardScreen(),
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (_, __) => const SellerDashboardScreen(),
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
