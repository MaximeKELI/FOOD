import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../api/accounts_api.dart';
import '../../services/app_location_service.dart';
import '../../services/platform_utils.dart';
import '../../ui/chezmama_theme.dart';
import '../profile/seller_profile_screen.dart';

/// Default map center (Dakar) when GPS is unavailable on desktop.
const _defaultCenter = LatLng(14.7167, -17.4677);

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<LatLng>? _positionSub;
  LatLng? _userLocation;
  String? _error;
  bool _loading = true;
  bool _manualMode = false;
  List<SellerLocation> _sellers = [];

  @override
  void initState() {
    super.initState();
    _startLocation();
    _loadSellers();
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

  Future<void> _retry() async {
    await _positionSub?.cancel();
    if (!mounted) return;
    setState(() {
      _userLocation = null;
      _error = null;
      _loading = true;
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
        _error = null;
        _loading = false;
        _manualMode = false;
      });
      _positionSub = AppLocationService.instance.watchLocation()?.listen((loc) {
        if (!mounted) return;
        setState(() => _userLocation = loc);
      });
      return;
    }

    setState(() {
      _error = result.error;
      _loading = false;
      _manualMode = result.allowManual;
      if (_manualMode) {
        _userLocation = _defaultCenter;
      }
    });
  }

  void _setManualLocation(LatLng point) {
    setState(() {
      _userLocation = point;
      _error = null;
    });
    _mapController.move(point, _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi & localisation')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Position en temps réel',
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _StatusProgress(value: _userLocation == null ? 0.1 : 0.78),
            if (_manualMode) ...[
              const SizedBox(height: 8),
              Text(
                'GPS indisponible : appuie sur la carte pour placer ta position.',
                style: t.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ChezMamaTheme.brandBrown,
                ),
              ),
            ],
            if (_error != null && !_manualMode) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: t.textTheme.bodySmall?.copyWith(
                  color: ChezMamaTheme.brandBrown,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_userLocation != null)
              Text(
                'Lat: ${_userLocation!.latitude.toStringAsFixed(5)}  •  Lng: ${_userLocation!.longitude.toStringAsFixed(5)}',
                style: t.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ChezMamaTheme.ink.withValues(alpha: 0.7),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildMapContent(),
                ),
              ),
            ),
            if (_error != null && !_manualMode) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Geolocator.openLocationSettings(),
                    icon: const Icon(Icons.settings_rounded),
                    label: const Text('Réglages'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.app_settings_alt_rounded),
                    label: const Text('Paramètres app'),
                  ),
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Réessayer'),
                    style: FilledButton.styleFrom(
                      backgroundColor: ChezMamaTheme.brandOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
            if (_manualMode || (_error != null && isDesktopPlatform)) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Réessayer GPS'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userLocation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_off_rounded, size: 40),
              const SizedBox(height: 10),
              Text(
                _error ?? 'Position indisponible.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
                style: FilledButton.styleFrom(
                  backgroundColor: ChezMamaTheme.brandOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final center = _userLocation!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(center, 15.5);
    });

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.5,
        onTap: _manualMode
            ? (_, point) => _setManualLocation(point)
            : null,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.food',
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
            Marker(
              point: center,
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
                label: const Text('Voir la boutique'),
                style: FilledButton.styleFrom(
                  backgroundColor: ChezMamaTheme.brandOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChezMamaTheme.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Préparation → En route → Livré',
                  style: t.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: t.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ChezMamaTheme.brandBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor:
                      ChezMamaTheme.brandBrown.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(
                    ChezMamaTheme.brandOrange,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
