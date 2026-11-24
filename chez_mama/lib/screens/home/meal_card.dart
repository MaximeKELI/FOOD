import 'package:flutter/material.dart';
import '../../cart/cart_fly_service.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/haptic_utils.dart';
import '../../widgets/accessible_icon_button.dart';
import '../../widgets/food_network_image.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/status_pill.dart';

/// Image-first meal tile: large food photo, social proof, one-tap add.
class MealCard extends StatefulWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.distanceKm,
    this.compact = false,
  });

  final Meal meal;
  final VoidCallback onTap;
  final double? distanceKm;
  final bool compact;

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool pressed = false;
  final _addKey = GlobalKey();

  void _quickAdd() {
    final m = widget.meal;
    if (!m.isAvailable) return;
    final added = CartService.instance.addMeal(m);
    if (!added) return;
    hapticLight();
    final ctx = _addKey.currentContext;
    if (ctx != null) {
      CartFlyService.instance.flyFromContext(ctx, color: m.accent);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(trf('meal.addedToCart', {'name': m.name})),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final m = widget.meal;
    final ratio = widget.compact ? 4 / 5 : 5 / 6;

    return Semantics(
      label: '${m.name}, ${formatFcfa(m.effectivePrice)}'
          '${m.rating > 0 ? ', ${m.rating.toStringAsFixed(1)}' : ''}',
      button: true,
      child: RepaintBoundary(
        child: PressableScale(
          onTap: widget.onTap,
          child: GestureDetector(
            onTapDown: (_) => setState(() => pressed = true),
            onTapUp: (_) => setState(() => pressed = false),
            onTapCancel: () => setState(() => pressed = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              decoration: ChezMamaTheme.cardDecoration(
                context,
                shadowOpacity: pressed ? 0.18 : 0.11,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _maybeHero(
                      enabled: !widget.compact,
                      tag: 'meal_${m.id}',
                      child: AspectRatio(
                        aspectRatio: ratio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FoodNetworkImage(
                              url: m.image,
                              accent: m.accent,
                              memCacheWidth: widget.compact ? 480 : 720,
                            ),
                            // Soft bottom fade so price/title sit on food (desire).
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x99000000),
                                  ],
                                  stops: [0.0, 0.45, 1.0],
                                ),
                              ),
                            ),
                            if (!m.isAvailable)
                              Container(
                                color: Colors.black.withValues(alpha: 0.5),
                                alignment: Alignment.center,
                                child: StatusPill(
                                  label: tr('meal.soldOut'),
                                  color: ChezMamaTheme.soldOutGray,
                                  icon: Icons.block_rounded,
                                ),
                              ),
                            Positioned(
                              top: 10,
                              left: 10,
                              right: 10,
                              child: Row(
                                children: [
                                  if (m.rating > 0)
                                    _ProofChip(
                                      icon: Icons.star_rounded,
                                      label: m.reviewsCount > 0
                                          ? '${m.rating.toStringAsFixed(1)} (${m.reviewsCount})'
                                          : m.rating.toStringAsFixed(1),
                                      color: ChezMamaTheme.brandAmber,
                                    ),
                                  const Spacer(),
                                  if (m.hasPromo)
                                    _ProofChip(
                                      icon: Icons.local_offer_rounded,
                                      label:
                                          '-${(100 - (m.promoPrice / m.price * 100)).round()}%',
                                      color: ChezMamaTheme.promoRed,
                                    ),
                                ],
                              ),
                            ),
                            if (m.isSpecial)
                              Positioned(
                                top: m.rating > 0 || m.hasPromo ? 42 : 10,
                                left: 10,
                                child: _ProofChip(
                                  icon: Icons.local_fire_department_rounded,
                                  label: tr('home.filter.special'),
                                  color: ChezMamaTheme.brandBrown,
                                ),
                              ),
                            Positioned(
                              left: 12,
                              right: 8,
                              bottom: 10,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          m.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style:
                                              t.textTheme.titleMedium?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x66000000),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (m.hasPromo &&
                                                m.promoPrice > 0) ...[
                                              Text(
                                                formatFcfa(m.price),
                                                style: t.textTheme.bodySmall
                                                    ?.copyWith(
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Text(
                                              formatFcfa(m.effectivePrice),
                                              style: t.textTheme.titleSmall
                                                  ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            if (m.prepTimeMinutes != null) ...[
                                              const SizedBox(width: 8),
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 13,
                                                color: Colors.white
                                                    .withValues(alpha: 0.85),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${m.prepTimeMinutes} min',
                                                style: t.textTheme.labelSmall
                                                    ?.copyWith(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (m.isAvailable)
                                    KeyedSubtree(
                                      key: _addKey,
                                      child: Material(
                                        color: Colors.white,
                                        elevation: 2,
                                        shape: const CircleBorder(),
                                        child: AccessibleIconButton(
                                          icon: Icons.add_rounded,
                                          label: tr('action.addToCart'),
                                          color: ChezMamaTheme.brandOrange,
                                          onPressed: _quickAdd,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!widget.compact)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 14,
                              color: ChezMamaTheme.mutedInk(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                m.sellerName.isNotEmpty
                                    ? m.sellerName
                                    : tr('home.localSeller'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: ChezMamaTheme.mutedInk(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (widget.distanceKm != null) ...[
                              Icon(
                                Icons.near_me_rounded,
                                size: 13,
                                color: ChezMamaTheme.mutedInk(context),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${widget.distanceKm!.toStringAsFixed(1)} km',
                                style: t.textTheme.labelSmall?.copyWith(
                                  color: ChezMamaTheme.mutedInk(context),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _maybeHero({
  required bool enabled,
  required String tag,
  required Widget child,
}) {
  if (!enabled) return child;
  return Hero(tag: tag, child: child);
}

class _ProofChip extends StatelessWidget {
  const _ProofChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
