import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../cart/received_orders_notifier.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/entrance.dart';

const _activeStatuses = {'pending', 'preparing', 'on_the_way'};

class ReceivedOrdersScreen extends StatefulWidget {
  const ReceivedOrdersScreen({super.key});

  @override
  State<ReceivedOrdersScreen> createState() => _ReceivedOrdersScreenState();
}

class _ReceivedOrdersScreenState extends State<ReceivedOrdersScreen> {
  List<OrderView> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<OrderView> get _active =>
      _orders.where((o) => _activeStatuses.contains(o.status)).toList();
  List<OrderView> get _done =>
      _orders.where((o) => !_activeStatuses.contains(o.status)).toList();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await OrdersApi.instance.fetchReceivedOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
      ReceivedOrdersNotifier.instance.refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  String _statusText(OrderView order) =>
      kOrderStatusKeys.contains(order.status)
          ? orderStatusLabel(order.status)
          : order.statusLabel;

  Future<void> _changeStatus(OrderView order, String status) async {
    try {
      final updated = await OrdersApi.instance.updateStatus(order.id, status);
      if (!mounted) return;
      setState(() {
        final i = _orders.indexWhere((o) => o.id == order.id);
        if (i != -1) _orders[i] = updated;
      });
      ReceivedOrdersNotifier.instance.refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            trf('orders.statusUpdated', {'status': _statusText(updated)}),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('orders.received')),
          bottom: TabBar(
            tabs: [
              Tab(text: trf('orders.tabActive', {'count': _active.length})),
              Tab(text: trf('orders.tabDone', {'count': _done.length})),
            ],
          ),
        ),
        body: _buildBody(),
      ),
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
    return TabBarView(
      children: [
        _OrdersList(
          orders: _active,
          emptyText: tr('orders.activeEmpty'),
          onRefresh: _load,
          onStatusChange: _changeStatus,
        ),
        _OrdersList(
          orders: _done,
          emptyText: tr('orders.doneEmpty'),
          onRefresh: _load,
          onStatusChange: _changeStatus,
        ),
      ],
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({
    required this.orders,
    required this.emptyText,
    required this.onRefresh,
    required this.onStatusChange,
  });

  final List<OrderView> orders;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final void Function(OrderView, String) onStatusChange;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: orders.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyText)),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(14),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => FadeInUp(
                index: i,
                child: _ReceivedOrderCard(
                  order: orders[i],
                  onStatusChange: (s) => onStatusChange(orders[i], s),
                ),
              ),
            ),
    );
  }
}

class _ReceivedOrderCard extends StatelessWidget {
  const _ReceivedOrderCard({required this.order, required this.onStatusChange});
  final OrderView order;
  final ValueChanged<String> onStatusChange;

  String get _statusText =>
      kOrderStatusKeys.contains(order.status)
          ? orderStatusLabel(order.status)
          : order.statusLabel;

  String get _fulfillmentText {
    if (order.fulfillment == 'pickup') return tr('checkout.pickup');
    if (order.address.isEmpty) return tr('checkout.delivery');
    return trf('orders.deliveryWithAddress', {'address': order.address});
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final paymentLine = order.paymentLabel.isEmpty
        ? ''
        : '\n${trf('orders.paymentLine', {'method': order.paymentLabel})}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          if (order.customerName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              trf('orders.customerLine', {'name': order.customerName}),
              style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 8),
          for (final item in order.items)
            Text(
              '${item.quantity} x ${item.mealName}'
              '${item.unitPrice > 0 ? '  (${formatFcfa(item.lineTotal)})' : ''}',
              style: t.textTheme.bodyMedium,
            ),
          const SizedBox(height: 6),
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
                  '$_fulfillmentText$paymentLine',
                  style:
                      t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatFcfa(order.total),
                style: t.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (order.phone.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '📞 ${order.phone}',
                style: t.textTheme.bodySmall,
              ),
            ),
          const Divider(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<String>(
              value: order.status,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(14),
              items: kOrderStatusKeys
                  .map(
                    (key) => DropdownMenuItem(
                      value: key,
                      child: Text(orderStatusLabel(key)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null && v != order.status) onStatusChange(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
