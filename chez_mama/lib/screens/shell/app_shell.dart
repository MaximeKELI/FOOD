import 'dart:async';
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../chat/chat_unread_notifier.dart';
import '../../notifications/notifications_notifier.dart';
import '../../ui/chezmama_theme.dart';
import '../../ui/theme_controller.dart';
import '../home/home_screen.dart';
import '../social/shorts_screen.dart';
import '../social/videos_screen.dart';
import '../cart/cart_screen.dart';
import '../chat/conversations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/favorite_meals_screen.dart';
import '../profile/loyalty_screen.dart';
import '../profile/seller_dashboard_screen.dart';
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

  static const _titles = ['Accueil', 'Shorts', 'Vidéos', 'Suivi', 'Panier'];

  Timer? _badgeTimer;

  @override
  void initState() {
    super.initState();
    ReceivedOrdersNotifier.instance.refresh();
    NotificationsNotifier.instance.refresh();
    ChatUnreadNotifier.instance.refresh();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        ReceivedOrdersNotifier.instance.refresh();
        NotificationsNotifier.instance.refresh();
        ChatUnreadNotifier.instance.refresh();
      },
    );
  }

  void _go(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen)).then(
      (_) {
        ReceivedOrdersNotifier.instance.refresh();
        NotificationsNotifier.instance.refresh();
        ChatUnreadNotifier.instance.refresh();
      },
    );
  }

  Future<void> _logout() async {
    await AuthScope.of(context).signOut();
    if (!mounted) return;
    ReceivedOrdersNotifier.instance.clear();
    NotificationsNotifier.instance.clear();
    ChatUnreadNotifier.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = ChezMamaTheme.cardColor(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: ChezMamaTheme.brandOrange.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.restaurant_rounded,
                size: 18,
                color: ChezMamaTheme.brandOrange,
              ),
            ),
            const SizedBox(width: 10),
            Text(_titles[index]),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: NotificationsNotifier.instance,
            builder: (context, _) {
              final count = NotificationsNotifier.instance.unread;
              return IconButton(
                tooltip: 'Notifications',
                onPressed: () => _go(const NotificationsScreen()),
                icon: count > 0
                    ? Badge.count(
                        count: count,
                        child: const Icon(Icons.notifications_rounded),
                      )
                    : const Icon(Icons.notifications_none_rounded),
              );
            },
          ),
          AnimatedBuilder(
            animation: ChatUnreadNotifier.instance,
            builder: (context, _) {
              final count = ChatUnreadNotifier.instance.unread;
              return IconButton(
                tooltip: 'Messages',
                onPressed: () => _go(const ConversationsScreen()),
                icon: count > 0
                    ? Badge.count(
                        count: count,
                        child: const Icon(Icons.chat_bubble_rounded),
                      )
                    : const Icon(Icons.chat_bubble_outline_rounded),
              );
            },
          ),
          AnimatedBuilder(
            animation: ReceivedOrdersNotifier.instance,
            builder: (context, _) {
              final count = ReceivedOrdersNotifier.instance.activeCount;
              return IconButton(
                tooltip: 'Commandes reçues',
                onPressed: () => _go(const ReceivedOrdersScreen()),
                icon: count > 0
                    ? Badge.count(
                        count: count,
                        child: const Icon(Icons.inbox_rounded),
                      )
                    : const Icon(Icons.inbox_rounded),
              );
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(Icons.menu_rounded),
            onSelected: (value) {
              switch (value) {
                case 'dashboard':
                  _go(const SellerDashboardScreen());
                case 'shop':
                  _go(const MyShopScreen());
                case 'publications':
                  _go(const MyPublicationsScreen());
                case 'favorites':
                  _go(const FavoriteMealsScreen());
                case 'loyalty':
                  _go(const LoyaltyScreen());
                case 'messages':
                  _go(const ConversationsScreen());
                case 'theme':
                  ThemeController.instance
                      .toggleDark(!ThemeController.instance.isDark);
                case 'logout':
                  _logout();
              }
            },
            itemBuilder: (context) {
              final dark = ThemeController.instance.isDark;
              return [
                const PopupMenuItem(
                  value: 'dashboard',
                  child: ListTile(
                    leading: Icon(Icons.insights_rounded),
                    title: Text('Tableau de bord'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'shop',
                  child: ListTile(
                    leading: Icon(Icons.storefront_rounded),
                    title: Text('Ma boutique'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'publications',
                  child: ListTile(
                    leading: Icon(Icons.video_library_rounded),
                    title: Text('Mes publications'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'favorites',
                  child: ListTile(
                    leading: Icon(Icons.favorite_rounded),
                    title: Text('Mes favoris'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'messages',
                  child: ListTile(
                    leading: Icon(Icons.forum_rounded),
                    title: Text('Messages'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'loyalty',
                  child: ListTile(
                    leading: Icon(Icons.workspace_premium_rounded),
                    title: Text('Mes points'),
                  ),
                ),
                PopupMenuItem(
                  value: 'theme',
                  child: ListTile(
                    leading: Icon(
                      dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    ),
                    title: Text(dark ? 'Mode clair' : 'Mode sombre'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Déconnexion'),
                  ),
                ),
              ];
            },
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AnimatedBuilder(
              animation: CartService.instance,
              builder: (context, _) {
                final count = CartService.instance.count;
                return BottomNavigationBar(
                  currentIndex: index,
                  onTap: (v) => setState(() => index = v),
                  backgroundColor: cardColor,
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: 'Accueil',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.bolt_rounded),
                      label: 'Shorts',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.videocam_rounded),
                      label: 'Vidéos',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.delivery_dining_rounded),
                      label: 'Suivi',
                    ),
                    BottomNavigationBarItem(
                      icon: count > 0
                          ? Badge.count(
                              count: count,
                              child: const Icon(Icons.shopping_bag_rounded),
                            )
                          : const Icon(Icons.shopping_bag_rounded),
                      label: 'Panier',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

