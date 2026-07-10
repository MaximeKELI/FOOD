import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/deliveries_api.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_location_service.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  DriverProfile? _driver;
  List<DeliveryView> _pending = [];
  DeliveryView? _active;
  bool _loading = true;
  String? _error;
  Timer? _locTimer;

  static const _statusFlow = [
    'assigned',
    'picked_up',
    'in_transit',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _locTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final driver = await DeliveriesApi.instance.fetchDriverMe();
      final pending = await DeliveriesApi.instance.fetchPending();
      if (!mounted) return;
      setState(() {
        _driver = driver;
        _pending = pending;
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

  void _startLocationUpdates(int deliveryId) {
    _locTimer?.cancel();
    _locTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      final res = await AppLocationService.instance.acquireLocation();
      final loc = res.location;
      if (loc == null) return;
      try {
        await DeliveriesApi.instance.updateLocation(
          deliveryId,
          latitude: loc.latitude,
          longitude: loc.longitude,
        );
      } catch (_) {}
    });
  }

  Future<void> _accept(DeliveryView d) async {
    try {
      final updated = await DeliveriesApi.instance.accept(d.id);
      if (!mounted) return;
      setState(() {
        _active = updated;
        _pending.removeWhere((e) => e.id == d.id);
      });
      _startLocationUpdates(updated.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('driver.accepted'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _advanceStatus() async {
    final active = _active;
    if (active == null) return;
    final idx = _statusFlow.indexOf(active.status);
    final next = idx >= 0 && idx < _statusFlow.length - 1
        ? _statusFlow[idx + 1]
        : null;
    if (next == null) return;
    try {
      final updated =
          await DeliveriesApi.instance.updateStatus(active.id, next);
      if (!mounted) return;
      setState(() => _active = updated);
      if (next == 'delivered') {
        _locTimer?.cancel();
        setState(() => _active = null);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _toggleOnline() async {
    final driver = _driver;
    if (driver == null) return;
    final next = driver.status == 'online' ? 'offline' : 'online';
    try {
      final updated =
          await DeliveriesApi.instance.updateDriverMe(status: next);
      if (!mounted) return;
      setState(() => _driver = updated);
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
        title: Text(tr('driver.title')),
        actions: [
          if (_driver != null)
            TextButton(
              onPressed: _toggleOnline,
              child: Text(
                _driver!.status == 'online'
                    ? tr('driver.goOffline')
                    : tr('driver.goOnline'),
              ),
            ),
        ],
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
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          if (_active != null) ...[
            Text(
              tr('driver.active'),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _DeliveryCard(
              delivery: _active!,
              trailing: FilledButton(
                onPressed: _advanceStatus,
                child: Text(tr('driver.nextStatus')),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            tr('driver.pending'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          if (_pending.isEmpty)
            Text(tr('driver.pendingEmpty'))
          else
            ..._pending.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DeliveryCard(
                  delivery: d,
                  trailing: FilledButton.tonal(
                    onPressed: () => _accept(d),
                    child: Text(tr('driver.accept')),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery, this.trailing});
  final DeliveryView delivery;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
                  trf('driver.orderLine', {'id': delivery.orderId}),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(trf('driver.statusLine', {'status': delivery.status})),
                if (delivery.etaMinutes != null)
                  Text(trf('driver.eta', {'min': delivery.etaMinutes!})),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
