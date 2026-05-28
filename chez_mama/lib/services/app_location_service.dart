import 'dart:async';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'platform_utils.dart';

class AppLocationService {
  AppLocationService._();
  static final AppLocationService instance = AppLocationService._();

  Future<({LatLng? location, String? error, bool allowManual})> acquireLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 6), onTimeout: () => false);
      if (!serviceEnabled) {
        return (
          location: null,
          error: isDesktopPlatform
              ? 'Localisation indisponible sur ce PC. Place ta position sur la carte.'
              : 'Active la localisation de ton appareil.',
          allowManual: isDesktopPlatform,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return (
          location: null,
          error: 'Permission de localisation refusée.',
          allowManual: isDesktopPlatform,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
      return (
        location: LatLng(position.latitude, position.longitude),
        error: null,
        allowManual: false,
      );
    } on TimeoutException {
      return (
        location: null,
        error: isDesktopPlatform
            ? 'Position GPS introuvable. Place ta position sur la carte.'
            : 'Délai dépassé. Réessaie.',
        allowManual: isDesktopPlatform,
      );
    } on MissingPluginException {
      return (
        location: null,
        error: isDesktopPlatform
            ? 'Localisation non disponible sur ce PC. Place ta position sur la carte.'
            : 'Plugin de localisation indisponible.',
        allowManual: isDesktopPlatform,
      );
    } catch (e) {
      return (
        location: null,
        error: isDesktopPlatform
            ? 'Localisation indisponible. Place ta position sur la carte.'
            : 'Erreur localisation: $e',
        allowManual: isDesktopPlatform,
      );
    }
  }

  Stream<LatLng>? watchLocation() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).map((p) => LatLng(p.latitude, p.longitude));
    } catch (_) {
      return null;
    }
  }
}
