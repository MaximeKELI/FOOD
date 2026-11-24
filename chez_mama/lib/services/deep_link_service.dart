import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../api/catalog_api.dart';
import '../navigation/root_navigator.dart';
import '../payments/payment_pending_service.dart';
import '../screens/meal/meal_details_screen.dart';
import '../screens/orders/order_detail_screen.dart';
import '../screens/profile/seller_profile_screen.dart';

/// Handles `food://` deep links (payment return, meal/seller/order routes).
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();

  Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleUri(initial);
      _appLinks.uriLinkStream.listen(_handleUri);
    } catch (_) {
      // Deep links unavailable on some desktop builds.
    }
  }

  void _handleUri(Uri uri) {
    final path = uri.path;
    if (path.contains('payment') || uri.host == 'payment') {
      PaymentPendingService.instance.onAppResume();
      return;
    }

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;

    final segments = _pathSegments(uri);
    if (segments.isEmpty) return;

    final kind = segments.first;
    final idRaw = segments.length > 1 ? segments[1] : null;
    final id = int.tryParse(idRaw ?? '');

    switch (kind) {
      case 'meal':
        if (id == null) return;
        _openMeal(ctx, id);
        return;
      case 'seller':
        if (id == null) return;
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => SellerProfileScreen(sellerId: id),
          ),
        );
        return;
      case 'order':
        if (id == null) return;
        Navigator.of(ctx).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: id),
          ),
        );
        return;
      default:
        break;
    }
  }

  List<String> _pathSegments(Uri uri) {
    final fromHost = uri.host.trim();
    if (fromHost.isNotEmpty &&
        fromHost != 'payment' &&
        !fromHost.contains('.')) {
      return [fromHost, ...uri.pathSegments.where((s) => s.isNotEmpty)];
    }
    return uri.pathSegments.where((s) => s.isNotEmpty).toList();
  }

  Future<void> _openMeal(BuildContext ctx, int mealId) async {
    try {
      final meal = await CatalogApi.instance.fetchMeal('$mealId');
      if (!ctx.mounted) return;
      Navigator.of(ctx).push(
        MaterialPageRoute(
          builder: (_) => MealDetailsScreen(meal: meal),
        ),
      );
    } catch (_) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Plat introuvable')),
      );
    }
  }
}