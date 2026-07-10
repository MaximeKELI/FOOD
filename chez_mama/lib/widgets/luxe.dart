import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// Text painted with an animated sweeping metallic-gold shimmer.
class ShimmerText extends StatefulWidget {
  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.period = const Duration(milliseconds: 2600),
    this.baseColor,
  });

  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Duration period;
  final Color? baseColor;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? ChezMamaTheme.inkColor(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) {
            final dx = rect.width * (_c.value * 2 - 0.5);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                base,
                base,
                ChezMamaTheme.goldLight,
                ChezMamaTheme.gold,
                base,
                base,
              ],
              stops: const [0.0, 0.35, 0.46, 0.54, 0.65, 1.0],
              transform: _SlideGradient(dx / rect.width),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style, textAlign: widget.textAlign),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.slide);
  final double slide;
  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slide, 0, 0);
  }
}

/// Frosted-glass container with a real backdrop blur.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = ChezMamaTheme.rCard,
    this.blur = 18,
    this.opacity = 0.14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: ChezMamaTheme.glassDecoration(
            context,
            radius: radius,
            opacity: opacity,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// A premium CTA: brand gradient fill, soft glow, and a light gloss that
/// sweeps across on an idle loop and on press.
class ShineButton extends StatefulWidget {
  const ShineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.gradient,
    this.height = 54,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final Gradient? gradient;
  final double height;

  @override
  State<ShineButton> createState() => _ShineButtonState();
}

class _ShineButtonState extends State<ShineButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  )..repeat();
  double _scale = 1;

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final gradient = widget.gradient ?? ChezMamaTheme.brandGradient;

    final button = AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 120),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ChezMamaTheme.rButton),
          gradient: enabled
              ? gradient
              : LinearGradient(colors: [
                  ChezMamaTheme.soldOutGray.withValues(alpha: 0.5),
                  ChezMamaTheme.soldOutGray.withValues(alpha: 0.5),
                ]),
          boxShadow: enabled
              ? ChezMamaTheme.glowShadow(ChezMamaTheme.brandOrange,
                  opacity: 0.45, blur: 24)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _sweep,
              builder: (context, _) {
                final v = _sweep.value;
                return Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1.6 + 3.2 * v, 0),
                        end: Alignment(-1.1 + 3.2 * v, 0),
                        colors: [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.28),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _scale = 0.96) : null,
        onTapUp: enabled ? (_) => setState(() => _scale = 1) : null,
        onTapCancel: enabled ? () => setState(() => _scale = 1) : null,
        onTap: widget.onPressed,
        child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

/// Subtle breathing pulse — gently scales its child up and down forever.
class Breathing extends StatefulWidget {
  const Breathing({
    super.key,
    required this.child,
    this.min = 0.98,
    this.max = 1.02,
    this.period = const Duration(milliseconds: 2400),
  });

  final Widget child;
  final double min;
  final double max;
  final Duration period;

  @override
  State<Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: widget.min, end: widget.max).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: widget.child,
    );
  }
}

/// Ambient drifting golden motes behind hero sections. Cheap, decorative.
class FloatingMotes extends StatefulWidget {
  const FloatingMotes({super.key, this.count = 18, this.color});
  final int count;
  final Color? color;

  @override
  State<FloatingMotes> createState() => _FloatingMotesState();
}

class _FloatingMotesState extends State<FloatingMotes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  )..repeat();

  late final List<_Mote> _motes = List.generate(
    widget.count,
    (i) => _Mote(
      x: math.Random(i * 7).nextDouble(),
      y: math.Random(i * 13).nextDouble(),
      r: 1.2 + math.Random(i * 17).nextDouble() * 2.6,
      speed: 0.3 + math.Random(i * 19).nextDouble() * 0.8,
      phase: math.Random(i * 23).nextDouble(),
    ),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _MotesPainter(
              _motes,
              _c.value,
              widget.color ?? ChezMamaTheme.goldLight,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _Mote {
  _Mote({
    required this.x,
    required this.y,
    required this.r,
    required this.speed,
    required this.phase,
  });
  final double x, y, r, speed, phase;
}

class _MotesPainter extends CustomPainter {
  _MotesPainter(this.motes, this.t, this.color);
  final List<_Mote> motes;
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in motes) {
      final progress = (t * m.speed + m.phase) % 1.0;
      final dy = m.y * size.height - progress * size.height * 0.6;
      final wrapY = dy % size.height;
      final dx = (m.x * size.width) +
          math.sin((progress + m.phase) * 2 * math.pi) * 14;
      final alpha = (math.sin(progress * math.pi)).clamp(0.0, 1.0) * 0.6;
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.5);
      canvas.drawCircle(Offset(dx, wrapY), m.r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MotesPainter oldDelegate) => true;
}
