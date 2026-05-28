import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/meal.dart';
import '../../ui/african_pattern_painter.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../meal/meal_details_screen.dart';
import 'hero_carousel.dart';
import 'meal_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ScrollController scroll = ScrollController();

  bool loading = true;
  String activeCategory = DemoData.categories.first;

  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Demo loading.
    Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() => loading = false);
      _stagger.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _stagger.dispose();
    scroll.dispose();
    super.dispose();
  }

  List<Meal> get _visibleMeals {
    if (activeCategory == 'Popular') return DemoData.meals;
    return DemoData.meals.where((m) => m.category == activeCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final meals = _visibleMeals;

    return Scaffold(
      body: CustomScrollView(
        controller: scroll,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            automaticallyImplyLeading: false,
            title: const Text('Food'),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFE3C3),
                          Color(0xFFFFFBF6),
                        ],
                      ),
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
                        selectedColor: ChezMamaTheme.brandOrange
                            .withValues(alpha: 0.16),
                        backgroundColor: Colors.white,
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
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
            sliver: loading
                ? const _HomeSkeleton()
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

