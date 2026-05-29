import 'dart:async';
import 'package:flutter/material.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../chat/chat_unread_notifier.dart';
import '../../l10n/app_strings.dart';
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

  List<String> get _titles => [
        tr('nav.home'),
        tr('nav.shorts'),
        tr('nav.videos'),
        tr('nav.tracking'),
        tr('nav.cart'),
      ];

  Timer? _badgeTimer;

  Future<void> _pickLanguage() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                tr('lang.choose'),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            for (final l in AppLang.values)
              ListTile(
                leading: Text(l.flag, style: const TextStyle(fontSize: 22)),
                title: Text(l.label),
                trailing: LocaleController.instance.lang == l
                    ? const Icon(Icons.check_circle_rounded,
                        color: ChezMamaTheme.brandOrange)
                    : null,
                onTap: () {
                  LocaleController.instance.setLang(l);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

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
                case 'language':
                  _pickLanguage();
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
                PopupMenuItem(
                  value: 'dashboard',
                  child: ListTile(
                    leading: const Icon(Icons.insights_rounded),
                    title: Text(tr('menu.dashboard')),
                  ),
                ),
                PopupMenuItem(
                  value: 'shop',
                  child: ListTile(
                    leading: const Icon(Icons.storefront_rounded),
                    title: Text(tr('menu.shop')),
                  ),
                ),
                PopupMenuItem(
                  value: 'publications',
                  child: ListTile(
                    leading: const Icon(Icons.video_library_rounded),
                    title: Text(tr('menu.publications')),
                  ),
                ),
                PopupMenuItem(
                  value: 'favorites',
                  child: ListTile(
                    leading: const Icon(Icons.favorite_rounded),
                    title: Text(tr('menu.favorites')),
                  ),
                ),
                PopupMenuItem(
                  value: 'messages',
                  child: ListTile(
                    leading: const Icon(Icons.forum_rounded),
                    title: Text(tr('menu.messages')),
                  ),
                ),
                PopupMenuItem(
                  value: 'loyalty',
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium_rounded),
                    title: Text(tr('menu.loyalty')),
                  ),
                ),
                PopupMenuItem(
                  value: 'language',
                  child: ListTile(
                    leading: const Icon(Icons.translate_rounded),
                    title: Text(tr('menu.language')),
                    trailing: Text(
                      LocaleController.instance.lang.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'theme',
                  child: ListTile(
                    leading: Icon(
                      dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    ),
                    title: Text(dark ? tr('menu.lightMode') : tr('menu.darkMode')),
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: const Icon(Icons.logout_rounded),
                    title: Text(tr('menu.logout')),
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

