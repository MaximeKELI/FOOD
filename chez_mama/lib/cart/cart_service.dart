import 'package:flutter/foundation.dart';

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
}

/// Simple in-memory cart shared across the app.
class CartService extends ChangeNotifier {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get count => _items.fold(0, (sum, i) => sum + i.quantity);

  int get total => _items.fold(0, (sum, i) => sum + i.lineTotal);

  bool get isEmpty => _items.isEmpty;

  void addMeal(Meal meal) {
    final id = int.tryParse(meal.id) ?? meal.id.hashCode;
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
  }

  void increment(int mealId) {
    for (final i in _items) {
      if (i.mealId == mealId) i.quantity += 1;
    }
    notifyListeners();
  }

  void decrement(int mealId) {
    for (final i in _items) {
      if (i.mealId == mealId) i.quantity -= 1;
    }
    _items.removeWhere((i) => i.quantity <= 0);
    notifyListeners();
  }

  void removeItem(int mealId) {
    _items.removeWhere((i) => i.mealId == mealId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Payload for the orders API.
  List<Map<String, dynamic>> toOrderItems() {
    return _items
        .map((i) => {'meal': i.mealId, 'quantity': i.quantity})
        .toList();
  }

  List<int> get mealIds => _items.map((i) => i.mealId).toList();
}
