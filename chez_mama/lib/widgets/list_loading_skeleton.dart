import 'package:flutter/material.dart';

import '../ui/chezmama_theme.dart';
import 'shimmer_skeleton.dart';

/// Generic list shimmer used while data loads.
class ListLoadingSkeleton extends StatelessWidget {
  const ListLoadingSkeleton({
    super.key,
    this.itemCount = 4,
    this.imageHeight = 150,
  });

  final int itemCount;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.all(ChezMamaTheme.spaceMd),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: ChezMamaTheme.spaceMd),
        itemBuilder: (_, __) => Column(
          children: [
            SkeletonBox(
              width: double.infinity,
              height: imageHeight,
              radius: ChezMamaTheme.rCard,
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: SkeletonBox(width: 1, height: 16, radius: 8)),
                SizedBox(width: 14),
                SkeletonBox(width: 98, height: 40, radius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
