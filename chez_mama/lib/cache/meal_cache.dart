import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/meal.dart';
import '../ui/chezmama_theme.dart';

/// Persists the last fetched meal catalog for offline browsing.
class MealCache {
  MealCache._();
  static final MealCache instance = MealCache._();

  static const cacheTtl = Duration(hours: 24);

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'food_meals_cache.db'),
      version: 1,
      onCreate: (d, _) async {
        await d.execute('''
          CREATE TABLE meals_cache (
            id INTEGER PRIMARY KEY,
            payload TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> saveMeals(List<Meal> meals) async {
    final database = await db;
    final batch = database.batch();
    batch.delete('meals_cache');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final m in meals) {
      batch.insert('meals_cache', {
        'id': int.tryParse(m.id) ?? m.id.hashCode,
        'payload': jsonEncode(_mealToJson(m)),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<Meal>> loadMeals() async {
    final database = await db;
    final rows = await database.query('meals_cache', orderBy: 'id DESC');
    if (rows.isEmpty) return [];
    final latest = rows
        .map((r) => r['cached_at'] as int? ?? 0)
        .reduce((a, b) => a > b ? a : b);
    final age = DateTime.now().millisecondsSinceEpoch - latest;
    if (age > cacheTtl.inMilliseconds) {
      await database.delete('meals_cache');
      return [];
    }
    return rows
        .map((r) => _mealFromJson(jsonDecode(r['payload'] as String)))
        .toList();
  }

  Future<bool> isStale() async {
    final database = await db;
    final row = await database.query(
      'meals_cache',
      columns: ['cached_at'],
      orderBy: 'cached_at DESC',
      limit: 1,
    );
    if (row.isEmpty) return true;
    final cachedAt = row.first['cached_at'] as int? ?? 0;
    return DateTime.now().millisecondsSinceEpoch - cachedAt >
        cacheTtl.inMilliseconds;
  }

  Map<String, dynamic> _mealToJson(Meal m) => {
        'id': m.id,
        'name': m.name,
        'subtitle': m.subtitle,
        'price': m.price,
        'promo_price': m.promoPrice,
        'has_promo': m.hasPromo,
        'rating': m.rating,
        'image': m.image,
        'category': m.category,
        'is_available': m.isAvailable,
        'is_special': m.isSpecial,
        'seller_id': m.sellerId,
        'seller_name': m.sellerName,
        'seller_lat': m.sellerLat,
        'seller_lng': m.sellerLng,
        'reviews_count': m.reviewsCount,
        'gallery': m.gallery,
      };

  Meal _mealFromJson(Map<String, dynamic> json) => Meal(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0,
        promoPrice: (json['promo_price'] as num?)?.toDouble() ?? 0,
        hasPromo: json['has_promo'] as bool? ?? false,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        image: json['image'] as String? ?? '',
        accent: ChezMamaTheme.brandOrange,
        category: json['category'] as String? ?? '',
        isAvailable: json['is_available'] as bool? ?? true,
        isSpecial: json['is_special'] as bool? ?? false,
        sellerId: json['seller_id'] as int?,
        sellerName: json['seller_name'] as String? ?? '',
        sellerLat: (json['seller_lat'] as num?)?.toDouble(),
        sellerLng: (json['seller_lng'] as num?)?.toDouble(),
        reviewsCount: json['reviews_count'] as int? ?? 0,
        gallery: (json['gallery'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}
