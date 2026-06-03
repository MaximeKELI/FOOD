import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/notifications_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../notifications/notifications_notifier.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/entrance.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';
import '../cart/orders_screen.dart';
import '../chat/conversation_screen.dart';
import '../profile/received_orders_screen.dart';
import '../profile/seller_profile_screen.dart';
import '../tracking/tracking_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await NotificationsApi.instance.fetch();
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  IconData _iconFor(String kind) {
    switch (kind) {
      case 'order':
      case 'order_status':
        return Icons.receipt_long_rounded;
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'review':
        return Icons.star_rounded;
      case 'chat':
        return Icons.chat_bubble_rounded;
      case 'weather':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('notif.deleteAll')),
        content: Text(tr('notif.deleteAllConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('action.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(tr('action.delete')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await NotificationsApi.instance.deleteAll();
      if (!mounted) return;
      setState(() => _items = []);
      await NotificationsNotifier.instance.refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('notif.cleared'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  void _patchItem(int id, {bool? isRead}) {
    setState(() {
      _items = _items
          .map((item) => item.id == id ? item.copyWith(isRead: isRead) : item)
          .toList();
    });
  }

  Future<void> _openNotification(AppNotification n) async {
    if (!n.isRead) {
      _patchItem(n.id, isRead: true);
      NotificationsNotifier.instance.markOneReadLocally();
      try {
        await NotificationsApi.instance.markRead(n.id);
        await NotificationsNotifier.instance.refresh();
      } catch (_) {
        // Garde l'état local lu ; resync au prochain refresh.
      }
    }
    if (!mounted) return;

    switch (n.link) {
      case 'order':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TrackingScreen()),
        );
      case 'received_order':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReceivedOrdersScreen()),
        );
      case 'chat':
        if (n.relatedId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ConversationScreen(conversationId: n.relatedId!),
            ),
          );
        }
      case 'follower':
        if (n.relatedId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SellerProfileScreen(
                sellerId: n.relatedId!,
                sellerName: n.title,
              ),
            ),
          );
        }
      case 'meal':
        break;
      default:
        if (n.kind == 'order' || n.kind == 'order_status') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AuthScope.of(context).isSeller
                  ? const ReceivedOrdersScreen()
                  : const OrdersScreen(),
            ),
          );
        }
    }
  }

  String _displayText(String raw) {
    return raw
        .replaceAll('\u2014', ', ')
        .replaceAll('\u2013', ', ')
        .replaceAll('\u2212', ', ');
  }

  Future<bool> _deleteOne(AppNotification n, {bool showSnack = true}) async {
    try {
      await NotificationsApi.instance.deleteOne(n.id);
      if (!mounted) return true;
      setState(() => _items.removeWhere((item) => item.id == n.id));
      await NotificationsNotifier.instance.refresh();
      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('notif.deleted'))),
        );
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
      return false;
    }
  }

  Widget _notificationTile(AppNotification n, int index) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isRead
            ? ChezMamaTheme.cardColor(context)
            : ChezMamaTheme.brandOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.06),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: ChezMamaTheme.brandOrange.withValues(alpha: 0.14),
            child: Icon(
              _iconFor(n.kind),
              color: ChezMamaTheme.brandBrown,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openNotification(n),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayText(n.title),
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (n.body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(_displayText(n.body)),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: tr('action.delete'),
            visualDensity: VisualDensity.compact,
            onPressed: () => _deleteOne(n),
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.error.withValues(
                    alpha: 0.85,
                  ),
            ),
          ),
        ],
      ),
    );

    return FadeInUp(
      index: index,
      child: Dismissible(
        key: ValueKey('notif-${n.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          return _deleteOne(n, showSnack: true);
        },
        child: card,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('notif.title')),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              tooltip: tr('notif.deleteAll'),
              onPressed: _confirmDeleteAll,
              icon: const Icon(Icons.delete_sweep_rounded),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListLoadingSkeleton(itemCount: 5, imageHeight: 72);
    }
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return EmptyStateView(
        icon: Icons.notifications_none_rounded,
        lottieAsset: LottieAssets.empty,
        title: tr('notif.empty'),
        subtitle: tr('notif.emptyHint'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _notificationTile(_items[i], i),
      ),
    );
  }
}
