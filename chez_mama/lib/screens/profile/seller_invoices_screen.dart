import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/platform_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/food_card.dart';
import '../../widgets/list_loading_skeleton.dart';

class SellerInvoicesScreen extends StatefulWidget {
  const SellerInvoicesScreen({super.key});

  @override
  State<SellerInvoicesScreen> createState() => _SellerInvoicesScreenState();
}

class _SellerInvoicesScreenState extends State<SellerInvoicesScreen> {
  List<SellerInvoice> _invoices = [];
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
      final list = await PlatformApi.instance.fetchInvoices();
      if (!mounted) return;
      setState(() {
        _invoices = list;
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

  String _period(SellerInvoice inv) {
    final start = inv.periodStart.length >= 10
        ? inv.periodStart.substring(0, 10)
        : inv.periodStart;
    final end =
        inv.periodEnd.length >= 10 ? inv.periodEnd.substring(0, 10) : inv.periodEnd;
    return trf('invoices.period', {'start': start, 'end': end});
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(tr('invoices.title'))),
      body: _loading
          ? const ListLoadingSkeleton(itemCount: 4, imageHeight: 0)
          : _error != null
              ? EmptyStateView(
                  icon: Icons.cloud_off_rounded,
                  title: tr('home.connectionFailed'),
                  subtitle: _error!,
                  actionLabel: tr('action.retry'),
                  onAction: _load,
                )
              : _invoices.isEmpty
                  ? EmptyStateView(
                      icon: Icons.receipt_long_outlined,
                      title: tr('invoices.empty'),
                      subtitle: tr('invoices.subtitle'),
                      wrapInCard: false,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final inv = _invoices[i];
                          return FoodCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _period(inv),
                                  style: t.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  trf('invoices.gmv', {
                                    'amount': formatFcfa(inv.gmv),
                                  }),
                                  style: t.textTheme.bodyMedium,
                                ),
                                Text(
                                  trf('invoices.commission', {
                                    'amount': formatFcfa(inv.commission),
                                  }),
                                  style: t.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  trf('invoices.status', {'status': inv.status}),
                                  style: t.textTheme.bodySmall?.copyWith(
                                    color: ChezMamaTheme.mutedInk(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}