import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/notifications_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../notifications/notifications_notifier.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/entrance.dart';
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
      default:
        return Icons.notifications_rounded;
    }
  }

  Future<void> _openNotification(AppNotification n) async {
    if (!n.isRead) {
      await NotificationsApi.instance.markRead(n.id);
      await NotificationsNotifier.instance.refresh();
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
        // Seller sees review on publications — stay on list for now.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('notif.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(tr('action.retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(child: Text(tr('notif.empty')));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final n = _items[i];
          return FadeInUp(
            index: i,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openNotification(n),
                borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                child: Container(
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
                        backgroundColor:
                            ChezMamaTheme.brandOrange.withValues(alpha: 0.14),
                        child: Icon(
                          _iconFor(n.kind),
                          color: ChezMamaTheme.brandBrown,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (n.body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(n.body),
                            ],
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
