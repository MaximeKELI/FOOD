import 'package:flutter/material.dart';

import '../../api/accounts_api.dart';
import '../../api/api_client.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class SellerShopSettingsScreen extends StatefulWidget {
  const SellerShopSettingsScreen({super.key});

  @override
  State<SellerShopSettingsScreen> createState() =>
      _SellerShopSettingsScreenState();
}

class _SellerShopSettingsScreenState extends State<SellerShopSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool _acceptsOrders = true;
  final _minOrder = TextEditingController();
  final _prep = TextEditingController();
  final _opens = TextEditingController();
  final _closes = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _minOrder.dispose();
    _prep.dispose();
    _opens.dispose();
    _closes.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AccountsApi.instance.fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _acceptsOrders = data['accepts_orders'] as bool? ?? true;
        _minOrder.text = '${data['min_order_amount'] as int? ?? 0}';
        _prep.text = '${data['default_prep_minutes'] as int? ?? 30}';
        _opens.text = data['opens_at'] as String? ?? '';
        _closes.text = data['closes_at'] as String? ?? '';
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await AccountsApi.instance.updateMyProfile({
        'accepts_orders': _acceptsOrders,
        'min_order_amount': int.tryParse(_minOrder.text.trim()) ?? 0,
        'default_prep_minutes': int.tryParse(_prep.text.trim()) ?? 30,
        'opens_at': _opens.text.trim(),
        'closes_at': _closes.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('shopSettings.saved'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('shopSettings.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton(itemCount: 3);
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: Text(tr('shopSettings.acceptsOrders')),
          subtitle: Text(tr('shopSettings.acceptsOrdersHint')),
          value: _acceptsOrders,
          onChanged: (v) => setState(() => _acceptsOrders = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _minOrder,
          decoration: InputDecoration(labelText: tr('shopSettings.minOrder')),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _prep,
          decoration: InputDecoration(labelText: tr('shopSettings.prepTime')),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _opens,
          decoration: InputDecoration(
            labelText: tr('shopSettings.opensAt'),
            hintText: '09:00',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _closes,
          decoration: InputDecoration(
            labelText: tr('shopSettings.closesAt'),
            hintText: '22:00',
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(
            _saving ? tr('checkout.submitting') : tr('action.save'),
          ),
        ),
      ],
    );
  }
}
