import 'package:flutter/material.dart';

/// Premium "reveal on scroll" entrance.
///
/// The child starts hidden (faded, shifted down, slightly scaled and tilted)
/// and plays a single, smooth entrance the first time it enters the viewport
/// while scrolling. Once revealed it stays perfectly crisp — so nothing ever
/// gets stuck half-visible at the edges of the screen.
///
/// Pass the [controller] of the surrounding scrollable and, optionally, an
/// [index] to stagger a batch of items that appear together (e.g. the first
/// screenful on load).
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.controller,
    required this.child,
    this.index = 0,
    this.slide = 60,
    this.minScale = 0.92,
    this.tilt = 0.12,
    this.horizontal = 0,
    this.duration = const Duration(milliseconds: 620),
    this.stagger = const Duration(milliseconds: 70),
    this.triggerFraction = 0.90,
    this.curve = Curves.easeOutCubic,
  });

  /// Scroll controller of the surrounding scrollable.
  final ScrollController controller;
  final Widget child;

  /// Stagger index for batched items (clamped internally).
  final int index;

  /// Vertical travel (px) while hidden.
  final double slide;

  /// Scale while fully hidden (1.0 = no scale).
  final double minScale;

  /// Back-tilt in radians while hidden (3D perspective).
  final double tilt;

  /// Horizontal travel (px) while hidden. Signed for left/right entrance.
  final double horizontal;

  final Duration duration;
  final Duration stagger;

  /// Trigger once the item's top rises above this fraction of the screen
  /// height (0.90 = when it is ~10% up from the bottom edge).
  final double triggerFraction;

  final Curve curve;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _anim =
      CurvedAnimation(parent: _c, curve: widget.curve);
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_maybeTrigger);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeTrigger());
  }

  @override
  void didUpdateWidget(covariant ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_maybeTrigger);
      widget.controller.addListener(_maybeTrigger);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maybeTrigger);
    _c.dispose();
    super.dispose();
  }

  void _maybeTrigger() {
    if (_triggered || !mounted) return;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached) return;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return;

    final screenH = media.size.height;
    final topY = render.localToGlobal(Offset.zero).dy;

    // Fire as soon as the top edge has entered the viewport far enough.
    if (topY <= screenH * widget.triggerFraction) {
      _triggered = true;
      widget.controller.removeListener(_maybeTrigger);
      final delay = widget.stagger * widget.index.clamp(0, 10);
      if (delay == Duration.zero) {
        _c.forward();
      } else {
        Future.delayed(delay, () {
          if (mounted) _c.forward();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check after this frame in case the item was just built into view.
    if (!_triggered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeTrigger();
      });
    }

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final t = _anim.value;
        final inv = 1 - t;
        final scale = widget.minScale + (1 - widget.minScale) * t;

        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..translateByDouble(widget.horizontal * inv, widget.slide * inv, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1)
          ..rotateX(widget.tilt * inv);

        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform(
            alignment: Alignment.topCenter,
            transform: matrix,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
