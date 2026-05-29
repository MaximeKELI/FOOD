import 'package:flutter/material.dart';

import '../widgets/fly_to_cart.dart';

/// Wires the fly-to-cart animation to the bottom-nav cart icon.
class CartFlyService {
  CartFlyService._();
  static final CartFlyService instance = CartFlyService._();

  final cartIconKey = GlobalKey();

  void flyFromContext(BuildContext fromContext, {required Color color}) {
    final overlay = Overlay.maybeOf(fromContext, rootOverlay: true);
    if (overlay == null) return;

    final box = fromContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final origin = box.localToGlobal(Offset.zero);
    final from = origin & box.size;

    FlyToCartController(overlay).flyFromRect(
      from: from,
      cartIconKey: cartIconKey,
      color: color,
    );
  }
}
