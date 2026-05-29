import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:latlong2/latlong.dart';
import '../../cache/meal_cache.dart';
import '../../api/api_client.dart';
import '../../api/catalog_api.dart';
import '../../l10n/app_strings.dart';
import '../../models/meal.dart';
import '../../services/app_location_service.dart';
import '../../ui/african_pattern_painter.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/shell_toolbar_actions.dart';
import '../meal/meal_details_screen.dart';
import 'hero_carousel.dart';
import 'meal_card.dart';
import 'publish_meal_sheet.dart';

enum MealSort { recent, priceAsc, priceDesc, rating, distance }

const _allCategory = 'Tous';

const Map<MealSort, String> _sortLabels = {
  MealSort.recent: 'Récents',
  MealSort.priceAsc: 'Prix ↑',
  MealSort.priceDesc: 'Prix ↓',
  MealSort.rating: 'Mieux notés',
  MealSort.distance: 'Plus proches',
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.isSeller,
    required this.onNotifications,
    required this.onMessages,
    required this.onReceivedOrders,
    required this.onMenuSelected,
    required this.onPickLanguage,
  });

  final bool isSeller;
  final VoidCallback onNotifications;
  final VoidCallback onMessages;
  final VoidCallback onReceivedOrders;
  final ValueChanged<String> onMenuSelected;
  final VoidCallback onPickLanguage;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController scroll = ScrollController();

  bool loading = true;
  String? error;
  String activeCategory = _allCategory;
  String _query = '';
  final _searchCtrl = TextEditingController();
  List<Meal> _allMeals = [];
  List<String> _categories = const [_allCategory];
  bool _fromCache = false;
  bool _listening = false;
  final _speech = SpeechToText();

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
      _fromCache = false;
    });
    try {
      final cached = await MealCache.instance.loadMeals();
      if (cached.isNotEmpty && mounted) {
        setState(() {
          _allMeals = cached;
          loading = false;
          _fromCache = true;
        });
      }
      final results = await Future.wait([
        CatalogApi.instance.fetchMeals(query: _query.trim().isEmpty ? null : _query),
        CatalogApi.instance.fetchCategories(),
      ]);
      if (!mounted) return;
      final meals = results[0] as List<Meal>;
      final apiCategories = results[1] as List<MealCategory>;
      await MealCache.instance.saveMeals(meals);
      setState(() {
        _allMeals = meals;
        _categories = [
          _allCategory,
          ...apiCategories.map((c) => c.name),
        ];
        if (!_categories.contains(activeCategory)) {
          activeCategory = _allCategory;
        }
        loading = false;
        _fromCache = false;
      });
      _stagger.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      if (_allMeals.isEmpty) {
        setState(() {
          error = apiErrorMessage(e);
          loading = false;
        });
      } else {
        setState(() {
          error = null;
          loading = false;
          _fromCache = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mode hors ligne — ${tr('action.retry')}')),
        );
      }
    }
  }

  Future<void> _startVoiceSearch() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final available = await _speech.initialize();
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reconnaissance vocale indisponible.')),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _searchCtrl.text = result.recognizedWords;
          _query = result.recognizedWords;
        });
        if (result.finalResult) {
          _speech.stop();
          _listening = false;
          _loadMeals();
        }
      },
      localeId: 'fr_FR',
    );
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
    var meals = activeCategory == _allCategory
        ? List<Meal>.from(_allMeals)
        : _allMeals.where((m) => m.category == activeCategory).toList();

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
      floatingActionButton: widget.isSeller
          ? FloatingActionButton.extended(
              onPressed: _publishMeal,
              icon: const Icon(Icons.add_rounded),
              label: Text(tr('home.publishMeal')),
            )
          : null,
      body: CustomScrollView(
        controller: scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            actions: [
              ShellToolbarActions(
                isSeller: widget.isSeller,
                onNotifications: widget.onNotifications,
                onMessages: widget.onMessages,
                onReceivedOrders: widget.onReceivedOrders,
                onMenuSelected: widget.onMenuSelected,
                onPickLanguage: widget.onPickLanguage,
              ),
            ],
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
                    bottom: 58,
                    child: const HeroCarousel(height: 130),
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
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final c = _categories[i];
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
              child: Column(
                children: [
                  if (_fromCache)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Données en cache — reconnecte-toi pour actualiser.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: ChezMamaTheme.brandBrown,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  TextField(
                controller: _searchCtrl,
                onChanged: (v) {
                  setState(() => _query = v);
                  if (v.trim().length >= 2) _loadMeals();
                },
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadMeals(),
                decoration: InputDecoration(
                  hintText: tr('home.search'),
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Recherche vocale',
                        onPressed: _startVoiceSearch,
                        icon: Icon(
                          _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                          color: _listening ? ChezMamaTheme.brandOrange : null,
                        ),
                      ),
                      if (_query.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                            _loadMeals();
                          },
                        ),
                    ],
                  ),
                ),
                  ),
                ],
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
                    label: Text(tr('home.filter.available')),
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
                    label: Text(tr('home.filter.promo')),
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
                    label: Text(tr('home.filter.special')),
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
                : error != null && meals.isEmpty
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
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, i) {
                              final meal = meals[i];
                              final start = (i * 0.08).clamp(0.0, 0.7);
                              final end = (start + 0.3).clamp(0.0, 1.0);
                              final a = CurvedAnimation(
                                parent: _stagger,
                                curve: Interval(start, end,
                                    curve: Curves.easeOutCubic),
                              );

                              return FadeTransition(
                                opacity: a,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(a),
                                  child: MealCard(
                                    meal: meal,
                                    distanceKm: _distanceKm(meal),
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MealDetailsScreen(meal: meal),
                                        ),
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
        label: Text('${tr('home.sort')} · ${_sortLabels[value]}'),
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
