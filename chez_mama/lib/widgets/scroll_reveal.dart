import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// Premium scroll-driven reveal.
///
/// As the child enters the viewport from the bottom, it continuously fades,
/// slides up, scales up and tilts back into place — all mapped to the live
/// scroll position (not a one-shot timer). The effect plays both ways, so
/// scrolling up "re-arms" items for a cohesive, high-end feel.
///
/// Give it the [controller] of the enclosing scroll view so it can recompute
/// on every scroll tick. It reads its own render position each frame, so it
/// works inside slivers, lists and columns without knowing its index.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.controller,
    required this.child,
    this.slide = 56,
    this.minScale = 0.90,
    this.tilt = 0.14,
    this.blur = 0,
    this.horizontal = 0,
    this.enterAt = 0.96,
    this.settleAt = 0.72,
    this.curve = Curves.easeOutCubic,
  });

  /// Scroll controller of the surrounding scrollable.
  final ScrollController controller;
  final Widget child;

  /// Vertical travel (px) applied while hidden.
  final double slide;

  /// Scale while fully hidden (1.0 = no scale).
  final double minScale;

  /// Max back-tilt in radians while hidden (3D perspective).
  final double tilt;

  /// Max gaussian blur (sigma) while hidden. 0 disables (cheaper).
  final double blur;

  /// Horizontal travel (px) while hidden. Signed for left/right entrance.
  final double horizontal;

  /// Fraction of screen height at which the item starts revealing
  /// (1.0 = very bottom edge).
  final double enterAt;

  /// Fraction of screen height at which the item is fully revealed.
  final double settleAt;

  final Curve curve;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  final ValueNotifier<double> _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_recompute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  @override
  void didUpdateWidget(covariant ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_recompute);
      widget.controller.addListener(_recompute);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_recompute);
    _t.dispose();
    super.dispose();
  }

  void _recompute() {
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached) return;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return;

    final screenH = media.size.height;
    final topY = render.localToGlobal(Offset.zero).dy;

    final enterY = screenH * widget.enterAt;
    final settleY = screenH * widget.settleAt;
    final span = (enterY - settleY).abs();
    if (span < 1) return;

    // 0 when the item top sits at/below the enter line, 1 once it reaches
    // the settle line. Clamped so it stays revealed further up.
    final raw = ((enterY - topY) / span).clamp(0.0, 1.0);
    final eased = widget.curve.transform(raw);

    if ((eased - _t.value).abs() > 0.002 || eased == 0 || eased == 1) {
      _t.value = eased;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recompute after this frame's layout so freshly-built (scrolled-in)
    // items start hidden instead of popping in at full opacity.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _recompute();
    });

    return ValueListenableBuilder<double>(
      valueListenable: _t,
      builder: (context, t, child) {
        final inv = 1 - t;
        final scale = widget.minScale + (1 - widget.minScale) * t;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..translateByDouble(widget.horizontal * inv, widget.slide * inv, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1)
          ..rotateX(widget.tilt * inv);

        Widget content = Transform(
          alignment: Alignment.topCenter,
          transform: matrix,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );

        if (widget.blur > 0 && inv > 0.01) {
          content = ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: widget.blur * inv,
              sigmaY: widget.blur * inv,
            ),
            child: content,
          );
        }
        return content;
      },
      child: widget.child,
    );
  }
}
