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
import '../../widgets/shell_toolbar_actions.dart';
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
import '../cart/orders_screen.dart';
import '../auth/login_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = AuthScope.of(context);
      if (auth.isAuthed) {
        ReceivedOrdersNotifier.instance.refresh();
        NotificationsNotifier.instance.refresh();
        ChatUnreadNotifier.instance.refresh();
      }
    });
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (!AuthScope.of(context).isAuthed) return;
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

  void _handleMenu(String value) {
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
        ThemeController.instance.toggleDark(!ThemeController.instance.isDark);
      case 'logout':
        _logout();
    }
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

  Widget _buildPage(int i, bool isSeller) {
    switch (i) {
      case 0:
        return HomeScreen(
          isSeller: isSeller,
          onNotifications: () => _go(const NotificationsScreen()),
          onMessages: () => _go(const ConversationsScreen()),
          onReceivedOrders: () => _go(const ReceivedOrdersScreen()),
          onMenuSelected: _handleMenu,
          onPickLanguage: _pickLanguage,
        );
      case 1:
        return const ShortsScreen();
      case 2:
        return const VideosScreen();
      case 3:
        return const TrackingScreen();
      case 4:
        return CartScreen(
          onSeeOrders: () => _go(const OrdersScreen()),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = ChezMamaTheme.cardColor(context);
    final auth = AuthScope.of(context);
    final isSeller = auth.isSeller;
    final showShellAppBar = index != 0;

    return Scaffold(
      appBar: showShellAppBar
          ? AppBar(
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
                if (index == 4)
                  IconButton(
                    tooltip: 'Mes commandes',
                    onPressed: () => _go(const OrdersScreen()),
                    icon: const Icon(Icons.receipt_long_rounded),
                  ),
                ShellToolbarActions(
                  isSeller: isSeller,
                  onNotifications: () => _go(const NotificationsScreen()),
                  onMessages: () => _go(const ConversationsScreen()),
                  onReceivedOrders: () => _go(const ReceivedOrdersScreen()),
                  onMenuSelected: _handleMenu,
                  onPickLanguage: _pickLanguage,
                ),
              ],
            )
          : null,
      body: AnimatedBuilder(
        animation: auth,
        builder: (context, _) {
          return AnimatedSwitcher(
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
              key: ValueKey('$index-${auth.isSeller}'),
              child: _buildPage(index, auth.isSeller),
            ),
          );
        },
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
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.home_rounded),
                      label: tr('nav.home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.bolt_rounded),
                      label: tr('nav.shorts'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.videocam_rounded),
                      label: tr('nav.videos'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Icon(Icons.delivery_dining_rounded),
                      label: tr('nav.tracking'),
                    ),
                    BottomNavigationBarItem(
                      icon: count > 0
                          ? Badge.count(
                              count: count,
                              child: const Icon(Icons.shopping_bag_rounded),
                            )
                          : const Icon(Icons.shopping_bag_rounded),
                      label: tr('nav.cart'),
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
