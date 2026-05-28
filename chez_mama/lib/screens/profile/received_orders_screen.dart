import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../ui/chezmama_theme.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Commandes reçues')),
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
    if (_orders.isEmpty) {
      return const Center(child: Text('Aucune commande reçue pour le moment.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _ReceivedOrderCard(
          order: _orders[i],
          onStatusChange: (s) => _changeStatus(_orders[i], s),
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
                  order.fulfillment == 'pickup'
                      ? 'Retrait'
                      : (order.address.isEmpty
                          ? 'Livraison'
                          : 'Livraison • ${order.address}'),
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
