import 'package:flutter/material.dart';

import '../../api/catalog_api.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../ui/chezmama_theme.dart';
import '../../utils/currency_format.dart';
import '../../widgets/food_network_image.dart';
import '../meal/meal_details_screen.dart';

/// Horizontal list of recently viewed meals for the home screen.
class RecentMealsSection extends StatefulWidget {
  const RecentMealsSection({super.key});

  @override
  State<RecentMealsSection> createState() => _RecentMealsSectionState();
}

class _RecentMealsSectionState extends State<RecentMealsSection> {
  List<Meal> _meals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meals = await CatalogApi.instance.fetchRecent();
      if (!mounted) return;
      setState(() => _meals = meals);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_meals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            tr('home.recent'),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _meals.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final m = _meals[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MealDetailsScreen(meal: m),
                    ),
                  );
                },
                child: SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 80,
                          width: 120,
                          child: FoodNetworkImage(
                            url: m.image,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        m.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        formatFcfa(m.effectivePrice.round()),
                        style: TextStyle(
                          color: ChezMamaTheme.brandBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
