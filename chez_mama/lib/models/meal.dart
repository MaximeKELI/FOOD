import 'package:flutter/material.dart';

class MealOptionChoice {
  const MealOptionChoice({
    required this.id,
    required this.name,
    required this.priceExtra,
    this.isAvailable = true,
  });

  final int id;
  final String name;
  final int priceExtra;
  final bool isAvailable;

  factory MealOptionChoice.fromJson(Map<String, dynamic> json) =>
      MealOptionChoice(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        priceExtra: json['price_extra'] as int? ?? 0,
        isAvailable: json['is_available'] as bool? ?? true,
      );
}

class MealOptionGroup {
  const MealOptionGroup({
    required this.id,
    required this.name,
    required this.required,
    required this.minSelect,
    required this.maxSelect,
    required this.choices,
  });

  final int id;
  final String name;
  final bool required;
  final int minSelect;
  final int maxSelect;
  final List<MealOptionChoice> choices;

  factory MealOptionGroup.fromJson(Map<String, dynamic> json) {
    final choices = (json['choices'] as List?) ?? const [];
    return MealOptionGroup(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      required: json['required'] as bool? ?? false,
      minSelect: json['min_select'] as int? ?? 0,
      maxSelect: json['max_select'] as int? ?? 1,
      choices: choices
          .map((e) => MealOptionChoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Meal {
  const Meal({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.image,
    required this.accent,
    required this.category,
    this.promoPrice = 0,
    this.hasPromo = false,
    this.isAvailable = true,
    this.isSpecial = false,
    this.sellerId,
    this.sellerName = '',
    this.sellerLat,
    this.sellerLng,
    this.reviewsCount = 0,
    this.favoritedByMe = false,
    this.gallery = const [],
    this.stockQty,
    this.prepTimeMinutes,
    this.tags = const [],
    this.optionGroups = const [],
  });

  final String id;
  final String name;
  final String subtitle;
  final double price;
  final double promoPrice;
  final bool hasPromo;
  final double rating;
  final String image;
  final Color accent;
  final String category;
  final bool isAvailable;
  final bool isSpecial;
  final int? sellerId;
  final String sellerName;
  final double? sellerLat;
  final double? sellerLng;
  final int reviewsCount;
  final bool favoritedByMe;
  final List<String> gallery;
  final int? stockQty;
  final int? prepTimeMinutes;
  final List<String> tags;
  final List<MealOptionGroup> optionGroups;

  /// Price actually charged (promo price when on sale, otherwise the price).
  double get effectivePrice => hasPromo && promoPrice > 0 ? promoPrice : price;
}
