import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../ui/chezmama_theme.dart';

class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark
          ? ChezMamaTheme.darkSurface2
          : ChezMamaTheme.ink.withValues(alpha: 0.06),
      highlightColor: isDark
          ? ChezMamaTheme.darkCard
          : ChezMamaTheme.ink.withValues(alpha: 0.12),
      child: child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.radius = 14,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: ChezMamaTheme.cardColor(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
