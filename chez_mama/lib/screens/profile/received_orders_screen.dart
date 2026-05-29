import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../cart/received_orders_notifier.dart';
import '../../ui/chezmama_theme.dart';

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
        SnackBar(content: Text('Statut: ${updated.statusLabel}')),
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
          title: const Text('Commandes reçues'),
          bottom: TabBar(
            labelColor: ChezMamaTheme.brandOrange,
            indicatorColor: ChezMamaTheme.brandOrange,
            tabs: [
              Tab(text: 'En cours (${_active.length})'),
              Tab(text: 'Terminées (${_done.length})'),
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
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(
                  backgroundColor: ChezMamaTheme.brandOrange,
                  foregroundColor: Colors.white,
                ),
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
          emptyText: 'Aucune commande en cours.',
          onRefresh: _load,
          onStatusChange: _changeStatus,
        ),
        _OrdersList(
          orders: _done,
          emptyText: 'Aucune commande terminée.',
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
              itemBuilder: (context, i) => _ReceivedOrderCard(
                order: orders[i],
                onStatusChange: (s) => onStatusChange(orders[i], s),
              ),
            ),
    );
  }
}

class _ReceivedOrderCard extends StatelessWidget {
  const _ReceivedOrderCard({required this.order, required this.onStatusChange});
  final OrderView order;
  final ValueChanged<String> onStatusChange;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commande #${order.id}',
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
                  order.statusLabel,
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
              'Client: ${order.customerName}',
              style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 8),
          for (final item in order.items)
            Text(
              '${item.quantity} x ${item.mealName}'
              '${item.unitPrice > 0 ? '  (${item.lineTotal} FCFA)' : ''}',
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
                  '${order.fulfillment == 'pickup' ? 'Retrait' : (order.address.isEmpty ? 'Livraison' : 'Livraison • ${order.address}')}'
                  '${order.paymentLabel.isEmpty ? '' : '\nPaiement: ${order.paymentLabel}'}',
                  style:
                      t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${order.total} FCFA',
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
              items: kOrderStatuses.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
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
