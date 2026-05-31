import 'package:flutter/material.dart';

/// Cart tab icon with fly-to-cart bounce feedback.
class CartNavIcon extends StatelessWidget {
  const CartNavIcon({
    super.key,
    required this.icon,
    required this.count,
    required this.bounceGeneration,
    required this.cartIconKey,
  });

  final IconData icon;
  final int count;
  final int bounceGeneration;
  final GlobalKey cartIconKey;

  @override
  Widget build(BuildContext context) {
    final inner = count > 0
        ? Badge.count(count: count, child: Icon(icon))
        : Icon(icon);

    return TweenAnimationBuilder<double>(
      key: ValueKey('cart-bounce-$bounceGeneration'),
      tween: Tween(begin: 1.22, end: 1.0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: KeyedSubtree(key: cartIconKey, child: inner),
    );
  }
}
