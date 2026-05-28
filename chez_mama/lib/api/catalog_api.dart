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

  Future<List<Meal>> fetchMeals({String? category}) async {
    final res = await _dio.get(
      '/catalog/meals/',
      queryParameters: {
        if (category != null && category != 'Popular') 'category': category,
      },
    );
    final results = (res.data['results'] as List?) ?? const [];
    return results.map((e) => _mealFromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Meal> createMeal({
    required String name,
    required int categoryId,
    required String imagePath,
    String? subtitle,
    int? price,
  }) async {
    final form = FormData.fromMap({
      'name': name,
      'category': categoryId,
      if (subtitle != null && subtitle.isNotEmpty) 'subtitle': subtitle,
      if (price != null) 'price': price,
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
      rating: 0,
      image: image.startsWith('http') ? image : '${ApiConfig.baseUrl}$image',
      accent: ChezMamaTheme.brandOrange,
      category: json['category_name'] as String? ?? '',
    );
  }
}
