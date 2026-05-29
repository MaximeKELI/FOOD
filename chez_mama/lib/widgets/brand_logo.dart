import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// App logo with optional badge container — used in splash and shell AppBar.
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 30,
    this.radius = 9,
    this.showShadow = false,
  });

  final double size;
  final double radius;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow
            ? ChezMamaTheme.softShadow(opacity: 0.14)
            : null,
        gradient: ChezMamaTheme.brandGradient,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
