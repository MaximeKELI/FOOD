import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

class CartItem {
  CartItem({
    required this.mealId,
    required this.name,
    required this.unitPrice,
    required this.image,
    this.quantity = 1,
  });

  final int mealId;
  final String name;
  final int unitPrice;
  final String image;
  int quantity;

  int get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toJson() => {
        'mealId': mealId,
        'name': name,
        'unitPrice': unitPrice,
        'image': image,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        mealId: json['mealId'] as int,
        name: json['name'] as String? ?? '',
        unitPrice: json['unitPrice'] as int? ?? 0,
        image: json['image'] as String? ?? '',
        quantity: json['quantity'] as int? ?? 1,
      );
}

/// Cart shared across the app, persisted locally between sessions.
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  static const _kCartKey = 'cart.items';

  final List<CartItem> _items = [];
  bool _loaded = false;

  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (sum, i) => sum + i.quantity);

  int get total => _items.fold(0, (sum, i) => sum + i.lineTotal);

  bool get isEmpty => _items.isEmpty;

  Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCartKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(
            list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)),
          );
      } catch (_) {
        // Corrupt cache — start fresh.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((i) => i.toJson()).toList());
    await prefs.setString(_kCartKey, encoded);
  }

  /// Returns false when the meal cannot be added (invalid id or unavailable).
  bool addMeal(Meal meal) {
    final id = int.tryParse(meal.id);
    if (id == null || !meal.isAvailable) return false;
    final existing = _items.where((i) => i.mealId == id).toList();
    if (existing.isNotEmpty) {
      existing.first.quantity += 1;
    } else {
      _items.add(
        CartItem(
          mealId: id,
          name: meal.name,
          unitPrice: meal.effectivePrice.round(),
          image: meal.image,
        ),
      );
    }
    notifyListeners();
    _persist();
    return true;
  }

  void increment(int mealId) {
    for (final i in _items) {
      if (i.mealId == mealId) i.quantity += 1;
    }
    notifyListeners();
    _persist();
  }

  void decrement(int mealId) {
    for (final i in _items) {
      if (i.mealId == mealId) i.quantity -= 1;
    }
    _items.removeWhere((i) => i.quantity <= 0);
    notifyListeners();
    _persist();
  }

  void removeItem(int mealId) {
    _items.removeWhere((i) => i.mealId == mealId);
    notifyListeners();
    _persist();
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }

  /// Payload for the orders API.
  List<Map<String, dynamic>> toOrderItems() {
    return _items
        .map((i) => {'meal': i.mealId, 'quantity': i.quantity})
        .toList();
  }

  List<int> get mealIds => _items.map((i) => i.mealId).toList();
}
