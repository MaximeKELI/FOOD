import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../data/demo_data.dart';
import '../../models/meal.dart';
import '../../services/app_location_service.dart';
import '../../ui/african_pattern_painter.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../meal/meal_details_screen.dart';
import 'hero_carousel.dart';
import 'meal_card.dart';
import 'publish_meal_sheet.dart';

enum MealSort { recent, priceAsc, priceDesc, rating, distance }

const Map<MealSort, String> _sortLabels = {
  MealSort.recent: 'Récents',
  MealSort.priceAsc: 'Prix ↑',
  MealSort.priceDesc: 'Prix ↓',
  MealSort.rating: 'Mieux notés',
  MealSort.distance: 'Plus proches',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController scroll = ScrollController();

  bool loading = true;
  String? error;
  String activeCategory = DemoData.categories.first;
  String _query = '';
  final _searchCtrl = TextEditingController();
  List<Meal> _allMeals = [];

  // Filters & sort
  MealSort _sort = MealSort.recent;
  bool _availableOnly = false;
  bool _promoOnly = false;
  bool _specialOnly = false;
  LatLng? _userLoc;
  bool _locating = false;

  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final meals = await CatalogApi.instance.fetchMeals();
      if (!mounted) return;
      setState(() {
        _allMeals = meals;
        loading = false;
      });
      _stagger.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = apiErrorMessage(e);
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _stagger.dispose();
    scroll.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double? _distanceKm(Meal m) {
    if (_userLoc == null || m.sellerLat == null || m.sellerLng == null) {
      return null;
    }
    return const Distance().as(
      LengthUnit.Kilometer,
      _userLoc!,
      LatLng(m.sellerLat!, m.sellerLng!),
    );
  }

  List<Meal> get _visibleMeals {
    var meals = List<Meal>.from(_allMeals);
    if (activeCategory != 'Popular') {
      meals = meals.where((m) => m.category == activeCategory).toList();
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      meals = meals.where((m) {
        return m.name.toLowerCase().contains(q) ||
            m.subtitle.toLowerCase().contains(q) ||
            m.sellerName.toLowerCase().contains(q);
      }).toList();
    }
    if (_availableOnly) meals = meals.where((m) => m.isAvailable).toList();
    if (_promoOnly) meals = meals.where((m) => m.hasPromo).toList();
    if (_specialOnly) meals = meals.where((m) => m.isSpecial).toList();

    switch (_sort) {
      case MealSort.recent:
        break;
      case MealSort.priceAsc:
        meals.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case MealSort.priceDesc:
        meals.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case MealSort.rating:
        meals.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case MealSort.distance:
        meals.sort((a, b) {
          final da = _distanceKm(a) ?? double.infinity;
          final db = _distanceKm(b) ?? double.infinity;
          return da.compareTo(db);
        });
        break;
    }
    return meals;
  }

  Future<void> _ensureLocation() async {
    if (_userLoc != null || _locating) return;
    setState(() => _locating = true);
    final res = await AppLocationService.instance.acquireLocation();
    if (!mounted) return;
    setState(() {
      _userLoc = res.location;
      _locating = false;
    });
    if (res.location == null && res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.error!)),
      );
    }
  }

  Future<void> _publishMeal() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const PublishMealSheet(),
    );
    if (created == true) {
      await _loadMeals();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plat publié avec succès')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final meals = _visibleMeals;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publishMeal,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Publier un plat'),
      ),
      body: CustomScrollView(
        controller: scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 176,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: ChezMamaTheme.headerGradient(context),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: AfricanPatternPainter(
                        a: ChezMamaTheme.brandOrange,
                        b: ChezMamaTheme.brandAmber,
                        c: ChezMamaTheme.brandBrown,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 64,
                    child: const HeroCarousel(height: 86),
                  ),
                ],
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(58),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: DemoData.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final c = DemoData.categories[i];
                      final selected = c == activeCategory;
                      return ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        labelStyle: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected
                              ? ChezMamaTheme.brandBrown
                              : ChezMamaTheme.mutedInk(context),
                        ),
                        onSelected: (_) {
                          setState(() => activeCategory = c);
                          if (!loading) _stagger.forward(from: 0);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Rechercher un plat, un vendeur…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                children: [
                  _SortMenu(
                    value: _sort,
                    onSelected: (s) async {
                      if (s == MealSort.distance) await _ensureLocation();
                      if (!mounted) return;
                      setState(() => _sort = s);
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Dispo'),
                    selected: _availableOnly,
                    onSelected: (v) => setState(() => _availableOnly = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(
                      Icons.sell_rounded,
                      size: 16,
                      color: _promoOnly ? Colors.white : null,
                    ),
                    label: const Text('Promo'),
                    selected: _promoOnly,
                    onSelected: (v) => setState(() => _promoOnly = v),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    avatar: Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: _specialOnly ? Colors.white : null,
                    ),
                    label: const Text('Plat du jour'),
                    selected: _specialOnly,
                    onSelected: (v) => setState(() => _specialOnly = v),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            sliver: loading
                ? const _HomeSkeleton()
                : error != null
                    ? SliverToBoxAdapter(
                        child: _HomeMessage(
                          icon: Icons.cloud_off_rounded,
                          title: 'Connexion impossible',
                          subtitle: error!,
                          onRetry: _loadMeals,
                        ),
                      )
                    : meals.isEmpty
                        ? SliverToBoxAdapter(
                            child: _HomeMessage(
                              icon: _query.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.restaurant_menu_rounded,
                              title: _query.isNotEmpty
                                  ? 'Aucun résultat'
                                  : 'Aucun plat pour le moment',
                              subtitle: _query.isNotEmpty
                                  ? 'Aucun plat ne correspond à « $_query ».'
                                  : 'Les plats publiés par les vendeurs apparaîtront ici.',
                              onRetry: _loadMeals,
                            ),
                          )
                        : SliverList.separated(
                    itemCount: meals.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final meal = meals[i];
                      final start = (i * 0.08).clamp(0.0, 0.7);
                      final end = (start + 0.3).clamp(0.0, 1.0);
                      final a = CurvedAnimation(
                        parent: _stagger,
                        curve: Interval(start, end, curve: Curves.easeOutCubic),
                      );

                      return FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(a),
                          child: Builder(
                            builder: (cardContext) {
                              return MealCard(
                                meal: meal,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          MealDetailsScreen(meal: meal),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.value, required this.onSelected});
  final MealSort value;
  final ValueChanged<MealSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MealSort>(
      initialValue: value,
      onSelected: onSelected,
      itemBuilder: (_) => MealSort.values
          .map((s) => PopupMenuItem(value: s, child: Text(_sortLabels[s]!)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.swap_vert_rounded, size: 18),
        label: Text('Trier · ${_sortLabels[value]}'),
      ),
    );
  }
}

class _HomeMessage extends StatelessWidget {
  const _HomeMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 48, color: ChezMamaTheme.brandBrown),
          const SizedBox(height: 12),
          Text(
            title,
            style: t.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
            style: FilledButton.styleFrom(
              backgroundColor: ChezMamaTheme.brandOrange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ShimmerSkeleton(
        child: Column(
          children: List.generate(4, (i) {
            return Padding(
              padding: EdgeInsets.only(bottom: i == 3 ? 0 : 14),
              child: Column(
                children: const [
                  SkeletonBox(width: double.infinity, height: 150, radius: 18),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: SkeletonBox(width: 1, height: 16, radius: 8)),
                      SizedBox(width: 14),
                      SkeletonBox(width: 98, height: 40, radius: 16),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

