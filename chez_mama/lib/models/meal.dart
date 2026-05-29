import 'package:flutter/material.dart';

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

  /// Price actually charged (promo price when on sale, otherwise the price).
  double get effectivePrice => hasPromo && promoPrice > 0 ? promoPrice : price;
}
