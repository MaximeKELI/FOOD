import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/food_network_image.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/status_pill.dart';

class MealCard extends StatefulWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
    this.distanceKm,
  });

  final Meal meal;
  final VoidCallback onTap;
  final double? distanceKm;

  @override
  State<MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<MealCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final m = widget.meal;

    return PressableScale(
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
            shadowOpacity: pressed ? 0.16 : 0.10,
            border: Border.all(
              color: ChezMamaTheme.brandOrange.withValues(alpha: pressed ? 0.18 : 0.06),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'meal_${m.id}',
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FoodNetworkImage(
                          url: m.image,
                          accent: m.accent,
                        ),
                        if (!m.isAvailable)
                          Container(
                            color: Colors.black.withValues(alpha: 0.48),
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
                          child: Row(
                            children: [
                              if (m.isSpecial)
                                StatusPill(
                                  label: tr('home.filter.special'),
                                  color: ChezMamaTheme.brandBrown,
                                  icon: Icons.local_fire_department_rounded,
                                ),
                              if (m.isSpecial && m.hasPromo)
                                const SizedBox(width: 6),
                              if (m.hasPromo)
                                StatusPill(
                                  label:
                                      '-${(100 - (m.promoPrice / m.price * 100)).round()}%',
                                  color: ChezMamaTheme.promoRed,
                                  icon: Icons.sell_rounded,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ChezMamaTheme.spaceMd,
                    12,
                    ChezMamaTheme.spaceMd,
                    ChezMamaTheme.spaceMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (m.sellerName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 13,
                              color: ChezMamaTheme.mutedInk(context),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                m.sellerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: t.textTheme.bodySmall?.copyWith(
                                  color: ChezMamaTheme.mutedInk(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: ChezMamaTheme.spaceSm),
                      Row(
                        children: [
                          if (m.rating > 0) ...[
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: ChezMamaTheme.brandAmber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              m.rating.toStringAsFixed(1),
                              style: t.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (widget.distanceKm != null) ...[
                            Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: ChezMamaTheme.mutedInk(context),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${widget.distanceKm!.toStringAsFixed(1)} km',
                              style: t.textTheme.bodySmall?.copyWith(
                                color: ChezMamaTheme.mutedInk(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                          ] else
                            const Spacer(),
                          if (m.hasPromo && m.promoPrice > 0) ...[
                            Text(
                              formatFcfa(m.price),
                              style: t.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: ChezMamaTheme.mutedInk(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            formatFcfa(m.effectivePrice),
                            style: ChezMamaTheme.priceStyle(
                              context,
                              t,
                              promo: m.hasPromo,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
