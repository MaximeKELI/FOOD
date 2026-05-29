import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../navigation/root_navigator.dart';
import '../payments/payment_pending_service.dart';

/// Handles `food://` deep links (payment return, future meal/seller routes).
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
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('Lien: ${uri.toString()}')),
    );
  }
}
