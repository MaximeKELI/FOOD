import 'api_client.dart';

class OrderItemView {
  OrderItemView({
    required this.mealName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String mealName;
  final int unitPrice;
  final int quantity;
  final int lineTotal;

  factory OrderItemView.fromJson(Map<String, dynamic> json) {
    return OrderItemView(
      mealName: json['meal_name'] as String? ?? '',
      unitPrice: json['unit_price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      lineTotal: json['line_total'] as int? ?? 0,
    );
  }
}

class OrderView {
  OrderView({
    required this.id,
    required this.status,
    required this.statusLabel,
    required this.fulfillment,
    required this.address,
    required this.phone,
    required this.customerName,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String fulfillment;
  final String address;
  final String phone;
  final String customerName;
  final int total;
  final String createdAt;
  final List<OrderItemView> items;

  factory OrderView.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?) ?? const [];
    return OrderView(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      statusLabel: json['status_label'] as String? ?? '',
      fulfillment: json['fulfillment'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      items: items
          .map((e) => OrderItemView.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Order status values used by the API.
const Map<String, String> kOrderStatuses = {
  'pending': 'En attente',
  'preparing': 'En préparation',
  'on_the_way': 'En route',
  'delivered': 'Livrée',
  'cancelled': 'Annulée',
};

class OrdersApi {
  OrdersApi._();
  static final OrdersApi instance = OrdersApi._();

  final _dio = ApiClient.instance.dio;

  Future<OrderView> createOrder({
    required String fulfillment,
    required String address,
    required String phone,
    required String note,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post('/orders/', data: {
      'fulfillment': fulfillment,
      'address': address,
      'phone': phone,
      'note': note,
      'items': items,
    });
    return OrderView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OrderView>> fetchOrders() async {
    final res = await _dio.get('/orders/');
    final results = (res.data['results'] as List?) ?? const [];
    return results
        .map((e) => OrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<OrderView>> fetchReceivedOrders() async {
    final res = await _dio.get('/orders/received/');
    final results = (res.data['results'] as List?) ?? const [];
    return results
        .map((e) => OrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderView> updateStatus(int orderId, String status) async {
    final res = await _dio.patch(
      '/orders/$orderId/status/',
      data: {'status': status},
    );
    return OrderView.fromJson(res.data as Map<String, dynamic>);
  }
}
