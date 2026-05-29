import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/pressable_scale.dart';

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

  Widget _buildMealImage(String source) {
    if (source.startsWith('assets/')) {
      return Image.asset(
        source,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    }
    return Image.network(
      source,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      errorBuilder: (context, error, stackTrace) {
        return _ImageFallback(accent: widget.meal.accent);
      },
    );
  }

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
          decoration: BoxDecoration(
            color: ChezMamaTheme.cardColor(context),
            borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
            boxShadow: pressed
                ? ChezMamaTheme.softShadow(opacity: 0.16)
                : ChezMamaTheme.softShadow(opacity: 0.10),
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
                        _buildMealImage(m.image),
                        if (!m.isAvailable)
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            alignment: Alignment.center,
                            child: const _Pill(
                              label: 'Épuisé',
                              color: Color(0xFF8A8A8A),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Row(
                            children: [
                              if (m.isSpecial)
                                const _Pill(
                                  label: 'Plat du jour',
                                  color: ChezMamaTheme.brandBrown,
                                  icon: Icons.local_fire_department_rounded,
                                ),
                              if (m.isSpecial && m.hasPromo)
                                const SizedBox(width: 6),
                              if (m.hasPromo)
                                _Pill(
                                  label:
                                      '-${(100 - (m.promoPrice / m.price * 100)).round()}%',
                                  color: const Color(0xFFD7263D),
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
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
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
                        Text(
                          m.sellerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.bodySmall?.copyWith(
                            color: ChezMamaTheme.mutedInk(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
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
                              '${m.price.round()} FCFA',
                              style: t.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: ChezMamaTheme.mutedInk(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            '${m.effectivePrice.round()} FCFA',
                            style: t.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: ChezMamaTheme.brandBrown,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color, this.icon});
  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.22),
            ChezMamaTheme.surface2,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: 42,
          color: ChezMamaTheme.brandBrown.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

