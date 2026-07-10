import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/list_loading_skeleton.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/entrance.dart';
import '../orders/order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<OrderView> _orders = [];
  bool _loading = true;
  String? _error;
  String? _statusFilter;

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
      final orders = await OrdersApi.instance.fetchOrders(
        status: _statusFilter,
      );
      if (!mounted) return;
      setState(() {
        _orders = orders;
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

  Future<void> _reorder(OrderView order) async {
    try {
      final items = await OrdersApi.instance.reorder(order.id);
      for (final item in items) {
        if (item.mealId <= 0) continue;
        final match = order.items.where((i) => i.mealId == item.mealId);
        CartService.instance.addMealById(
          mealId: item.mealId,
          name: match.isNotEmpty ? match.first.mealName : 'Meal #${item.mealId}',
          unitPrice: match.isNotEmpty ? match.first.unitPrice : 0,
          quantity: item.quantity,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('orders.reordered'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  void _openDetail(OrderView order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(
          orderId: order.id,
          initial: order,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('orders.title'))),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(tr('orders.filterAll')),
                    selected: _statusFilter == null,
                    onSelected: (_) {
                      setState(() => _statusFilter = null);
                      _load();
                    },
                  ),
                ),
                for (final s in kOrderStatusKeys)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(orderStatusLabel(s)),
                      selected: _statusFilter == s,
                      onSelected: (_) {
                        setState(() => _statusFilter = s);
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListLoadingSkeleton();
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
    if (_orders.isEmpty) {
      return EmptyStateView(
        icon: Icons.receipt_long_outlined,
        lottieAsset: LottieAssets.empty,
        title: tr('orders.empty'),
        subtitle: tr('tracking.noneHint'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => FadeInUp(
          index: i,
          child: _OrderCard(
            order: _orders[i],
            onTap: () => _openDetail(_orders[i]),
            onReorder: () => _reorder(_orders[i]),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onReorder,
  });
  final OrderView order;
  final VoidCallback onTap;
  final VoidCallback onReorder;

  String get _statusText =>
      kOrderStatusKeys.contains(order.status)
          ? orderStatusLabel(order.status)
          : order.statusLabel;

  String get _fulfillmentText => order.fulfillment == 'pickup'
      ? tr('checkout.pickup')
      : tr('checkout.delivery');

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
      child: Container(
        padding: const EdgeInsets.all(ChezMamaTheme.spaceMd),
        decoration: ChezMamaTheme.cardDecoration(context, shadowOpacity: 0.08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trf('tracking.orderLabel', {'id': order.id}),
                    style: t.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ChezMamaTheme.brandOrange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _statusText,
                    style: t.textTheme.labelMedium?.copyWith(
                      color: ChezMamaTheme.brandBrown,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${item.quantity} x ${item.mealName}'
                  '${item.unitPrice > 0 ? '  (${formatFcfa(item.lineTotal)})' : ''}',
                  style: t.textTheme.bodyMedium,
                ),
              ),
            const Divider(height: 18),
            if (order.deliveryFee > 0 ||
                order.discount > 0 ||
                order.subtotal > 0) ...[
              _miniLine(
                  context, t, tr('checkout.subtotal'), formatFcfa(order.subtotal)),
              if (order.deliveryFee > 0)
                _miniLine(
                  context,
                  t,
                  tr('checkout.deliveryFee'),
                  formatFcfa(order.deliveryFee),
                ),
              if (order.discount > 0)
                _miniLine(
                  context,
                  t,
                  order.promoCode.isEmpty
                      ? tr('checkout.promoLine')
                      : trf('orders.promoWithCode', {'code': order.promoCode}),
                  '−${formatFcfa(order.discount)}',
                  accent: const Color(0xFFD7263D),
                ),
              const SizedBox(height: 6),
            ],
            Row(
              children: [
                Icon(
                  order.fulfillment == 'pickup'
                      ? Icons.storefront_rounded
                      : Icons.delivery_dining_rounded,
                  size: 18,
                  color: ChezMamaTheme.brandBrown,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _fulfillmentText +
                        (order.paymentLabel.isEmpty
                            ? ''
                            : ' • ${order.paymentLabel}'),
                    style: t.textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  trf('orders.totalLine', {'total': formatFcfa(order.total)}),
                  style: t.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (order.pointsEarned > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.workspace_premium_rounded,
                      size: 16, color: ChezMamaTheme.brandAmber),
                  const SizedBox(width: 4),
                  Text(
                    trf('orders.loyaltyEarned', {'points': order.pointsEarned}),
                    style: t.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: ChezMamaTheme.brandBrown,
                    ),
                  ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReorder,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text(tr('orders.reorder')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniLine(BuildContext context, ThemeData t, String label, String value,
      {Color? accent}) {
    final style = t.textTheme.bodySmall?.copyWith(
      color: accent ?? ChezMamaTheme.mutedInk(context),
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}
