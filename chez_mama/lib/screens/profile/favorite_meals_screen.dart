import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../widgets/list_loading_skeleton.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/entrance.dart';
import '../home/meal_card.dart';
import '../meal/meal_details_screen.dart';

class FavoriteMealsScreen extends StatefulWidget {
  const FavoriteMealsScreen({super.key});

  @override
  State<FavoriteMealsScreen> createState() => _FavoriteMealsScreenState();
}

class _FavoriteMealsScreenState extends State<FavoriteMealsScreen> {
  List<Meal> _meals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final meals = await CatalogApi.instance.fetchFavorites();
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('favorites.title'))),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const ListLoadingSkeleton(imageHeight: 120);
    }
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    if (_meals.isEmpty) {
      return EmptyStateView(
        icon: Icons.favorite_border_rounded,
        lottieAsset: LottieAssets.empty,
        title: tr('favorites.empty'),
        subtitle: tr('favorites.emptyHint'),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _meals.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final meal = _meals[i];
          return FadeInUp(
            index: i,
            child: MealCard(
              meal: meal,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MealDetailsScreen(meal: meal),
                  ),
                );
                _load();
              },
            ),
          );
        },
      ),
    );
  }
}
