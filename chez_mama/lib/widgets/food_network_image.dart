import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';

/// Cached network image with consistent placeholder and error handling.
class FoodNetworkImage extends StatelessWidget {
  const FoodNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.filterQuality = FilterQuality.low,
    this.placeholder,
    this.borderRadius,
    this.accent,
    this.memCacheWidth,
  });

  final String url;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final BorderRadius? borderRadius;
  final Color? accent;
  final int? memCacheWidth;

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      final image = Image.asset(url, fit: fit, filterQuality: filterQuality);
      if (borderRadius != null) {
        return ClipRRect(borderRadius: borderRadius!, child: image);
      }
      return image;
    }
    if (!url.startsWith('http')) {
      return placeholder ?? _gradientPlaceholder(context);
    }
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      filterQuality: filterQuality,
      memCacheWidth: memCacheWidth,
      placeholder: (_, __) => placeholder ?? _gradientPlaceholder(context),
      errorWidget: (_, __, ___) => placeholder ?? _gradientPlaceholder(context),
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _gradientPlaceholder(BuildContext context) {
    final base = accent ?? ChezMamaTheme.brandOrange;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: 0.28),
            ChezMamaTheme.subtleSurface(context),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 36,
          color: ChezMamaTheme.brandBrown.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
