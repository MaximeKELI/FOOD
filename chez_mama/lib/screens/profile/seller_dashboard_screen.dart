import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../ui/chezmama_theme.dart';

const _statusLabels = {
  'pending': 'En attente',
  'preparing': 'En préparation',
  'on_the_way': 'En route',
  'delivered': 'Livrée',
  'cancelled': 'Annulée',
};

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  SellerStats? _stats;
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
      final stats = await OrdersApi.instance.fetchStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
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
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null || _stats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 46),
              const SizedBox(height: 10),
              Text(_error ?? 'Indisponible', textAlign: TextAlign.center),
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
    final s = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _StatCard(
                icon: Icons.payments_rounded,
                label: 'Revenu total',
                value: '${s.revenue} FCFA',
                color: ChezMamaTheme.brandOrange,
              ),
              _StatCard(
                icon: Icons.check_circle_rounded,
                label: 'Revenu livré',
                value: '${s.deliveredRevenue} FCFA',
                color: ChezMamaTheme.brandBrown,
              ),
              _StatCard(
                icon: Icons.receipt_long_rounded,
                label: 'Commandes',
                value: '${s.ordersCount}',
                color: ChezMamaTheme.brandAmber,
              ),
              _StatCard(
                icon: Icons.fastfood_rounded,
                label: 'Articles vendus',
                value: '${s.itemsSold}',
                color: ChezMamaTheme.brandOrange,
              ),
              _StatCard(
                icon: Icons.people_rounded,
                label: 'Abonnés',
                value: '${s.followers}',
                color: ChezMamaTheme.brandBrown,
              ),
              _StatCard(
                icon: Icons.restaurant_menu_rounded,
                label: 'Plats',
                value: '${s.mealsCount}',
                color: ChezMamaTheme.brandAmber,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Ventes des 7 derniers jours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
            decoration: BoxDecoration(
              color: ChezMamaTheme.cardColor(context),
              borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
              boxShadow: ChezMamaTheme.softShadow(opacity: 0.08),
            ),
            child: _SalesBarChart(days: s.salesByDay),
          ),
          const SizedBox(height: 20),
          Text(
            'Commandes par statut',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ChezMamaTheme.cardColor(context),
              borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
              boxShadow: ChezMamaTheme.softShadow(opacity: 0.08),
            ),
            child: Column(
              children: _statusLabels.entries.map((e) {
                final count = s.byStatus[e.key] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(e.value)),
                      Text(
                        '$count',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Plats les plus vendus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          if (s.topMeals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Aucune vente pour le moment.'),
            )
          else
            ...s.topMeals.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ChezMamaTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                  boxShadow: ChezMamaTheme.softShadow(opacity: 0.06),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor:
                          ChezMamaTheme.brandOrange.withValues(alpha: 0.15),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: ChezMamaTheme.brandBrown,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text('${m.quantity} vendus  •  ${m.revenue} FCFA'),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: t.textTheme.bodySmall?.copyWith(
              color: ChezMamaTheme.mutedInk(context),
            ),
          ),
        ],
      ),
    );
  }
}
