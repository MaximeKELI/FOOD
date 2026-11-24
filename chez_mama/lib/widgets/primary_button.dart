import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

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
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      label: widget.label,
      enabled: enabled,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          final s = 1 + (0.05 * Curves.elasticOut.transform(_c.value));
          return Transform.scale(scale: s, child: child);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    _bounce();
                    widget.onPressed!();
                  }
                : null,
            borderRadius: BorderRadius.circular(ChezMamaTheme.rButton),
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                gradient: enabled ? ChezMamaTheme.brandGradient : null,
                color: enabled
                    ? null
                    : ChezMamaTheme.brandOrange.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(ChezMamaTheme.rButton),
                boxShadow: enabled
                    ? ChezMamaTheme.glowShadow(
                        ChezMamaTheme.brandOrange,
                        opacity: 0.35,
                        blur: 20,
                        offset: const Offset(0, 8),
                      )
                    : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon ?? Icons.add_shopping_cart_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
