import 'api_client.dart';

class DriverProfile {
  DriverProfile({
    required this.id,
    required this.vehicleType,
    required this.licensePlate,
    required this.status,
    this.latitude,
    this.longitude,
    required this.isActive,
  });

  final int id;
  final String vehicleType;
  final String licensePlate;
  final String status;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        id: json['id'] as int,
        vehicleType: json['vehicle_type'] as String? ?? '',
        licensePlate: json['license_plate'] as String? ?? '',
        status: json['status'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isActive: json['is_active'] as bool? ?? false,
      );
}

class DeliveryView {
  DeliveryView({
    required this.id,
    required this.orderId,
    required this.status,
    this.driverId,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.etaMinutes,
    required this.updatedAt,
  });

  final int id;
  final int orderId;
  final String status;
  final int? driverId;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final int? etaMinutes;
  final String updatedAt;

  factory DeliveryView.fromJson(Map<String, dynamic> json) => DeliveryView(
        id: json['id'] as int,
        orderId: json['order_id'] as int? ?? 0,
        status: json['status'] as String? ?? '',
        driverId: json['driver'] as int?,
        pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble(),
        pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble(),
        dropoffLatitude: (json['dropoff_latitude'] as num?)?.toDouble(),
        dropoffLongitude: (json['dropoff_longitude'] as num?)?.toDouble(),
        etaMinutes: json['eta_minutes'] as int?,
        updatedAt: json['updated_at'] as String? ?? '',
      );
}

class DeliveriesApi {
  DeliveriesApi._();
  static final DeliveriesApi instance = DeliveriesApi._();

  final _dio = ApiClient.instance.dio;

  Future<DriverProfile> fetchDriverMe() async {
    final res = await _dio.get('/deliveries/drivers/me/');
    return DriverProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DriverProfile> updateDriverMe({
    String? vehicleType,
    String? licensePlate,
    String? status,
    double? latitude,
    double? longitude,
  }) async {
    final res = await _dio.patch('/deliveries/drivers/me/', data: {
      if (vehicleType != null) 'vehicle_type': vehicleType,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (status != null) 'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
    return DriverProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<DeliveryView>> fetchPending() async {
    final res = await _dio.get('/deliveries/pending/');
    final list = res.data is Map
        ? ((res.data['results'] as List?) ?? const [])
        : ((res.data as List?) ?? const []);
    return list
        .map((e) => DeliveryView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DeliveryView> accept(int deliveryId) async {
    final res = await _dio.post('/deliveries/$deliveryId/accept/');
    return DeliveryView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DeliveryView> updateStatus(int deliveryId, String status) async {
    final res = await _dio.patch(
      '/deliveries/$deliveryId/status/',
      data: {'status': status},
    );
    return DeliveryView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DeliveryView?> byOrder(int orderId) async {
    try {
      final res = await _dio.get('/deliveries/by-order/$orderId/');
      return DeliveryView.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<DeliveryView> updateLocation(
    int deliveryId, {
    required double latitude,
    required double longitude,
    int? etaMinutes,
  }) async {
    final res = await _dio.patch('/deliveries/$deliveryId/location/', data: {
      'latitude': latitude,
      'longitude': longitude,
      if (etaMinutes != null) 'eta_minutes': etaMinutes,
    });
    return DeliveryView.fromJson(res.data as Map<String, dynamic>);
  }
}
