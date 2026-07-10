import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class SellerPromosScreen extends StatefulWidget {
  const SellerPromosScreen({super.key});

  @override
  State<SellerPromosScreen> createState() => _SellerPromosScreenState();
}

class _SellerPromosScreenState extends State<SellerPromosScreen> {
  List<SellerPromo> _items = [];
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
      final items = await OrdersApi.instance.fetchPromos();
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

  Future<void> _edit([SellerPromo? existing]) async {
    final code = TextEditingController(text: existing?.code ?? '');
    final percent = TextEditingController(
      text: existing != null ? '${existing.percent}' : '10',
    );
    final amount = TextEditingController(
      text: existing != null ? '${existing.amount}' : '0',
    );
    final minTotal = TextEditingController(
      text: existing != null ? '${existing.minTotal}' : '0',
    );
    var active = existing?.active ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? tr('promos.add') : tr('promos.edit')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: code,
                  decoration: InputDecoration(labelText: tr('promos.code')),
                  textCapitalization: TextCapitalization.characters,
                ),
                TextField(
                  controller: percent,
                  decoration: InputDecoration(labelText: tr('promos.percent')),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: amount,
                  decoration: InputDecoration(labelText: tr('promos.amount')),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minTotal,
                  decoration: InputDecoration(labelText: tr('promos.minTotal')),
                  keyboardType: TextInputType.number,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('promos.active')),
                  value: active,
                  onChanged: (v) => setLocal(() => active = v),
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
              child: Text(tr('action.save')),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      if (existing == null) {
        await OrdersApi.instance.createPromo(
          code: code.text.trim(),
          percent: int.tryParse(percent.text) ?? 0,
          amount: int.tryParse(amount.text) ?? 0,
          minTotal: int.tryParse(minTotal.text) ?? 0,
          active: active,
        );
      } else {
        await OrdersApi.instance.updatePromo(
          existing.id,
          code: code.text.trim(),
          percent: int.tryParse(percent.text) ?? 0,
          amount: int.tryParse(amount.text) ?? 0,
          minTotal: int.tryParse(minTotal.text) ?? 0,
          active: active,
        );
      }
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _delete(SellerPromo p) async {
    try {
      await OrdersApi.instance.deletePromo(p.id);
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
      appBar: AppBar(title: Text(tr('promos.title'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
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
        icon: Icons.local_offer_outlined,
        title: tr('promos.empty'),
        subtitle: tr('promos.emptyHint'),
        actionLabel: tr('promos.add'),
        onAction: () => _edit(),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = _items[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: ChezMamaTheme.cardDecoration(context),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.code,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        p.percent > 0
                            ? '${p.percent}%'
                            : '${p.amount} FCFA',
                      ),
                      Text(
                        p.active ? tr('promos.active') : tr('promos.inactive'),
                        style: TextStyle(
                          color: p.active
                              ? ChezMamaTheme.brandBrown
                              : ChezMamaTheme.mutedInk(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _edit(p),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => _delete(p),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
