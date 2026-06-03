import 'package:flutter_stripe/flutter_stripe.dart';

import '../api/api_client.dart';

/// Creates a Stripe PaymentIntent via the backend and presents PaymentSheet.
class StripePaymentService {
  StripePaymentService._();
  static final instance = StripePaymentService._();

  final _client = ApiClient.instance;

  Future<int> payOrder(int orderId) async {
    final res = await _client.dio.post(
      '/payments/stripe/create/',
      data: {'order_id': orderId},
    );
    final data = res.data as Map<String, dynamic>;
    final intentId = data['id'] as int?;
    final secret = data['client_secret'] as String?;
    final publishable = data['publishable_key'] as String?;
    if (intentId == null) {
      throw StateError('payment intent id manquant');
    }
    if (secret == null || secret.isEmpty) {
      throw StateError('client_secret manquant');
    }
    if (publishable != null && publishable.isNotEmpty) {
      Stripe.publishableKey = publishable;
    }
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: secret,
        merchantDisplayName: 'Chez Mama',
      ),
    );
    await Stripe.instance.presentPaymentSheet();
    return intentId;
  }
}
