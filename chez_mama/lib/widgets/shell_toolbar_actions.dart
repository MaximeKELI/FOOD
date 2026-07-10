import 'package:flutter/material.dart';
import '../../cart/received_orders_notifier.dart';
import '../../chat/chat_unread_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../notifications/notifications_notifier.dart';
import '../../ui/chezmama_theme.dart';
import '../../ui/theme_controller.dart';

/// Shared toolbar actions used by [AppShell] and the home hero header.
class ShellToolbarActions extends StatelessWidget {
  const ShellToolbarActions({
    super.key,
    required this.isSeller,
    required this.isAuthed,
    required this.onNotifications,
    required this.onMessages,
    required this.onReceivedOrders,
    required this.onMenuSelected,
    required this.onPickLanguage,
    required this.onLogin,
  });

  final bool isSeller;
  final bool isAuthed;
  final VoidCallback onNotifications;
  final VoidCallback onMessages;
  final VoidCallback onReceivedOrders;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback onPickLanguage;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAuthed) ...[
          AnimatedBuilder(
            animation: NotificationsNotifier.instance,
            builder: (context, _) {
              final count = NotificationsNotifier.instance.unread;
              return IconButton(
                tooltip: tr('notif.title'),
                onPressed: onNotifications,
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
                tooltip: tr('menu.messages'),
                onPressed: onMessages,
                icon: count > 0
                    ? Badge.count(
                        count: count,
                        child: const Icon(Icons.chat_bubble_rounded),
                      )
                    : const Icon(Icons.chat_bubble_outline_rounded),
              );
            },
          ),
        ],
        if (isSeller && isAuthed)
          AnimatedBuilder(
            animation: ReceivedOrdersNotifier.instance,
            builder: (context, _) {
              final count = ReceivedOrdersNotifier.instance.activeCount;
              return IconButton(
                tooltip: tr('menu.receivedOrders'),
                onPressed: onReceivedOrders,
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
            if (value == 'language') {
              onPickLanguage();
            } else if (value == 'login') {
              onLogin();
            } else {
              onMenuSelected(value);
            }
          },
          itemBuilder: (context) {
            final dark = ThemeController.instance.resolveIsDark(context);
            return [
              if (!isAuthed)
                PopupMenuItem(
                  value: 'login',
                  child: ListTile(
                    leading: const Icon(Icons.login_rounded),
                    title: Text(tr('auth.login')),
                  ),
                ),
              if (isSeller && isAuthed) ...[
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
              ] else if (isAuthed) ...[
                PopupMenuItem(
                  value: 'shop',
                  child: ListTile(
                    leading: const Icon(Icons.store_mall_directory_rounded),
                    title: Text(tr('auth.sellerRegister')),
                  ),
                ),
              ],
              if (isAuthed) ...[
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
                  value: 'faq',
                  child: ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: Text(tr('menu.faq')),
                  ),
                ),
                PopupMenuItem(
                  value: 'addresses',
                  child: ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(tr('menu.addresses')),
                  ),
                ),
                PopupMenuItem(
                  value: 'referral',
                  child: ListTile(
                    leading: const Icon(Icons.card_giftcard_rounded),
                    title: Text(tr('menu.referral')),
                  ),
                ),
                PopupMenuItem(
                  value: 'disputes',
                  child: ListTile(
                    leading: const Icon(Icons.gavel_rounded),
                    title: Text(tr('menu.disputes')),
                  ),
                ),
                PopupMenuItem(
                  value: 'driver',
                  child: ListTile(
                    leading: const Icon(Icons.delivery_dining_rounded),
                    title: Text(tr('menu.driver')),
                  ),
                ),
                PopupMenuItem(
                  value: 'groupOrder',
                  child: ListTile(
                    leading: const Icon(Icons.groups_rounded),
                    title: Text(tr('menu.groupOrder')),
                  ),
                ),
              ],
              if (isSeller && isAuthed) ...[
                PopupMenuItem(
                  value: 'promos',
                  child: ListTile(
                    leading: const Icon(Icons.local_offer_rounded),
                    title: Text(tr('menu.promos')),
                  ),
                ),
                PopupMenuItem(
                  value: 'shopSettings',
                  child: ListTile(
                    leading: const Icon(Icons.settings_rounded),
                    title: Text(tr('menu.shopSettings')),
                  ),
                ),
              ],
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
              if (isAuthed)
                PopupMenuItem(
                  value: 'deleteAccount',
                  child: ListTile(
                    leading: Icon(Icons.delete_forever_outlined,
                        color: ChezMamaTheme.promoRed),
                    title: Text(tr('menu.deleteAccount')),
                  ),
                ),
              if (isAuthed)
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
    );
  }
}
