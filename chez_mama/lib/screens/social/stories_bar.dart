import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/support_api.dart';
import '../../auth/auth_scope.dart';
import '../../auth/auth_service.dart';
import '../../cart/cart_service.dart';
import '../../l10n/app_strings.dart';
import '../../services/app_media_picker.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/food_network_image.dart';
import '../meal/meal_details_screen.dart';
import '../meal/meal_options_sheet.dart';
import '../../api/catalog_api.dart';
import '../../models/meal.dart';

/// Horizontal stories strip for home / social feed.
class StoriesBar extends StatefulWidget {
  const StoriesBar({super.key});

  @override
  State<StoriesBar> createState() => _StoriesBarState();
}

class _StoriesBarState extends State<StoriesBar> {
  List<StoryView> _stories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final stories = await SupportApi.instance.fetchStoriesFeed();
      if (!mounted) return;
      setState(() {
        _stories = stories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<int?> _pickMealForStory(AuthService auth) async {
    if (!auth.isSeller) return null;
    List<Meal> meals = [];
    try {
      meals = await CatalogApi.instance.fetchMeals(sellerId: auth.userId);
    } catch (_) {
      meals = const [];
    }
    if (!mounted) return null;
    return showDialog<int?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(tr('stories.pickMeal')),
          content: SizedBox(
            width: double.maxFinite,
            child: meals.isEmpty
                ? Text(tr('publications.noMeals'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: meals.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return ListTile(
                          leading: const Icon(Icons.skip_next_rounded),
                          title: Text(tr('stories.noMeal')),
                          onTap: () => Navigator.pop(ctx, null),
                        );
                      }
                      final meal = meals[i - 1];
                      final id = int.tryParse(meal.id);
                      return ListTile(
                        leading: const Icon(Icons.restaurant_rounded),
                        title: Text(meal.name),
                        subtitle: meal.category.isNotEmpty
                            ? Text(meal.category)
                            : null,
                        onTap: () => Navigator.pop(ctx, id),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(tr('onboarding.skip')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addStory() async {
    final auth = AuthScope.of(context);
    if (!auth.isAuthed) return;
    final mealIdAsk = await _pickMealForStory(auth);
    final path = await AppMediaPicker.instance.pickPhotoFromGallery();
    if (path == null || !mounted) return;
    try {
      await SupportApi.instance.createStory(
        mediaPath: path.path,
        mealId: mealIdAsk,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  void _openStory(StoryView story) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 9 / 16,
              child: FoodNetworkImage(
                url: story.mediaUrl,
                fit: BoxFit.cover,
              ),
            ),
            if (story.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  story.caption,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            if (story.mealId != null) ...[
              Semantics(
                label: tr('stories.addToCart'),
                button: true,
                child: FilledButton(
                  onPressed: () async {
                    try {
                      final meal =
                          await CatalogApi.instance.fetchMeal('${story.mealId}');
                      if (!ctx.mounted) return;
                      final opts = await showMealOptionsSheet(ctx, meal);
                      if (opts == null) return;
                      CartService.instance.addMeal(
                        meal,
                        optionIds: (opts['ids'] as List<int>?) ?? const [],
                        optionsExtra: (opts['extra'] as int?) ?? 0,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(tr('stories.addToCart'))),
                      );
                    } catch (e) {
                      if (!ctx.mounted) return;
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text(apiErrorMessage(e))),
                      );
                    }
                  },
                  child: Text(tr('stories.addToCart')),
                ),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final meal =
                        await CatalogApi.instance.fetchMeal('${story.mealId}');
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MealDetailsScreen(meal: meal),
                      ),
                    );
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text(apiErrorMessage(e))),
                    );
                  }
                },
                child: Text(
                  story.mealName != null && story.mealName!.isNotEmpty
                      ? story.mealName!
                      : tr('stories.openMeal'),
                ),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('action.close')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _stories.isEmpty) {
      return const SizedBox(height: 88);
    }
    final authed = AuthScope.of(context).isAuthed;
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: _stories.length + (authed ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (authed && i == 0) {
            return GestureDetector(
              onTap: _addStory,
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ChezMamaTheme.brandOrange,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: ChezMamaTheme.brandOrange),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('stories.add'),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }
          final story = _stories[authed ? i - 1 : i];
          return GestureDetector(
            onTap: () => _openStory(story),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ChezMamaTheme.brandOrange,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: FoodNetworkImage(
                      url: story.mediaUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 70,
                  child: Text(
                    story.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
