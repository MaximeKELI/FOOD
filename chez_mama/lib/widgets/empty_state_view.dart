import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../ui/chezmama_theme.dart';
import 'food_card.dart';

/// Branded empty / error state with optional Lottie animation.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.lottieAsset,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
    this.wrapInCard = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? lottieAsset;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool compact;
  final bool wrapInCard;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final animationSize = compact ? 120.0 : 160.0;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (lottieAsset != null)
          SizedBox(
            width: animationSize,
            height: animationSize,
            child: Lottie.asset(
              lottieAsset!,
              fit: BoxFit.contain,
              repeat: true,
              errorBuilder: (_, __, ___) => _IconFallback(icon: icon, compact: compact),
            ),
          )
        else
          _IconFallback(icon: icon, compact: compact),
        SizedBox(height: compact ? ChezMamaTheme.spaceSm : ChezMamaTheme.spaceLg),
        Text(
          title,
          style: (compact ? t.textTheme.titleMedium : t.textTheme.titleLarge)?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: t.textTheme.bodyMedium?.copyWith(
            color: ChezMamaTheme.mutedInk(context),
          ),
          textAlign: TextAlign.center,
        ),
        if (onAction != null || onSecondaryAction != null) ...[
          SizedBox(height: compact ? ChezMamaTheme.spaceMd : ChezMamaTheme.spaceLg),
          if (onAction != null)
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel ?? ''),
            ),
          if (onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onSecondaryAction,
              child: Text(secondaryActionLabel ?? ''),
            ),
          ],
        ],
      ],
    );

    if (!wrapInCard) {
      return Padding(
        padding: EdgeInsets.all(compact ? ChezMamaTheme.spaceMd : ChezMamaTheme.spaceXl),
        child: content,
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? ChezMamaTheme.spaceMd : ChezMamaTheme.spaceXl),
        child: FoodCard(
          padding: EdgeInsets.all(compact ? ChezMamaTheme.spaceMd : ChezMamaTheme.spaceXl),
          shadowOpacity: 0.08,
          child: content,
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.icon, this.compact = false});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 64.0 : 88.0;
    final iconSize = compact ? 30.0 : 40.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ChezMamaTheme.brandOrange.withValues(alpha: 0.10),
        border: Border.all(
          color: ChezMamaTheme.brandAmber.withValues(alpha: 0.35),
        ),
      ),
      child: Icon(icon, size: iconSize, color: ChezMamaTheme.brandBrown),
    );
  }
}

/// Shared Lottie asset paths for empty states.
abstract final class LottieAssets {
  static const empty = 'assets/lottie/empty_box.json';
}
