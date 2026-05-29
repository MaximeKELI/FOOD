import 'package:dio/dio.dart';

import '../models/meal.dart';
import '../ui/chezmama_theme.dart';
import 'api_client.dart';
import 'api_config.dart';

class MealCategory {
  const MealCategory({required this.id, required this.name});
  final int id;
  final String name;
}

class CatalogApi {
  CatalogApi._();
  static final CatalogApi instance = CatalogApi._();

  final _dio = ApiClient.instance.dio;

  Future<List<MealCategory>> fetchCategories() async {
    final res = await _dio.get('/catalog/categories/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => MealCategory(id: e['id'] as int, name: e['name'] as String))
        .toList();
  }

  Future<List<Meal>> fetchMeals({
    String? category,
    String? query,
    int? sellerId,
    bool availableOnly = false,
    bool specialOnly = false,
  }) async {
    final res = await _dio.get(
      '/catalog/meals/',
      queryParameters: {
        if (category != null && category != 'Popular' && category != 'Tous')
          'category': category,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (sellerId != null) 'seller': sellerId,
        if (availableOnly) 'available': 'true',
        if (specialOnly) 'special': 'true',
      },
    );
    final results = (res.data['results'] as List?) ?? const [];
    return results.map((e) => _mealFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deleteMeal(String id) async {
    await _dio.delete('/catalog/meals/$id/');
  }

  /// Updates the availability / "plat du jour" flags of a meal owned by the
  /// current seller. Uses multipart to match the endpoint's parsers.
  Future<Meal> updateMealFlags(
    String id, {
    bool? isAvailable,
    bool? isSpecial,
  }) async {
    final form = FormData.fromMap({
      if (isAvailable != null) 'is_available': isAvailable,
      if (isSpecial != null) 'is_special': isSpecial,
    });
    final res = await _dio.patch('/catalog/meals/$id/', data: form);
    return _mealFromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> toggleFavorite(String mealId) async {
    final res = await _dio.post('/catalog/meals/$mealId/favorite/');
    return res.data['favorited'] as bool? ?? false;
  }

  Future<List<Meal>> fetchFavorites() async {
    final res = await _dio.get('/catalog/favorites/');
    final results = (res.data['results'] as List?) ?? const [];
    return results.map((e) => _mealFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MealReview>> fetchReviews(String mealId) async {
    final res = await _dio.get('/catalog/meals/$mealId/reviews/');
    final list = (res.data as List?) ?? const [];
    return list
        .map((e) => MealReview.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MealReview> addReview(
    String mealId, {
    required int rating,
    String comment = '',
  }) async {
    final res = await _dio.post(
      '/catalog/meals/$mealId/reviews/',
      data: {'rating': rating, 'comment': comment},
    );
    return MealReview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Meal> createMeal({
    required String name,
    required int categoryId,
    required String imagePath,
    String? subtitle,
    int? price,
    int? promoPrice,
    bool isSpecial = false,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'category': categoryId,
      if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
      if (price != null) 'price': price,
      if (promoPrice != null) 'promo_price': promoPrice,
      'is_special': isSpecial,
      'image': await MultipartFile.fromFile(imagePath),
    });
    final res = await _dio.post('/catalog/meals/', data: form);
    return _mealFromJson(res.data as Map<String, dynamic>);
  }

  Meal _mealFromJson(Map<String, dynamic> json) {
    final image = (json['image'] as String?) ?? '';
    return Meal(
      id: (json['id']).toString(),
      name: json['name'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      promoPrice: (json['promo_price'] as num?)?.toDouble() ?? 0,
      hasPromo: json['has_promo'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      image: image.startsWith('http') ? image : '${ApiConfig.baseUrl}$image',
      accent: ChezMamaTheme.brandOrange,
      category: json['category_name'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      isSpecial: json['is_special'] as bool? ?? false,
      sellerId: json['seller'] as int?,
      sellerName: json['seller_name'] as String? ?? '',
      sellerLat: (json['seller_lat'] as num?)?.toDouble(),
      sellerLng: (json['seller_lng'] as num?)?.toDouble(),
      reviewsCount: json['reviews_count'] as int? ?? 0,
      favoritedByMe: json['favorited_by_me'] as bool? ?? false,
    );
  }
}

class MealReview {
  MealReview({
    required this.rating,
    required this.comment,
    required this.userName,
    required this.createdAt,
  });

  final int rating;
  final String comment;
  final String userName;
  final String createdAt;

  factory MealReview.fromJson(Map<String, dynamic> json) {
    return MealReview(
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      userName: json['user_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
