import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../auth/auth_scope.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';

class GroupOrderScreen extends StatefulWidget {
  const GroupOrderScreen({super.key});

  @override
  State<GroupOrderScreen> createState() => _GroupOrderScreenState();
}

class _GroupOrderScreenState extends State<GroupOrderScreen> {
  GroupOrderView? _group;
  final _codeCtrl = TextEditingController();
  final _sellerCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _sellerCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final sellerId = int.tryParse(_sellerCtrl.text.trim());
    if (sellerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('groupOrder.needSeller'))),
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await SupportApi.instance.createGroupOrder(sellerId: sellerId);
      if (!mounted) return;
      setState(() => _group = g);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final g = await SupportApi.instance.joinGroupOrder(code);
      if (!mounted) return;
      setState(() => _group = g);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addFromCart() async {
    final g = _group;
    if (g == null) return;
    final cart = CartService.instance;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('groupOrder.cartEmpty'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      GroupOrderView updated = g;
      for (final item in cart.items) {
        updated = await SupportApi.instance.addGroupOrderItem(
          g.code,
          mealId: item.mealId,
          quantity: item.quantity,
        );
      }
      if (!mounted) return;
      setState(() => _group = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('groupOrder.itemsAdded'))),
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

  Future<void> _checkout() async {
    final g = _group;
    if (g == null) return;
    final me = AuthScope.of(context).userId;
    if (me != g.hostId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('groupOrder.hostOnly'))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await SupportApi.instance.checkoutGroupOrder(
        g.code,
        fulfillment: 'delivery',
        paymentMethod: 'cash',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('groupOrder.checkedOut'))),
      );
      final refreshed = await SupportApi.instance.fetchGroupOrder(g.code);
      if (!mounted) return;
      setState(() => _group = refreshed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    final g = _group;
    if (g == null) return;
    try {
      final updated = await SupportApi.instance.fetchGroupOrder(g.code);
      if (!mounted) return;
      setState(() => _group = updated);
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
      appBar: AppBar(title: Text(tr('groupOrder.title'))),
      body: _group == null ? _buildJoinCreate() : _buildGroup(),
    );
  }

  Widget _buildJoinCreate() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: ChezMamaTheme.promoRed)),
          ),
        Text(
          tr('groupOrder.createTitle'),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _sellerCtrl,
          decoration: InputDecoration(labelText: tr('groupOrder.sellerId')),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _busy ? null : _create,
          child: Text(tr('groupOrder.create')),
        ),
        const SizedBox(height: 28),
        Text(
          tr('groupOrder.joinTitle'),
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeCtrl,
          decoration: InputDecoration(labelText: tr('groupOrder.code')),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: _busy ? null : _join,
          child: Text(tr('groupOrder.join')),
        ),
      ],
    );
  }

  Widget _buildGroup() {
    final g = _group!;
    final me = AuthScope.of(context).userId;
    if (g.items.isEmpty && g.status == 'open') {
      // still show actions
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ChezMamaTheme.cardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trf('groupOrder.codeLine', {'code': g.code}),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(trf('groupOrder.hostLine', {'name': g.hostName})),
                Text(trf('groupOrder.statusLine', {'status': g.status})),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            tr('groupOrder.items'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (g.items.isEmpty)
            EmptyStateView(
              icon: Icons.group_outlined,
              title: tr('groupOrder.noItems'),
              subtitle: tr('groupOrder.noItemsHint'),
            )
          else
            ...g.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${item.quantity}× ${item.mealName}'),
                subtitle: Text(item.userName),
              ),
            ),
          const SizedBox(height: 16),
          if (g.status == 'open') ...[
            FilledButton.tonal(
              onPressed: _busy ? null : _addFromCart,
              child: Text(tr('groupOrder.addFromCart')),
            ),
            if (me == g.hostId) ...[
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _checkout,
                child: Text(tr('groupOrder.checkout')),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
