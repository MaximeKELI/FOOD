import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';

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
      appBar: AppBar(title: Text(tr('dashboard.title'))),
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
              Text(_error ?? tr('action.unavailable'), textAlign: TextAlign.center),
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
                label: tr('dashboard.totalRevenue'),
                value: formatFcfa(s.revenue),
                color: ChezMamaTheme.brandOrange,
              ),
              _StatCard(
                icon: Icons.check_circle_rounded,
                label: tr('dashboard.deliveredRevenue'),
                value: formatFcfa(s.deliveredRevenue),
                color: ChezMamaTheme.brandBrown,
              ),
              _StatCard(
                icon: Icons.receipt_long_rounded,
                label: tr('dashboard.ordersCount'),
                value: '${s.ordersCount}',
                color: ChezMamaTheme.brandAmber,
              ),
              _StatCard(
                icon: Icons.fastfood_rounded,
                label: tr('dashboard.itemsSold'),
                value: '${s.itemsSold}',
                color: ChezMamaTheme.brandOrange,
              ),
              _StatCard(
                icon: Icons.people_rounded,
                label: tr('dashboard.followers'),
                value: '${s.followers}',
                color: ChezMamaTheme.brandBrown,
              ),
              _StatCard(
                icon: Icons.restaurant_menu_rounded,
                label: tr('dashboard.meals'),
                value: '${s.mealsCount}',
                color: ChezMamaTheme.brandAmber,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            tr('dashboard.salesLast7Days'),
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
            tr('dashboard.ordersByStatus'),
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
              children: kOrderStatusKeys.map((key) {
                final count = s.byStatus[key] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(orderStatusLabel(key))),
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
            tr('dashboard.topMeals'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          if (s.topMeals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(tr('dashboard.noSales')),
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
                    Text(
                      trf('dashboard.mealSoldLine', {
                        'quantity': m.quantity,
                        'revenue': formatFcfa(m.revenue),
                      }),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({required this.days});
  final List<DaySales> days;

  static List<String> get _weekdays => [
        tr('date.weekdayMon'),
        tr('date.weekdayTue'),
        tr('date.weekdayWed'),
        tr('date.weekdayThu'),
        tr('date.weekdayFri'),
        tr('date.weekdaySat'),
        tr('date.weekdaySun'),
      ];

  String _dow(String iso) {
    try {
      final d = DateTime.parse(iso);
      return _weekdays[(d.weekday - 1) % 7];
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return SizedBox(
        height: 60,
        child: Center(child: Text(tr('dashboard.noData'))),
      );
    }
    final maxV = days.fold<int>(0, (m, d) => d.revenue > m ? d.revenue : m);
    final total = days.fold<int>(0, (sum, d) => sum + d.revenue);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          trf('dashboard.weekTotal', {'total': formatFcfa(total)}),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ChezMamaTheme.mutedInk(context),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((d) {
              final ratio = maxV == 0 ? 0.0 : d.revenue / maxV;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d.revenue > 0)
                        Text(
                          d.revenue >= 1000
                              ? '${(d.revenue / 1000).toStringAsFixed(1)}k'
                              : '${d.revenue}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => Container(
                          height: (90 * v).clamp(2.0, 90.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                ChezMamaTheme.brandBrown,
                                ChezMamaTheme.brandOrange,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _dow(d.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: ChezMamaTheme.mutedInk(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
