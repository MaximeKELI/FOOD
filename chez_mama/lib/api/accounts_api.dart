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
}
