import 'api_client.dart';

class SellerProfileView {
  SellerProfileView({
    required this.id,
    required this.name,
    required this.phone,
    required this.shopName,
    required this.shopCategory,
    required this.cuisine,
    required this.city,
    required this.neighborhood,
    required this.opensAt,
    required this.closesAt,
    required this.acceptsDelivery,
    required this.acceptsPickup,
    required this.followersCount,
    required this.mealsCount,
    required this.followedByMe,
  });

  final int id;
  final String name;
  final String phone;
  final String shopName;
  final String shopCategory;
  final String cuisine;
  final String city;
  final String neighborhood;
  final String opensAt;
  final String closesAt;
  final bool acceptsDelivery;
  final bool acceptsPickup;
  final int followersCount;
  final int mealsCount;
  final bool followedByMe;

  factory SellerProfileView.fromJson(Map<String, dynamic> json) {
    final profile = (json['seller_profile'] as Map<String, dynamic>?) ?? const {};
    return SellerProfileView(
      id: json['id'] as int,
      name: (json['name'] ?? json['display_name'] ?? '') as String,
      phone: json['phone'] as String? ?? '',
      shopName: profile['shop_name'] as String? ?? '',
      shopCategory: profile['shop_category'] as String? ?? '',
      cuisine: profile['cuisine'] as String? ?? '',
      city: profile['city'] as String? ?? '',
      neighborhood: profile['neighborhood'] as String? ?? '',
      opensAt: profile['opens_at'] as String? ?? '',
      closesAt: profile['closes_at'] as String? ?? '',
      acceptsDelivery: profile['accepts_delivery'] as bool? ?? false,
      acceptsPickup: profile['accepts_pickup'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      mealsCount: json['meals_count'] as int? ?? 0,
      followedByMe: json['followed_by_me'] as bool? ?? false,
    );
  }
}

class SellerLocation {
  SellerLocation({
    required this.id,
    required this.name,
    required this.shopName,
    required this.cuisine,
    required this.city,
    required this.latitude,
    required this.longitude,
  });

  final int id;
  final String name;
  final String shopName;
  final String cuisine;
  final String city;
  final double latitude;
  final double longitude;

  factory SellerLocation.fromJson(Map<String, dynamic> json) {
    return SellerLocation(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      shopName: json['shop_name'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      city: json['city'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class AccountsApi {
  AccountsApi._();
  static final AccountsApi instance = AccountsApi._();

  final _dio = ApiClient.instance.dio;

  Future<SellerProfileView> fetchSeller(int sellerId) async {
    final res = await _dio.get('/auth/sellers/$sellerId/');
    return SellerProfileView.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> toggleFollow(int sellerId) async {
    final res = await _dio.post('/auth/sellers/$sellerId/follow/');
    return res.data['following'] as bool? ?? false;
  }

  /// Returns the raw seller profile map for the current user.
  Future<Map<String, dynamic>> fetchMyProfile() async {
    final res = await _dio.get('/auth/me/profile/');
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> updateMyProfile(Map<String, dynamic> data) async {
    await _dio.patch('/auth/me/profile/', data: data);
  }

  Future<void> updateMe({String? displayName, String? phone}) async {
    await _dio.patch('/auth/me/', data: {
      if (displayName != null) 'display_name': displayName,
      if (phone != null) 'phone': phone,
    });
  }

  Future<List<SellerLocation>> fetchSellersWithLocation() async {
    final res = await _dio.get('/auth/sellers/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => SellerLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
