import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../api/support_api.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId, this.initial});

  final int orderId;
  final OrderView? initial;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderView? _order;
  List<OrderTimelineEvent> _timeline = [];
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initial;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final order = await OrdersApi.instance.fetchOrder(widget.orderId);
      final timeline = await OrdersApi.instance.fetchTimeline(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _timeline = timeline;
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

  Future<void> _cancel() async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('orders.cancelTitle')),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(labelText: tr('orders.cancelReason')),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('action.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('orders.cancelConfirm')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final order = await OrdersApi.instance.cancelOrder(
        widget.orderId,
        reason: reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _order = order);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('orders.cancelled'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reorder() async {
    setState(() => _busy = true);
    try {
      final items = await OrdersApi.instance.reorder(widget.orderId);
      for (final item in items) {
        if (item.mealId <= 0) continue;
        final meal = Meal(
          id: item.mealId.toString(),
          name: 'Meal #${item.mealId}',
          subtitle: '',
          price: 0,
          rating: 0,
          image: '',
          accent: ChezMamaTheme.brandOrange,
          category: '',
        );
        for (var i = 0; i < item.quantity; i++) {
          CartService.instance.addMeal(meal);
        }
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
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openDispute() async {
    final reasonCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('disputes.create')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(labelText: tr('disputes.reason')),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: detailsCtrl,
              decoration: InputDecoration(labelText: tr('disputes.details')),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('action.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('action.send')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await SupportApi.instance.createDispute(
        orderId: widget.orderId,
        reason: reasonCtrl.text.trim(),
        details: detailsCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('disputes.created'))),
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
      appBar: AppBar(
        title: Text(trf('tracking.orderLabel', {'id': widget.orderId})),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _order == null) return const ListLoadingSkeleton();
    if (_error != null && _order == null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    final order = _order!;
    final statusText = kOrderStatusKeys.contains(order.status)
        ? orderStatusLabel(order.status)
        : order.statusLabel;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ChezMamaTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    Text(
                      formatFcfa(order.total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                if (order.scheduledFor != null &&
                    order.scheduledFor!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(trf('orders.scheduled', {'when': order.scheduledFor!})),
                ],
                if (order.cancellationReason.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    trf('orders.cancelReasonLine', {
                      'reason': order.cancellationReason,
                    }),
                    style: TextStyle(color: ChezMamaTheme.promoRed),
                  ),
                ],
                const Divider(height: 20),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${item.quantity}× ${item.mealName}'
                      '${item.note.isNotEmpty ? ' — ${item.note}' : ''}',
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('orders.timeline'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (_timeline.isEmpty)
            Text(tr('orders.timelineEmpty'))
          else
            ..._timeline.map(
              (e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.check_circle_outline,
                    color: ChezMamaTheme.brandOrange),
                title: Text(
                  kOrderStatusKeys.contains(e.status)
                      ? orderStatusLabel(e.status)
                      : e.status,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  [
                    if (e.note.isNotEmpty) e.note,
                    if (e.actorName.isNotEmpty) e.actorName,
                    e.createdAt,
                  ].where((s) => s.isNotEmpty).join(' · '),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.status == 'pending')
                FilledButton.tonal(
                  onPressed: _busy ? null : _cancel,
                  child: Text(tr('orders.cancel')),
                ),
              FilledButton(
                onPressed: _busy ? null : _reorder,
                child: Text(tr('orders.reorder')),
              ),
              OutlinedButton(
                onPressed: _busy ? null : _openDispute,
                child: Text(tr('disputes.open')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
