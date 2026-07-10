import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// A luxurious animated brand logo.
///
/// Layers a pulsing radial halo, a slowly counter-rotating gilded ring, the
/// logo itself (optionally spinning) and a sweeping metallic shimmer. Designed
/// to be the centrepiece of the splash screen but light enough for an AppBar.
class AnimatedBrandLogo extends StatefulWidget {
  const AnimatedBrandLogo({
    super.key,
    this.size = 104,
    this.radius = 26,
    this.spin = true,
    this.showHalo = true,
    this.showRing = true,
    this.spinPeriod = const Duration(seconds: 14),
  });

  final double size;
  final double radius;

  /// Rotate the logo tile itself (subtle continuous spin).
  final bool spin;

  /// Pulsing brand-coloured glow behind the logo.
  final bool showHalo;

  /// Counter-rotating gilded ring around the logo.
  final bool showRing;

  final Duration spinPeriod;

  @override
  State<AnimatedBrandLogo> createState() => _AnimatedBrandLogoState();
}

class _AnimatedBrandLogoState extends State<AnimatedBrandLogo>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: widget.spinPeriod,
  )..repeat();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final ringSize = s * 1.34;
    final haloSize = s * 1.9;

    return SizedBox(
      width: haloSize,
      height: haloSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.showHalo)
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(_pulse.value);
                return Container(
                  width: haloSize * (0.82 + 0.18 * t),
                  height: haloSize * (0.82 + 0.18 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ChezMamaTheme.haloGradient(context),
                  ),
                );
              },
            ),
          if (widget.showRing)
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) {
                return Transform.rotate(
                  angle: -_spin.value * 2 * math.pi,
                  child: CustomPaint(
                    size: Size.square(ringSize),
                    painter: _GildedRingPainter(),
                  ),
                );
              },
            ),
          AnimatedBuilder(
            animation: _spin,
            builder: (context, child) {
              final angle =
                  widget.spin ? _spin.value * 2 * math.pi : 0.0;
              return Transform.rotate(angle: angle, child: child);
            },
            child: _LogoTile(size: s, radius: widget.radius, shimmer: _shimmer),
          ),
        ],
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile({
    required this.size,
    required this.radius,
    required this.shimmer,
  });

  final double size;
  final double radius;
  final Animation<double> shimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: ChezMamaTheme.brandGradient,
        boxShadow: ChezMamaTheme.glowShadow(
          ChezMamaTheme.brandOrange,
          opacity: 0.5,
          blur: 34,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
          // Sweeping metallic shimmer across the logo.
          AnimatedBuilder(
            animation: shimmer,
            builder: (context, _) {
              final v = shimmer.value;
              return FractionallySizedBox(
                widthFactor: 1,
                heightFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.4 + 3 * v, -1),
                      end: Alignment(-0.4 + 3 * v, 1),
                      colors: [
                        Colors.white.withValues(alpha: 0.0),
                        Colors.white.withValues(alpha: 0.42),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GildedRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.width / 2;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..shader = SweepGradient(
        colors: const [
          Color(0x00E7B84B),
          ChezMamaTheme.gold,
          ChezMamaTheme.goldLight,
          ChezMamaTheme.gold,
          Color(0x00E7B84B),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, ringPaint);

    // Gilded dots orbiting the ring.
    final dotPaint = Paint()..color = ChezMamaTheme.goldLight;
    for (int i = 0; i < 3; i++) {
      final a = (i / 3) * 2 * math.pi;
      final o = Offset(
        center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a),
      );
      canvas.drawCircle(o, 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GildedRingPainter oldDelegate) => false;
}
