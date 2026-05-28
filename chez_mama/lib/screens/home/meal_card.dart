import 'package:flutter/material.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/pressable_scale.dart';
import '../../widgets/primary_button.dart';

class MealCard extends StatefulWidget {
  const MealCard({
    super.key,
    required this.meal,
    required this.onAdd,
    required this.onTap,
  });

  final Meal meal;
  final VoidCallback onAdd;
  final VoidCallback onTap;

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
                Stack(
                  children: [
                    Hero(
                      tag: 'meal_${m.id}',
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          m.image,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 16, color: Color(0xFFFFB000)),
                            const SizedBox(width: 4),
                            Text(
                              m.rating.toStringAsFixed(1),
                              style: t.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                      const SizedBox(height: 4),
                      Text(
                        m.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall?.copyWith(
                          color: ChezMamaTheme.ink.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${m.price.toStringAsFixed(0)} FCFA',
                              style: t.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 44,
                            child: PrimaryButton(
                              label: 'Ajouter',
                              onPressed: widget.onAdd,
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

