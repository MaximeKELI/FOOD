import 'package:flutter/material.dart';

import '../api/payments_api.dart';
import '../l10n/app_strings.dart';
import '../navigation/root_navigator.dart';

/// Tracks an in-flight mobile-money payment and polls when the app resumes.
class PaymentPendingService extends ChangeNotifier {
  PaymentPendingService._();
  static final PaymentPendingService instance = PaymentPendingService._();

  int? _intentId;
  int? _orderId;
  bool _polling = false;

  int? get intentId => _intentId;
  int? get orderId => _orderId;
  bool get hasPending => _intentId != null;

  void track({required int intentId, required int orderId}) {
    _intentId = intentId;
    _orderId = orderId;
    notifyListeners();
  }

  void clear() {
    _intentId = null;
    _orderId = null;
    notifyListeners();
  }

  /// Called when the user returns from an external payment app/browser.
  Future<void> onAppResume() async {
    final intentId = _intentId;
    if (intentId == null || _polling) return;
    _polling = true;
    try {
      for (var i = 0; i < 5; i++) {
        final intent = await PaymentsApi.instance.status(intentId);
        if (intent.status == 'paid') {
          final orderId = _orderId ?? intent.orderId;
          clear();
          _showSnack(trf('checkout.paymentConfirmedResume', {'id': orderId}));
          return;
        }
        if (intent.status == 'failed' || intent.status == 'cancelled') {
          clear();
          _showSnack(tr('checkout.paymentFailedResume'));
          return;
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    } catch (_) {
      // Keep pending — user can check orders tab.
    } finally {
      _polling = false;
    }
  }

  void _showSnack(String message) {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }
}
