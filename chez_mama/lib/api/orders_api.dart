import 'api_client.dart';

class OrderItemView {
  OrderItemView({
    required this.mealName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.mealId,
    this.note = '',
  });

  final int? mealId;
  final String mealName;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
  final String note;

  factory OrderItemView.fromJson(Map<String, dynamic> json) {
    return OrderItemView(
      mealId: json['meal'] as int?,
      mealName: json['meal_name'] as String? ?? '',
      unitPrice: json['unit_price'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 0,
      lineTotal: json['line_total'] as int? ?? 0,
      note: json['note'] as String? ?? '',
    );
  }
}

class OrderTimelineEvent {
  OrderTimelineEvent({
    required this.id,
    required this.status,
    required this.note,
    this.actorId,
    required this.actorName,
    required this.createdAt,
  });

  final int id;
  final String status;
  final String note;
  final int? actorId;
  final String actorName;
  final String createdAt;

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) =>
      OrderTimelineEvent(
        id: json['id'] as int,
        status: json['status'] as String? ?? '',
        note: json['note'] as String? ?? '',
        actorId: json['actor'] as int?,
        actorName: json['actor_name'] as String? ?? '',
        createdAt: json['created_at'] as String? ?? '',
      );
}

class ReorderItem {
  ReorderItem({
    required this.mealId,
    required this.quantity,
    this.note = '',
  });

  final int mealId;
  final int quantity;
  final String note;

  factory ReorderItem.fromJson(Map<String, dynamic> json) => ReorderItem(
        mealId: json['meal'] as int? ?? 0,
        quantity: json['quantity'] as int? ?? 1,
        note: json['note'] as String? ?? '',
      );
}

class SellerPromo {
  SellerPromo({
    required this.id,
    required this.code,
    required this.percent,
    required this.amount,
    required this.minTotal,
    required this.active,
    this.startsAt,
    this.endsAt,
    required this.createdAt,
  });

  final int id;
  final String code;
  final int percent;
  final int amount;
  final int minTotal;
  final bool active;
  final String? startsAt;
  final String? endsAt;
  final String createdAt;

  factory SellerPromo.fromJson(Map<String, dynamic> json) => SellerPromo(
        id: json['id'] as int,
        code: json['code'] as String? ?? '',
        percent: json['percent'] as int? ?? 0,
        amount: json['amount'] as int? ?? 0,
        minTotal: json['min_total'] as int? ?? 0,
        active: json['active'] as bool? ?? true,
        startsAt: json['starts_at'] as String?,
        endsAt: json['ends_at'] as String?,
        createdAt: json['created_at'] as String? ?? '',
      );
}

class LoyaltyRedeemPreview {
  LoyaltyRedeemPreview({
    required this.pointsRequested,
    required this.pointsAvailable,
    required this.pointsUsable,
    required this.discountFcfa,
  });

  final int pointsRequested;
  final int pointsAvailable;
  final int pointsUsable;
  final int discountFcfa;

  factory LoyaltyRedeemPreview.fromJson(Map<String, dynamic> json) =>
      LoyaltyRedeemPreview(
        pointsRequested: json['points_requested'] as int? ?? 0,
        pointsAvailable: json['points_available'] as int? ?? 0,
        pointsUsable: json['points_usable'] as int? ?? 0,
        discountFcfa: json['discount_fcfa'] as int? ?? 0,
      );
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
    this.pointsRedeemed = 0,
    this.scheduledFor,
    this.cancellationReason = '',
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
  final int pointsRedeemed;
  final String? scheduledFor;
  final String cancellationReason;
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
      subtotal: json['subtotal'] as int? ?? json['seller_subtotal'] as int? ?? 0,
      deliveryFee: json['delivery_fee'] as int? ?? 0,
      discount: json['discount'] as int? ?? 0,
      promoCode: json['promo_code'] as String? ?? '',
      pointsEarned: json['points_earned'] as int? ?? 0,
      pointsRedeemed: json['points_redeemed'] as int? ?? 0,
      scheduledFor: json['scheduled_for'] as String?,
      cancellationReason: json['cancellation_reason'] as String? ?? '',
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
    String? scheduledFor,
    int? pointsToRedeem,
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
      if (scheduledFor != null && scheduledFor.isNotEmpty)
        'scheduled_for': scheduledFor,
      if (pointsToRedeem != null && pointsToRedeem > 0)
        'points_to_redeem': pointsToRedeem,
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

  Future<List<OrderView>> fetchOrders({
    String? status,
    String? from,
    String? to,
  }) async {
    final res = await _dio.get('/orders/', queryParameters: {
      if (status != null && status.isNotEmpty) 'status': status,
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    });
    final results = (res.data['results'] as List?) ?? const [];
    return results
        .map((e) => OrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderView> fetchOrder(int orderId) async {
    final res = await _dio.get('/orders/$orderId/');
    return OrderView.fromJson(res.data as Map<String, dynamic>);
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

  Future<OrderView> cancelOrder(int orderId, {String reason = ''}) async {
    final res = await _dio.post(
      '/orders/$orderId/cancel/',
      data: {'reason': reason},
    );
    return OrderView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<OrderTimelineEvent>> fetchTimeline(int orderId) async {
    final res = await _dio.get('/orders/$orderId/timeline/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => OrderTimelineEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReorderItem>> reorder(int orderId) async {
    final res = await _dio.post('/orders/$orderId/reorder/');
    final items = (res.data['items'] as List?) ?? const [];
    return items
        .map((e) => ReorderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SellerPromo>> fetchPromos() async {
    final res = await _dio.get('/promos/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => SellerPromo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SellerPromo> createPromo({
    required String code,
    int percent = 0,
    int amount = 0,
    int minTotal = 0,
    bool active = true,
  }) async {
    final res = await _dio.post('/promos/', data: {
      'code': code,
      'percent': percent,
      'amount': amount,
      'min_total': minTotal,
      'active': active,
    });
    return SellerPromo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SellerPromo> updatePromo(
    int id, {
    String? code,
    int? percent,
    int? amount,
    int? minTotal,
    bool? active,
  }) async {
    final res = await _dio.patch('/promos/$id/', data: {
      if (code != null) 'code': code,
      if (percent != null) 'percent': percent,
      if (amount != null) 'amount': amount,
      if (minTotal != null) 'min_total': minTotal,
      if (active != null) 'active': active,
    });
    return SellerPromo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deletePromo(int id) async {
    await _dio.delete('/promos/$id/');
  }

  Future<LoyaltyRedeemPreview> loyaltyRedeemPreview({
    required int points,
    int? subtotal,
  }) async {
    final res = await _dio.post('/loyalty/redeem-preview/', data: {
      'points': points,
      if (subtotal != null) 'subtotal': subtotal,
    });
    return LoyaltyRedeemPreview.fromJson(res.data as Map<String, dynamic>);
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
