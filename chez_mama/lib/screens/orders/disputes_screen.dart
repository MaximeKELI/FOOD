import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  List<DisputeView> _items = [];
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
      final items = await SupportApi.instance.fetchDisputes();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _create() async {
    final orderCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('disputes.create')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: orderCtrl,
                decoration: InputDecoration(labelText: tr('disputes.orderId')),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
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
    final orderId = int.tryParse(orderCtrl.text.trim());
    if (orderId == null) return;
    try {
      await SupportApi.instance.createDispute(
        orderId: orderId,
        reason: reasonCtrl.text.trim(),
        details: detailsCtrl.text.trim(),
      );
      await _load();
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
      appBar: AppBar(title: Text(tr('disputes.title'))),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add_rounded),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton();
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    if (_items.isEmpty) {
      return EmptyStateView(
        icon: Icons.gavel_rounded,
        title: tr('disputes.empty'),
        subtitle: tr('disputes.emptyHint'),
        actionLabel: tr('disputes.create'),
        onAction: _create,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final d = _items[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: ChezMamaTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        trf('disputes.orderLine', {'id': d.orderId}),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                    Text(
                      d.status,
                      style: TextStyle(
                        color: ChezMamaTheme.brandBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(d.reason),
                if (d.details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    d.details,
                    style: TextStyle(color: ChezMamaTheme.mutedInk(context)),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
