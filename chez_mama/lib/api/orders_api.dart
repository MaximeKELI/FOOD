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
    required this.paymentLabel,
    required this.address,
    required this.phone,
    required this.customerName,
    this.latitude,
    this.longitude,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.promoCode,
    required this.pointsEarned,
    required this.total,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String status;
  final String statusLabel;
  final String fulfillment;
  final String paymentLabel;
  final String address;
  final String phone;
  final String customerName;
  final double? latitude;
  final double? longitude;
  final int subtotal;
  final int deliveryFee;
  final int discount;
  final String promoCode;
  final int pointsEarned;
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
      paymentLabel: json['payment_label'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      subtotal: json['subtotal'] as int? ?? 0,
      deliveryFee: json['delivery_fee'] as int? ?? 0,
      discount: json['discount'] as int? ?? 0,
      promoCode: json['promo_code'] as String? ?? '',
      pointsEarned: json['points_earned'] as int? ?? 0,
      total: json['total'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      items: items
          .map((e) => OrderItemView.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Payment method keys sent to the API.
const List<String> kPaymentMethodKeys = [
  'cash',
  'stripe',
  'wave',
  'orange_money',
  'free_money',
];

/// Order status keys from the API.
const List<String> kOrderStatusKeys = [
  'pending',
  'preparing',
  'on_the_way',
  'delivered',
  'cancelled',
];

class OrdersApi {
  OrdersApi._();
  static final OrdersApi instance = OrdersApi._();

  final _dio = ApiClient.instance.dio;

  Future<OrderView> createOrder({
    required String fulfillment,
    required String paymentMethod,
    required String address,
    required String phone,
    required String note,
    required List<Map<String, dynamic>> items,
    double? latitude,
    double? longitude,
    String? promoCode,
    Map<String, dynamic>? deviceContext,
  }) async {
    final res = await _dio.post('/orders/', data: {
      'fulfillment': fulfillment,
      'payment_method': paymentMethod,
      'address': address,
      'phone': phone,
      'note': note,
      'items': items,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
      if (deviceContext != null) 'device_context': deviceContext,
    });
    return OrderView.fromJson(res.data as Map<String, dynamic>);
  }

  /// Previews the delivery fee for the given meals + customer location.
  Future<int> deliveryQuote({
    required List<int> mealIds,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.post('/orders/delivery-quote/', data: {
      'meals': mealIds,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return res.data['delivery_fee'] as int? ?? 0;
  }

  Future<({String code, int discount, int subtotal})> validatePromo({
    required String promoCode,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await _dio.post('/orders/promo-validate/', data: {
      'promo_code': promoCode,
      'items': items,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      code: data['promo_code'] as String? ?? promoCode,
      discount: data['discount'] as int? ?? 0,
      subtotal: data['subtotal'] as int? ?? 0,
    );
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

  Future<SellerStats> fetchStats() async {
    final res = await _dio.get('/orders/stats/');
    return SellerStats.fromJson(res.data as Map<String, dynamic>);
  }
}

class TopMeal {
  TopMeal({required this.name, required this.quantity, required this.revenue});
  final String name;
  final int quantity;
  final int revenue;

  factory TopMeal.fromJson(Map<String, dynamic> json) {
    return TopMeal(
      name: json['meal_name'] as String? ?? '',
      quantity: json['qty'] as int? ?? 0,
      revenue: json['revenue'] as int? ?? 0,
    );
  }
}

class DaySales {
  DaySales({required this.date, required this.revenue});
  final String date; // ISO yyyy-MM-dd
  final int revenue;

  factory DaySales.fromJson(Map<String, dynamic> json) => DaySales(
        date: json['date'] as String? ?? '',
        revenue: json['revenue'] as int? ?? 0,
      );
}

class SellerStats {
  SellerStats({
    required this.ordersCount,
    required this.itemsSold,
    required this.revenue,
    required this.deliveredRevenue,
    required this.byStatus,
    required this.topMeals,
    required this.salesByDay,
    required this.followers,
    required this.mealsCount,
  });

  final int ordersCount;
  final int itemsSold;
  final int revenue;
  final int deliveredRevenue;
  final Map<String, int> byStatus;
  final List<TopMeal> topMeals;
  final List<DaySales> salesByDay;
  final int followers;
  final int mealsCount;

  factory SellerStats.fromJson(Map<String, dynamic> json) {
    final status = (json['by_status'] as Map?) ?? const {};
    final top = (json['top_meals'] as List?) ?? const [];
    final days = (json['sales_by_day'] as List?) ?? const [];
    return SellerStats(
      ordersCount: json['orders_count'] as int? ?? 0,
      itemsSold: json['items_sold'] as int? ?? 0,
      revenue: json['revenue'] as int? ?? 0,
      deliveredRevenue: json['delivered_revenue'] as int? ?? 0,
      byStatus: status.map((k, v) => MapEntry(k as String, v as int)),
      topMeals:
          top.map((e) => TopMeal.fromJson(e as Map<String, dynamic>)).toList(),
      salesByDay:
          days.map((e) => DaySales.fromJson(e as Map<String, dynamic>)).toList(),
      followers: json['followers'] as int? ?? 0,
      mealsCount: json['meals_count'] as int? ?? 0,
    );
  }
}
