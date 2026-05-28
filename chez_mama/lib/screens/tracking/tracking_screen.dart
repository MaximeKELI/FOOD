import 'package:flutter/material.dart';
import '../../ui/chezmama_theme.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi commande')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #CM-2041',
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _StatusProgress(value: 0.62),
            const SizedBox(height: 16),
            Text(
              'Ton livreur arrive…',
              style: t.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: ChezMamaTheme.ink.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: ChezMamaTheme.softShadow(opacity: 0.10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Hook point: replace this with Google Maps / Mapbox.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                ChezMamaTheme.brandOrange
                                    .withValues(alpha: 0.08),
                                ChezMamaTheme.brandAmber
                                    .withValues(alpha: 0.10),
                                Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _RoutePainter(
                            color: ChezMamaTheme.brandBrown
                                .withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) {
                          final v = Curves.easeInOut.transform(_c.value);
                          return Positioned(
                            left: 36 + (220 * v),
                            top: 70 + (140 * (1 - v)),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: ChezMamaTheme.brandOrange,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow:
                                    ChezMamaTheme.softShadow(opacity: 0.16),
                              ),
                              child: const Icon(
                                Icons.delivery_dining_rounded,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      const Positioned(
                        left: 28,
                        top: 200,
                        child: _Pin(label: 'Restaurant'),
                      ),
                      const Positioned(
                        right: 22,
                        bottom: 26,
                        child: _Pin(label: 'Toi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusProgress extends StatelessWidget {
  const _StatusProgress({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ChezMamaTheme.surface2,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Préparation → En route → Livré',
                  style: t.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: t.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: ChezMamaTheme.brandBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 10,
                  backgroundColor:
                      ChezMamaTheme.brandBrown.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation(
                    ChezMamaTheme.brandOrange,
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: ChezMamaTheme.softShadow(opacity: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: ChezMamaTheme.brandOrange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: t.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(44, size.height * 0.62)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.35,
        size.width * 0.60,
        size.height * 0.75,
        size.width - 56,
        size.height - 58,
      );

    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

