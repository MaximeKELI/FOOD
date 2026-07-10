import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<SavedAddress> _items = [];
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
      final items = await SupportApi.instance.fetchAddresses();
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

  Future<void> _edit([SavedAddress? existing]) async {
    final label = TextEditingController(text: existing?.label ?? '');
    final address = TextEditingController(text: existing?.address ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    var isDefault = existing?.isDefault ?? false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(
            existing == null ? tr('addresses.add') : tr('addresses.edit'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: InputDecoration(labelText: tr('addresses.label')),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: address,
                  decoration:
                      InputDecoration(labelText: tr('addresses.address')),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phone,
                  decoration: InputDecoration(labelText: tr('checkout.phone')),
                  keyboardType: TextInputType.phone,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr('addresses.default')),
                  value: isDefault,
                  onChanged: (v) => setLocal(() => isDefault = v),
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
        await SupportApi.instance.createAddress(
          label: label.text.trim(),
          address: address.text.trim(),
          phone: phone.text.trim(),
          isDefault: isDefault,
        );
      } else {
        await SupportApi.instance.updateAddress(
          existing.id,
          label: label.text.trim(),
          address: address.text.trim(),
          phone: phone.text.trim(),
          isDefault: isDefault,
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

  Future<void> _delete(SavedAddress a) async {
    try {
      await SupportApi.instance.deleteAddress(a.id);
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
      appBar: AppBar(title: Text(tr('addresses.title'))),
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
        icon: Icons.location_on_outlined,
        title: tr('addresses.empty'),
        subtitle: tr('addresses.emptyHint'),
        actionLabel: tr('addresses.add'),
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
          final a = _items[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: ChezMamaTheme.cardDecoration(context),
            child: Row(
              children: [
                Icon(
                  a.isDefault
                      ? Icons.home_rounded
                      : Icons.location_on_outlined,
                  color: ChezMamaTheme.brandOrange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.label.isEmpty ? tr('addresses.untitled') : a.label,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(a.address),
                      if (a.phone.isNotEmpty)
                        Text(
                          a.phone,
                          style: TextStyle(
                            color: ChezMamaTheme.mutedInk(context),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _edit(a),
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  onPressed: () => _delete(a),
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
