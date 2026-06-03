import 'package:flutter/material.dart';

/// Fires [onTap] only when the pointer did not move much (so vertical PageView scroll works).
class ScrollFriendlyTap extends StatefulWidget {
  const ScrollFriendlyTap({
    super.key,
    required this.onTap,
    required this.child,
    this.maxTapDistance = 14,
  });

  final VoidCallback onTap;
  final Widget child;
  final double maxTapDistance;

  @override
  State<ScrollFriendlyTap> createState() => _ScrollFriendlyTapState();
}

class _ScrollFriendlyTapState extends State<ScrollFriendlyTap> {
  Offset? _down;
  bool _moved = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _down = e.position;
        _moved = false;
      },
      onPointerMove: (e) {
        if (_down == null || _moved) return;
        if ((e.position - _down!).distance > widget.maxTapDistance) {
          _moved = true;
        }
      },
      onPointerUp: (_) {
        if (!_moved && _down != null) widget.onTap();
        _down = null;
        _moved = false;
      },
      onPointerCancel: (_) {
        _down = null;
        _moved = false;
      },
      child: widget.child,
    );
  }
}
