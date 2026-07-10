import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_fly_service.dart';
import '../../cart/cart_service.dart';
import '../../cart/received_orders_notifier.dart';
import '../../chat/chat_unread_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../notifications/notifications_notifier.dart';
import '../../providers/auth_provider.dart';
import '../../ui/chezmama_theme.dart';
import '../../ui/theme_controller.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/cart_nav_icon.dart';
import '../../widgets/shell_toolbar_actions.dart';
import '../home/home_screen.dart';
import '../social/shorts_screen.dart';
import '../social/videos_screen.dart';
import '../cart/cart_screen.dart';
import '../cart/group_order_screen.dart';
import '../chat/conversations_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/favorite_meals_screen.dart';
import '../profile/delete_account_screen.dart';
import '../profile/loyalty_screen.dart';
import '../profile/my_publications_screen.dart';
import '../profile/my_shop_screen.dart';
import '../profile/received_orders_screen.dart';
import '../profile/addresses_screen.dart';
import '../profile/referral_screen.dart';
import '../profile/seller_promos_screen.dart';
import '../profile/seller_shop_settings_screen.dart';
import '../help/faq_screen.dart';
import '../orders/disputes_screen.dart';
import '../driver/driver_home_screen.dart';
import '../tracking/tracking_screen.dart';
import '../cart/orders_screen.dart';
import '../auth/login_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int get index => ref.watch(shellTabIndexProvider);
  set index(int value) => ref.read(shellTabIndexProvider.notifier).state = value;

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
        if (!mounted) return;
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
        if (!mounted) return;
        if (!AuthScope.of(context).isAuthed) return;
        ReceivedOrdersNotifier.instance.refresh();
        NotificationsNotifier.instance.refresh();
        ChatUnreadNotifier.instance.refresh();
      },
    );
  }

  void _requireAuth(VoidCallback action) {
    if (!AuthScope.of(context).isAuthed) {
      _go(const LoginScreen());
      return;
    }
    action();
  }

  void _handleMenu(String value) {
    if (value == 'login') {
      _go(const LoginScreen());
      return;
    }
    if (!AuthScope.of(context).isAuthed &&
        value != 'theme' &&
        value != 'language') {
      _go(const LoginScreen());
      return;
    }
    switch (value) {
      case 'dashboard':
        context.push('/vendor');
        return;
      case 'shop':
        _go(const MyShopScreen());
      case 'publications':
        _go(const MyPublicationsScreen());
      case 'favorites':
        _go(const FavoriteMealsScreen());
      case 'loyalty':
        _go(const LoyaltyScreen());
      case 'faq':
        _go(const FaqScreen());
      case 'addresses':
        _go(const AddressesScreen());
      case 'referral':
        _go(const ReferralScreen());
      case 'disputes':
        _go(const DisputesScreen());
      case 'driver':
        _go(const DriverHomeScreen());
      case 'promos':
        _go(const SellerPromosScreen());
      case 'shopSettings':
        _go(const SellerShopSettingsScreen());
      case 'groupOrder':
        _go(const GroupOrderScreen());
      case 'deleteAccount':
        _go(const DeleteAccountScreen());
      case 'messages':
        _go(const ConversationsScreen());
      case 'theme':
        ThemeController.instance.toggleDark(context);
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
    ref.read(shellTabIndexProvider.notifier).state = 0;
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  Widget _buildPage(int i, bool isSeller, bool isAuthed) {
    switch (i) {
      case 0:
        return HomeScreen(
          isSeller: isSeller,
          isAuthed: isAuthed,
          onNotifications: () => _requireAuth(() => _go(const NotificationsScreen())),
          onMessages: () => _requireAuth(() => _go(const ConversationsScreen())),
          onReceivedOrders: () => _go(const ReceivedOrdersScreen()),
          onMenuSelected: _handleMenu,
          onPickLanguage: _pickLanguage,
          onLogin: () => _go(const LoginScreen()),
        );
      case 1:
        return const ShortsScreen();
      case 2:
        return const VideosScreen();
      case 3:
        return const TrackingScreen();
      case 4:
        return CartScreen(
          onSeeOrders: isAuthed
              ? () => _go(const OrdersScreen())
              : () => _go(const LoginScreen()),
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
    final isAuthed = auth.isAuthed;
    final showShellAppBar = index != 0;

    return Scaffold(
      appBar: showShellAppBar
          ? AppBar(
              titleSpacing: 16,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 30, radius: 9, spin: true),
                  const SizedBox(width: 10),
                  Text(_titles[index]),
                ],
              ),
              actions: [
                if (index == 4 && isAuthed)
                  IconButton(
                    tooltip: tr('cart.orders'),
                    onPressed: () => _go(const OrdersScreen()),
                    icon: const Icon(Icons.receipt_long_rounded),
                  ),
                ShellToolbarActions(
                  isSeller: isSeller,
                  isAuthed: isAuthed,
                  onNotifications: () => _requireAuth(() => _go(const NotificationsScreen())),
                  onMessages: () => _requireAuth(() => _go(const ConversationsScreen())),
                  onReceivedOrders: () => _go(const ReceivedOrdersScreen()),
                  onMenuSelected: _handleMenu,
                  onPickLanguage: _pickLanguage,
                  onLogin: () => _go(const LoginScreen()),
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
              key: ValueKey('$index-${auth.isSeller}-${auth.isAuthed}'),
              child: _buildPage(index, auth.isSeller, auth.isAuthed),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(
            ChezMamaTheme.spaceMd,
            0,
            ChezMamaTheme.spaceMd,
            12,
          ),
          decoration: ChezMamaTheme.cardDecoration(
            context,
            radius: 22,
            shadowOpacity: 0.12,
            border: Border.all(
              color: ChezMamaTheme.brandOrange.withValues(alpha: 0.08),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                CartService.instance,
                CartFlyService.instance,
              ]),
              builder: (context, _) {
                final count = CartService.instance.count;
                final bounce = CartFlyService.instance.bounceGeneration;
                return NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (v) {
                    ref.read(shellTabIndexProvider.notifier).state = v;
                  },
                  backgroundColor: cardColor,
                  indicatorColor: ChezMamaTheme.brandOrange.withValues(alpha: 0.14),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      selectedIcon: const Icon(Icons.home_rounded),
                      label: tr('nav.home'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.bolt_outlined),
                      selectedIcon: const Icon(Icons.bolt_rounded),
                      label: tr('nav.shorts'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.videocam_outlined),
                      selectedIcon: const Icon(Icons.videocam_rounded),
                      label: tr('nav.videos'),
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.delivery_dining_outlined),
                      selectedIcon: const Icon(Icons.delivery_dining_rounded),
                      label: tr('nav.tracking'),
                    ),
                    NavigationDestination(
                      icon: CartNavIcon(
                        icon: Icons.shopping_bag_outlined,
                        count: count,
                        bounceGeneration: bounce,
                        cartIconKey: CartFlyService.instance.cartIconKey,
                      ),
                      selectedIcon: CartNavIcon(
                        icon: Icons.shopping_bag_rounded,
                        count: count,
                        bounceGeneration: bounce,
                        cartIconKey: CartFlyService.instance.cartIconKey,
                      ),
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
