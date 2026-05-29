import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chez_mama/cart/cart_service.dart';
import 'package:chez_mama/models/meal.dart';

Meal _sampleMeal({
  String id = '42',
  bool isAvailable = true,
  double price = 2500,
  double promoPrice = 0,
  bool hasPromo = false,
}) {
  return Meal(
    id: id,
    name: 'Thieb',
    subtitle: 'Riz au poisson',
    price: price,
    promoPrice: promoPrice,
    hasPromo: hasPromo,
    rating: 4.5,
    image: 'https://example.com/thieb.jpg',
    accent: Colors.orange,
    category: 'Plats',
    isAvailable: isAvailable,
  );
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await CartService.instance.init();
  });

  setUp(() {
    CartService.instance.clear();
  });

  test('addMeal increases count and total', () {
    final cart = CartService.instance;
    expect(cart.addMeal(_sampleMeal()), isTrue);
    expect(cart.count, 1);
    expect(cart.total, 2500);

    cart.increment(42);
    expect(cart.count, 2);
    expect(cart.total, 5000);
  });

  test('addMeal rejects unavailable meals and invalid ids', () {
    final cart = CartService.instance;
    expect(cart.addMeal(_sampleMeal(isAvailable: false)), isFalse);
    expect(cart.addMeal(_sampleMeal(id: 'abc')), isFalse);
    expect(cart.isEmpty, isTrue);
  });

  test('decrement removes line when quantity reaches zero', () {
    final cart = CartService.instance;
    cart.addMeal(_sampleMeal());
    cart.decrement(42);
    expect(cart.isEmpty, isTrue);
  });

  test('toOrderItems matches cart contents', () {
    final cart = CartService.instance;
    cart.addMeal(_sampleMeal());
    cart.increment(42);
    expect(cart.toOrderItems(), [
      {'meal': 42, 'quantity': 2},
    ]);
  });

  test('uses promo price for line total', () {
    final cart = CartService.instance;
    cart.addMeal(
      _sampleMeal(price: 3000, promoPrice: 2000, hasPromo: true),
    );
    expect(cart.total, 2000);
  });
}
