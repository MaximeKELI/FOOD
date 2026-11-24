import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/platform_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class OpsScreen extends StatefulWidget {
  const OpsScreen({super.key});

  @override
  State<OpsScreen> createState() => _OpsScreenState();
}

class _OpsScreenState extends State<OpsScreen> {
  OpsOverview? _ops;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = AuthScope.of(context);
    if (!auth.isStaff && !auth.isSuperuser) {
      setState(() {
        _loading = false;
        _error = tr('ops.forbidden');
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ops = await PlatformApi.instance.fetchOps();
      if (!mounted) return;
      setState(() {
        _ops = ops;
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

  Future<void> _toggle(String field, bool value) async {
    setState(() => _saving = true);
    try {
      await PlatformApi.instance.patchOpsFlags({field: value});
      await _load();
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
      appBar: AppBar(title: Text(tr('ops.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton();
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.admin_panel_settings_outlined,
        title: tr('ops.title'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    final ops = _ops!;
    final s = ops.settings;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Text(tr('ops.metrics'), style: Theme.of(context).textTheme.titleMedium),
        ListTile(
          title: Text(tr('ops.ordersToday')),
          trailing: Text('${ops.ordersToday}'),
        ),
        ListTile(
          title: Text(tr('ops.pendingDisputes')),
          trailing: Text('${ops.pendingDisputes}'),
        ),
        ListTile(
          title: Text(tr('ops.pendingKyc')),
          trailing: Text('${ops.pendingKyc}'),
        ),
        const Divider(height: 24),
        Text(tr('ops.killSwitches'), style: Theme.of(context).textTheme.titleMedium),
        SwitchListTile(
          title: Text(tr('ops.paymentsEnabled')),
          value: s.paymentsEnabled,
          onChanged: _saving
              ? null
              : (v) => _toggle('payments_enabled', v),
        ),
        SwitchListTile(
          title: Text(tr('ops.newOrdersEnabled')),
          value: s.newOrdersEnabled,
          onChanged: _saving
              ? null
              : (v) => _toggle('new_orders_enabled', v),
        ),
        SwitchListTile(
          title: Text(tr('ops.cashEnabled')),
          value: s.cashEnabled,
          onChanged: _saving ? null : (v) => _toggle('cash_enabled', v),
        ),
        SwitchListTile(
          title: Text(tr('ops.digitalPaymentsEnabled')),
          value: s.digitalPaymentsEnabled,
          onChanged: _saving
              ? null
              : (v) => _toggle('digital_payments_enabled', v),
        ),
      ],
    );
  }
}