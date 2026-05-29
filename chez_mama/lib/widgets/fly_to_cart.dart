import 'dart:ui';
import 'package:flutter/material.dart';

/// “Item flies to cart” micro-interaction.
///
/// Usage:
/// - Give your cart icon a [cartIconKey]
/// - Call [FlyToCartController.flyFromRect] with the tapped card image bounds
class FlyToCartController {
  FlyToCartController(this.overlay);

  final OverlayState overlay;

  void flyFromRect({
    required Rect from,
    required GlobalKey cartIconKey,
    required Color color,
    VoidCallback? onComplete,
  }) {
    final cartBox =
        cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartBox == null) return;

    final cartPos = cartBox.localToGlobal(Offset.zero);
    final to = Rect.fromCenter(
      center: cartPos + cartBox.size.center(Offset.zero),
      width: 18,
      height: 18,
    );

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return _FlyDot(
          from: from,
          to: to,
          color: color,
          onDone: () {
            entry.remove();
            onComplete?.call();
          },
        );
      },
    );
    overlay.insert(entry);
  }
}

class _FlyDot extends StatefulWidget {
  const _FlyDot({
    required this.from,
    required this.to,
    required this.color,
    required this.onDone,
  });

  final Rect from;
  final Rect to;
  final Color color;
  final VoidCallback onDone;

  @override
  State<_FlyDot> createState() => _FlyDotState();
}

class _FlyDotState extends State<_FlyDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubicEmphasized);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: a,
        builder: (context, _) {
          final t = a.value;
          final p = lerpDouble(widget.from.center.dx, widget.to.center.dx, t)!;
          final q = lerpDouble(widget.from.center.dy, widget.to.center.dy, t)!;
          final s = lerpDouble(1.0, 0.2, t)!;
          final o = lerpDouble(1.0, 0.0, t)!;

          return Positioned(
            left: p - 10,
            top: q - 10,
            child: Opacity(
              opacity: o,
              child: Transform.scale(
                scale: s,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

