import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// Elevated surface card used across the app for consistent shadows and radius.
class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = ChezMamaTheme.rCard,
    this.color,
    this.shadowOpacity = 0.10,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final double shadowOpacity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: ChezMamaTheme.cardDecoration(
        context,
        radius: radius,
        shadowOpacity: shadowOpacity,
        color: color,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
