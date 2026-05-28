import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../ui/chezmama_theme.dart';
import 'api_client.dart';
import 'api_config.dart';

class CatalogApi {
  CatalogApi._();
  static final CatalogApi instance = CatalogApi._();

  final _dio = ApiClient.instance.dio;

  Future<List<String>> fetchCategories() async {
    final res = await _dio.get('/catalog/categories/');
    final list = (res.data as List?) ?? const [];
    return list.map((e) => e['name'] as String).toList();
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
