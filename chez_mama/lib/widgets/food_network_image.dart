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
  });

  final String url;
  final BoxFit fit;
  final FilterQuality filterQuality;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!url.startsWith('http')) {
      return placeholder ?? _defaultPlaceholder(context);
    }
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      filterQuality: filterQuality,
      placeholder: (_, __) => placeholder ?? _defaultPlaceholder(context),
      errorWidget: (_, __, ___) => placeholder ?? _defaultPlaceholder(context),
    );
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _defaultPlaceholder(BuildContext context) {
    return Container(
      color: ChezMamaTheme.brandOrange.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: const Icon(Icons.restaurant_rounded, color: ChezMamaTheme.brandOrange),
    );
  }
}
