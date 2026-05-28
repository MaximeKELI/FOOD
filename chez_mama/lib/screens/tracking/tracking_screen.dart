import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../ui/chezmama_theme.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  Position? _position;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startLocation();
  }

  Future<void> _startLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'Active la localisation de ton appareil.';
          _loading = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'Permission de localisation refusée.';
          _loading = false;
        });
        return;
      }

      final initial = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _position = initial;
        _loading = false;
      });

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen((pos) {
        if (!mounted) return;
        setState(() => _position = pos);
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur localisation: $e';
        _loading = false;
      });
    }
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
            _StatusProgress(value: _position == null ? 0.1 : 0.78),
            const SizedBox(height: 16),
            if (_position != null)
              Text(
                'Lat: ${_position!.latitude.toStringAsFixed(5)}  •  Lng: ${_position!.longitude.toStringAsFixed(5)}',
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
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final pos = _position;
    if (pos == null) {
      return const Center(child: Text('Position indisponible.'));
    }
    final center = LatLng(pos.latitude, pos.longitude);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(center, 15.5);
    });

    final nearbyServices = [
      LatLng(pos.latitude + 0.0042, pos.longitude - 0.0024),
      LatLng(pos.latitude - 0.0031, pos.longitude + 0.0036),
      LatLng(pos.latitude + 0.0021, pos.longitude + 0.0018),
    ];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.5,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.food',
        ),
        MarkerLayer(
          markers: [
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
            ...nearbyServices.map(
              (p) => Marker(
                point: p,
                width: 38,
                height: 38,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF6E3B1F),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
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


