import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// App logo with optional badge container — used in splash and shell AppBar.
///
/// When [spin] is true the tile rotates slowly with a soft gilded glow, giving
/// the AppBar a subtle premium motion without dominating the layout.
class BrandLogo extends StatefulWidget {
  const BrandLogo({
    super.key,
    this.size = 30,
    this.radius = 9,
    this.showShadow = false,
    this.spin = false,
    this.spinPeriod = const Duration(seconds: 18),
  });

  final double size;
  final double radius;
  final bool showShadow;
  final bool spin;
  final Duration spinPeriod;

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;

  @override
  void initState() {
    super.initState();
    if (widget.spin) {
      _c = AnimationController(vsync: this, duration: widget.spinPeriod)
        ..repeat();
    }
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        boxShadow: widget.showShadow
            ? ChezMamaTheme.softShadow(opacity: 0.14)
            : (widget.spin
                ? ChezMamaTheme.glowShadow(
                    ChezMamaTheme.brandAmber,
                    opacity: 0.4,
                    blur: 14,
                  )
                : null),
        gradient: ChezMamaTheme.brandGradient,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
    );

    if (_c == null) return tile;

    return AnimatedBuilder(
      animation: _c!,
      builder: (context, child) => Transform.rotate(
        angle: _c!.value * 2 * math.pi,
        child: child,
      ),
      child: tile,
    );
  }
}
