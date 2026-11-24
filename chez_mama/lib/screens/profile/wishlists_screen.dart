import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/platform_api.dart';
import '../../l10n/app_strings.dart';
import '../../screens/meal/meal_details_screen.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/food_network_image.dart';
import '../../widgets/list_loading_skeleton.dart';

class WishlistsScreen extends StatefulWidget {
  const WishlistsScreen({super.key});

  @override
  State<WishlistsScreen> createState() => _WishlistsScreenState();
}

class _WishlistsScreenState extends State<WishlistsScreen> {
  List<WishList> _lists = [];
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
      final lists = await PlatformApi.instance.fetchWishlists();
      if (!mounted) return;
      setState(() {
        _lists = lists;
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

  Future<void> _create() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('wishlist.create')),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(labelText: tr('wishlist.name')),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('action.cancel')),
          ),
          Semantics(
            label: tr('wishlist.create'),
            button: true,
            child: FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(tr('action.save')),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = ctrl.text.trim();
    if (name.isEmpty) return;
    try {
      await PlatformApi.instance.createWishlist(name);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  Future<void> _deleteList(WishList list) async {
    try {
      await PlatformApi.instance.deleteWishlist(list.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('wishlist.title'))),
      floatingActionButton: Semantics(
        label: tr('wishlist.create'),
        button: true,
        child: FloatingActionButton(
          onPressed: _create,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ListLoadingSkeleton();
    if (_error != null) {
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        title: tr('home.connectionFailed'),
        subtitle: _error!,
        actionLabel: tr('action.retry'),
        onAction: _load,
      );
    }
    if (_lists.isEmpty) {
      return EmptyStateView(
        icon: Icons.bookmark_outline_rounded,
        title: tr('wishlist.empty'),
        subtitle: tr('wishlist.emptyHint'),
        actionLabel: tr('wishlist.create'),
        onAction: _create,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: _lists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final list = _lists[i];
          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(
              list.name,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(trf('wishlist.itemCount', {'count': list.itemsCount})),
            trailing: IconButton(
              tooltip: tr('action.delete'),
              onPressed: () => _deleteList(list),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            children: [
              if (list.items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(tr('wishlist.noItems')),
                )
              else
                for (final item in list.items)
                  ListTile(
                    leading: item.meal != null
                        ? SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: FoodNetworkImage(
                                url: item.meal!.image,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : null,
                    title: Text(item.meal?.name ?? '#${item.mealId}'),
                    onTap: item.meal != null
                        ? () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    MealDetailsScreen(meal: item.meal!),
                              ),
                            )
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () async {
                        try {
                          await PlatformApi.instance.removeWishlistItem(
                            list.id,
                            item.mealId,
                          );
                          await _load();
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(apiErrorMessage(e))),
                          );
                        }
                      },
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}