import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/pressable_scale.dart';

class MealCard extends StatefulWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onTap,
  });

  final Meal meal;
  final VoidCallback onTap;

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
            boxShadow:
                pressed ? ChezMamaTheme.softShadow(opacity: 0.16) : ChezMamaTheme.softShadow(opacity: 0.10),
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
                    child: _buildMealImage(m.image),
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

