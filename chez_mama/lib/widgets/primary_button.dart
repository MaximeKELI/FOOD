import 'package:flutter/material.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      lowerBound: 0,
      upperBound: 1,
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _bounce() {
    _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.onPressed != null,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final s = 1 + (0.06 * Curves.elasticOut.transform(_c.value));
          return Transform.scale(scale: s, child: child);
        },
        child: FilledButton.icon(
          onPressed: widget.onPressed == null
              ? null
              : () {
                  _bounce();
                  widget.onPressed!();
                },
          icon: Icon(widget.icon ?? Icons.add_shopping_cart_rounded, size: 20),
          label: Text(widget.label),
        ),
      ),
    );
  }
}
