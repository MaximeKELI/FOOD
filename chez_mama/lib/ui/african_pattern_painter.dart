import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Lightweight “local identity” texture (no images) for headers.
class AfricanPatternPainter extends CustomPainter {
  AfricanPatternPainter({
    required this.a,
    required this.b,
    required this.c,
  });

  final Color a;
  final Color b;
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = a.withValues(alpha: 0.22);
    final p2 = Paint()..color = b.withValues(alpha: 0.18);
    final p3 = Paint()..color = c.withValues(alpha: 0.14);

    const cell = 22.0;
    for (double y = -cell; y < size.height + cell; y += cell) {
      for (double x = -cell; x < size.width + cell; x += cell) {
        final t = (x / cell + y / cell);
        final r = (t % 3);
        final cx = x + cell * 0.5;
        final cy = y + cell * 0.5;

        if (r == 0) {
          canvas.save();
          canvas.translate(cx, cy);
          canvas.rotate(math.pi / 4);
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: 8, height: 8),
            p1,
          );
          canvas.restore();
        } else if (r == 1) {
          canvas.drawCircle(Offset(cx, cy), 3.5, p2);
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(cx, cy), width: 10, height: 4),
              const Radius.circular(4),
            ),
            p3,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AfricanPatternPainter oldDelegate) {
    return oldDelegate.a != a || oldDelegate.b != b || oldDelegate.c != c;
  }
}

