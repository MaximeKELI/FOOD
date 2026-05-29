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
    required this.onNotifications,
    required this.onMessages,
    required this.onReceivedOrders,
    required this.onMenuSelected,
    required this.onPickLanguage,
  });

  final bool isSeller;
  final VoidCallback onNotifications;
  final VoidCallback onMessages;
  final VoidCallback onReceivedOrders;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback onPickLanguage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: NotificationsNotifier.instance,
          builder: (context, _) {
            final count = NotificationsNotifier.instance.unread;
            return IconButton(
              tooltip: 'Notifications',
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
              tooltip: 'Messages',
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
        if (isSeller)
          AnimatedBuilder(
            animation: ReceivedOrdersNotifier.instance,
            builder: (context, _) {
              final count = ReceivedOrdersNotifier.instance.activeCount;
              return IconButton(
                tooltip: 'Commandes reçues',
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
            } else {
              onMenuSelected(value);
            }
          },
          itemBuilder: (context) {
            final dark = ThemeController.instance.isDark;
            return [
              if (isSeller) ...[
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
              ],
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
    );
  }
}