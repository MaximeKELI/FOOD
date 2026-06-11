import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../api/accounts_api.dart';
import '../../api/api_client.dart';
import '../../api/orders_api.dart';
import '../../auth/auth_scope.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_location_service.dart';
import '../../services/platform_utils.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/list_loading_skeleton.dart';
import '../auth/login_screen.dart';
import '../cart/orders_screen.dart';
import '../profile/seller_profile_screen.dart';

/// Default map center (Dakar) when GPS is unavailable on desktop.
const _defaultCenter = LatLng(14.7167, -17.4677);

const _activeStatuses = {'pending', 'preparing', 'on_the_way'};

double orderStatusProgress(String status) {
  switch (status) {
    case 'pending':
      return 0.2;
    case 'preparing':
      return 0.5;
    case 'on_the_way':
      return 0.8;
    case 'delivered':
      return 1.0;
    case 'cancelled':
      return 0;
    default:
      return 0.1;
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<LatLng>? _positionSub;
  Timer? _ordersTimer;

  LatLng? _userLocation;
  String? _locationError;
  bool _locating = true;
  bool _manualMode = false;
  List<SellerLocation> _sellers = [];

  List<OrderView> _orders = [];
  bool _ordersLoading = true;
  String? _ordersError;
  int _selectedOrderIndex = 0;
  bool _wasAuthed = false;

  @override
  void initState() {
    super.initState();
    _startLocation();
    _loadSellers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindOrdersForAuth());
  }

  void _bindOrdersForAuth() {
    if (!mounted) return;
    final authed = AuthScope.of(context).isAuthed;
    if (authed == _wasAuthed && (_ordersTimer != null || !authed)) return;
    _wasAuthed = authed;
    if (authed) {
      _loadOrders();
      _ordersTimer?.cancel();
      _ordersTimer =
          Timer.periodic(const Duration(seconds: 20), (_) => _loadOrders());
    } else {
      _ordersTimer?.cancel();
      _ordersTimer = null;
      setState(() {
        _orders = [];
        _ordersLoading = false;
        _ordersError = null;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindOrdersForAuth();
  }

  List<OrderView> get _activeOrders => _orders
      .where((o) => _activeStatuses.contains(o.status))
      .toList();

  OrderView? get _trackedOrder {
    final active = _activeOrders;
    if (active.isEmpty) return null;
    final idx = _selectedOrderIndex.clamp(0, active.length - 1);
    return active[idx];
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await OrdersApi.instance.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _ordersLoading = false;
        _ordersError = null;
        if (_selectedOrderIndex >= _activeOrders.length) {
          _selectedOrderIndex = 0;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ordersError = apiErrorMessage(e);
        _ordersLoading = false;
      });
    }
  }

  Future<void> _loadSellers() async {
    try {
      final sellers = await AccountsApi.instance.fetchSellersWithLocation();
      if (!mounted) return;
      setState(() => _sellers = sellers);
    } catch (_) {
      // Non-blocking: the map still works without seller markers.
    }
  }

  void _openSeller(SellerLocation seller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SellerProfileScreen(
          sellerId: seller.id,
          sellerName: seller.shopName.isEmpty ? seller.name : seller.shopName,
        ),
      ),
    );
  }

  Future<void> _retryLocation() async {
    await _positionSub?.cancel();
    if (!mounted) return;
    setState(() {
      _userLocation = null;
      _locationError = null;
      _locating = true;
      _manualMode = false;
    });
    await _startLocation();
  }

  Future<void> _startLocation() async {
    final result = await AppLocationService.instance.acquireLocation();
    if (!mounted) return;

    if (result.location != null) {
      setState(() {
        _userLocation = result.location;
        _locationError = null;
        _locating = false;
        _manualMode = false;
      });
      _positionSub = AppLocationService.instance.watchLocation()?.listen((loc) {
        if (!mounted) return;
        setState(() => _userLocation = loc);
      });
      return;
    }

    setState(() {
      _locationError = result.error;
      _locating = false;
      _manualMode = result.allowManual;
      if (_manualMode) {
        _userLocation = _defaultCenter;
      }
    });
  }

  void _setManualLocation(LatLng point) {
    setState(() {
      _userLocation = point;
      _locationError = null;
    });
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _ordersTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthScope.of(context).isAuthed) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            ChezMamaTheme.spaceMd,
            ChezMamaTheme.spaceMd,
            ChezMamaTheme.spaceMd,
            ChezMamaTheme.navClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('tracking.title'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 12),
              EmptyStateView(
                compact: true,
                wrapInCard: false,
                icon: Icons.login_rounded,
                title: tr('tracking.loginRequired'),
                subtitle: tr('auth.loginSubtitle'),
                secondaryActionLabel: tr('auth.login'),
                onSecondaryAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    final t = Theme.of(context);
    final tracked = _trackedOrder;
    final active = _activeOrders;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([_loadOrders(), _loadSellers()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            ChezMamaTheme.spaceMd,
            ChezMamaTheme.spaceMd,
            ChezMamaTheme.spaceMd,
            ChezMamaTheme.navClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('tracking.title'),
                style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (_ordersLoading)
                const ListLoadingSkeleton(itemCount: 2, imageHeight: 80)
              else if (_ordersError != null && _orders.isEmpty)
                EmptyStateView(
                  compact: true,
                  wrapInCard: false,
                  icon: Icons.cloud_off_rounded,
                  title: tr('tracking.loadError'),
                  subtitle: _ordersError!,
                  actionLabel: tr('action.retry'),
                  onAction: _loadOrders,
                )
              else if (tracked == null)
                EmptyStateView(
                  compact: true,
                  wrapInCard: false,
                  icon: Icons.delivery_dining_outlined,
                  lottieAsset: LottieAssets.empty,
                  title: tr('tracking.none'),
                  subtitle: tr('tracking.noneHint'),
                  secondaryActionLabel: tr('tracking.seeAll'),
                  onSecondaryAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const OrdersScreen()),
                  ),
                )
              else ...[
                if (active.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: active.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final order = active[i];
                          final selected = i == _selectedOrderIndex;
                          return ChoiceChip(
                            label: Text(trf('tracking.orderLabel', {'id': order.id})),
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => _selectedOrderIndex = i),
                          );
                        },
                      ),
                    ),
                  ),
                _OrderStatusCard(order: tracked),
              ],
              const SizedBox(height: 16),
              Text(
                tr('tracking.mapSection'),
                style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            if (_manualMode) ...[
              const SizedBox(height: 8),
              Text(
                tr('tracking.manualGpsHint'),
                style: t.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ChezMamaTheme.brandBrown,
                ),
              ),
            ],
            if (_locationError != null && !_manualMode) ...[
              const SizedBox(height: 8),
              Text(
                _locationError!,
                style: t.textTheme.bodySmall?.copyWith(
                  color: ChezMamaTheme.brandBrown,
                ),
              ),
            ],
            if (_userLocation != null) ...[
              const SizedBox(height: 8),
              Text(
                trf('tracking.coords', {
                  'lat': _userLocation!.latitude.toStringAsFixed(5),
                  'lng': _userLocation!.longitude.toStringAsFixed(5),
                }),
                style: t.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ChezMamaTheme.mutedInk(context),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: Container(
                decoration: BoxDecoration(
                  color: ChezMamaTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                  boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                  child: _buildMapContent(),
                ),
              ),
            ),
            if (_locationError != null && !_manualMode) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Geolocator.openLocationSettings(),
                    icon: const Icon(Icons.settings_rounded),
                    label: Text(tr('tracking.settings')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.app_settings_alt_rounded),
                    label: Text(tr('tracking.appSettings')),
                  ),
                  FilledButton.icon(
                    onPressed: _retryLocation,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(tr('action.retry')),
                  ),
                ],
              ),
            ],
            if (_manualMode || (_locationError != null && isDesktopPlatform)) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _retryLocation,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(tr('tracking.retryGps')),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildMapContent() {
    final tracked = _trackedOrder;

    if (_locating) {
      return const ListLoadingSkeleton(itemCount: 1, imageHeight: 220);
    }

    if (_userLocation == null &&
        (tracked?.latitude == null || tracked?.longitude == null)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded, size: 40),
              const SizedBox(height: 10),
              Text(
                _locationError ?? tr('tracking.locationUnavailable'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _retryLocation,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(tr('action.retry')),
              ),
            ],
          ),
        ),
      );
    }

    final center = _mapCenter(tracked);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(center, 14.5);
    });

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 14.5,
        onTap: _manualMode ? (_, point) => _setManualLocation(point) : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.food.chezmama',
        ),
        MarkerLayer(
          markers: [
            for (final seller in _sellers)
              Marker(
                point: LatLng(seller.latitude, seller.longitude),
                width: 46,
                height: 46,
                child: GestureDetector(
                  onTap: () => _showSeller(seller),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChezMamaTheme.brandBrown,
                        width: 2,
                      ),
                      boxShadow: ChezMamaTheme.softShadow(opacity: 0.18),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: ChezMamaTheme.brandBrown,
                      size: 22,
                    ),
                  ),
                ),
              ),
            if (tracked?.latitude != null && tracked?.longitude != null)
              Marker(
                point: LatLng(tracked!.latitude!, tracked.longitude!),
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: ChezMamaTheme.brandOrange, width: 2),
                    boxShadow: ChezMamaTheme.softShadow(opacity: 0.18),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: ChezMamaTheme.brandOrange,
                    size: 24,
                  ),
                ),
              ),
            if (_userLocation != null)
              Marker(
                point: _userLocation!,
                width: 52,
                height: 52,
                child: Container(
                  decoration: BoxDecoration(
                    color: ChezMamaTheme.brandOrange,
                    shape: BoxShape.circle,
                    boxShadow: ChezMamaTheme.softShadow(opacity: 0.2),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  LatLng _mapCenter(OrderView? order) {
    if (order?.latitude != null && order?.longitude != null) {
      return LatLng(order!.latitude!, order.longitude!);
    }
    return _userLocation ?? _defaultCenter;
  }

  void _showSeller(SellerLocation seller) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              seller.shopName.isEmpty ? seller.name : seller.shopName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              [seller.cuisine, seller.city].where((s) => s.isNotEmpty).join(' • '),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _openSeller(seller);
                },
                icon: const Icon(Icons.storefront_rounded),
                label: Text(tr('tracking.viewShop')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});
  final OrderView order;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final progress = orderStatusProgress(order.status);
    final steps = [
      ('pending', orderStatusLabel('pending')),
      ('preparing', orderStatusLabel('preparing')),
      ('on_the_way', orderStatusLabel('on_the_way')),
      ('delivered', orderStatusLabel('delivered')),
    ];
    final fulfillment = order.fulfillment == 'pickup'
        ? tr('checkout.pickup')
        : tr('checkout.delivery');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChezMamaTheme.subtleSurface(context),
        borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  trf('tracking.orderLabel', {'id': order.id}),
                  style: t.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ChezMamaTheme.brandOrange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  kOrderStatusKeys.contains(order.status)
                      ? orderStatusLabel(order.status)
                      : order.statusLabel,
                  style: t.textTheme.labelMedium?.copyWith(
                    color: ChezMamaTheme.brandBrown,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final item in order.items)
            Text(
              '${item.quantity} × ${item.mealName}',
              style: t.textTheme.bodyMedium,
            ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: ChezMamaTheme.brandBrown.withValues(alpha: 0.12),
              valueColor: const AlwaysStoppedAnimation(ChezMamaTheme.brandOrange),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _stepDone(order.status, steps[i].$1)
                          ? ChezMamaTheme.brandOrange
                          : ChezMamaTheme.brandBrown.withValues(alpha: 0.15),
                    ),
                  ),
                _StepDot(
                  label: steps[i].$2,
                  active: order.status == steps[i].$1,
                  done: _stepDone(order.status, steps[i].$1),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            trf('tracking.fulfillmentLine', {
              'fulfillment': fulfillment,
              'total': formatFcfa(order.total),
            }),
            style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  bool _stepDone(String current, String step) {
    const order = ['pending', 'preparing', 'on_the_way', 'delivered'];
    return order.indexOf(current) >= order.indexOf(step);
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done || active
        ? ChezMamaTheme.brandOrange
        : ChezMamaTheme.brandBrown.withValues(alpha: 0.25);
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active
                      ? ChezMamaTheme.brandBrown
                      : ChezMamaTheme.mutedInk(context),
                ),
          ),
        ),
      ],
    );
  }
}
