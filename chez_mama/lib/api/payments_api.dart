import '../api/api_client.dart';

class PaymentIntentView {
  PaymentIntentView({
    required this.id,
    required this.orderId,
    required this.provider,
    required this.status,
    required this.amount,
    required this.checkoutUrl,
  });

  final int id;
  final int orderId;
  final String provider;
  final String status;
  final int amount;
  final String checkoutUrl;

  factory PaymentIntentView.fromJson(Map<String, dynamic> json) {
    return PaymentIntentView(
      id: json['id'] as int,
      orderId: json['order'] as int,
      provider: json['provider'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      checkoutUrl: json['checkout_url'] as String? ?? '',
    );
  }
}

class PaymentsApi {
  PaymentsApi._();
  static final PaymentsApi instance = PaymentsApi._();

  final _dio = ApiClient.instance.dio;

  Future<PaymentIntentView> initiate(int orderId) async {
    final res = await _dio.post('/payments/initiate/', data: {'order_id': orderId});
    return PaymentIntentView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<PaymentIntentView> status(int paymentId) async {
    final res = await _dio.get('/payments/$paymentId/');
    return PaymentIntentView.fromJson(res.data as Map<String, dynamic>);
  }
}
