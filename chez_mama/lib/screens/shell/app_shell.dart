import 'dart:async';
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../notifications/notifications_notifier.dart';
import '../../ui/chezmama_theme.dart';
import '../home/home_screen.dart';
import '../social/shorts_screen.dart';
import '../social/videos_screen.dart';
import '../cart/cart_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/favorite_meals_screen.dart';
import '../profile/my_publications_screen.dart';
import '../profile/my_shop_screen.dart';
import '../profile/received_orders_screen.dart';
import '../tracking/tracking_screen.dart';
import '../auth/login_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  final pages = const [
    HomeScreen(),
    ShortsScreen(),
    VideosScreen(),
    TrackingScreen(),
    CartScreen(),
  ];

  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    ReceivedOrdersNotifier.instance.refresh();
    NotificationsNotifier.instance.refresh();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        ReceivedOrdersNotifier.instance.refresh();
        NotificationsNotifier.instance.refresh();
      },
    );
  }

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then(
      (_) {
        ReceivedOrdersNotifier.instance.refresh();
        NotificationsNotifier.instance.refresh();
      },
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food'),
        actions: [
          IconButton(
            tooltip: 'Ma boutique',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyShopScreen()),
            ),
            icon: const Icon(Icons.storefront_rounded),
          ),
          IconButton(
            tooltip: 'Mes publications',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyPublicationsScreen()),
            ),
            icon: const Icon(Icons.video_library_rounded),
          ),
          AnimatedBuilder(
            animation: ReceivedOrdersNotifier.instance,
            builder: (context, _) {
              final count = ReceivedOrdersNotifier.instance.activeCount;
              return IconButton(
                tooltip: 'Commandes reçues',
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReceivedOrdersScreen(),
                    ),
                  );
                  ReceivedOrdersNotifier.instance.refresh();
                },
                icon: count > 0
                    ? Badge.count(
                        count: count,
                        child: const Icon(Icons.inbox_rounded),
                      )
                    : const Icon(Icons.inbox_rounded),
              );
            },
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () async {
              await AuthScope.of(context).signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, a) {
          final fade = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(fade),
              child: child,
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(index),
          child: pages[index],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: CartService.instance,
        builder: (context, _) {
          final count = CartService.instance.count;
          return FloatingActionButton.extended(
            heroTag: 'fab_cart',
            onPressed: () => setState(() => index = 4),
            backgroundColor: ChezMamaTheme.brandOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            icon: const Icon(Icons.shopping_bag_rounded),
            label: Text(count > 0 ? 'Panier ($count)' : 'Panier'),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BottomNavigationBar(
              currentIndex: index,
              onTap: (v) => setState(() => index = v),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bolt_rounded),
                  label: 'Shorts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.videocam_rounded),
                  label: 'Vidéos',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.delivery_dining_rounded),
                  label: 'Suivi',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.shopping_bag_rounded),
                  label: 'Panier',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

