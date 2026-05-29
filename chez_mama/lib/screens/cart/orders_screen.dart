import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/entrance.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
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
      final orders = await OrdersApi.instance.fetchOrders();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
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
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return const Center(child: Text('Aucune commande pour le moment.'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) =>
            FadeInUp(index: i, child: _OrderCard(order: _orders[i])),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final OrderView order;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
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
          const SizedBox(height: 8),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${item.quantity} x ${item.mealName}'
                '${item.unitPrice > 0 ? '  (${item.lineTotal} FCFA)' : ''}',
                style: t.textTheme.bodyMedium,
              ),
            ),
          const Divider(height: 18),
          if (order.deliveryFee > 0 ||
              order.discount > 0 ||
              order.subtotal > 0) ...[
            _miniLine(t, 'Sous-total', '${order.subtotal} FCFA'),
            if (order.deliveryFee > 0)
              _miniLine(t, 'Livraison', '${order.deliveryFee} FCFA'),
            if (order.discount > 0)
              _miniLine(
                t,
                'Promo${order.promoCode.isEmpty ? '' : ' (${order.promoCode})'}',
                '−${order.discount} FCFA',
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
              Text(
                '${order.fulfillment == 'pickup' ? 'Retrait' : 'Livraison'}'
                '${order.paymentLabel.isEmpty ? '' : ' • ${order.paymentLabel}'}',
                style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Total: ${order.total} FCFA',
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
                  '+${order.pointsEarned} points de fidélité',
                  style: t.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ChezMamaTheme.brandBrown,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniLine(ThemeData t, String label, String value, {Color? accent}) {
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
