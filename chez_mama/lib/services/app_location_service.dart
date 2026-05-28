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
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (
          location: null,
          error: 'Active la localisation de ton appareil (GeoClue sur Linux).',
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
      );
      return (
        location: LatLng(position.latitude, position.longitude),
        error: null,
        allowManual: false,
      );
    } on MissingPluginException {
      return (
        location: null,
        error: 'Plugin de localisation indisponible. Relance l’app après mise à jour.',
        allowManual: true,
      );
    } catch (e) {
      return (
        location: null,
        error: 'Erreur localisation: $e',
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
