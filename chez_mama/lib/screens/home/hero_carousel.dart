import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/food_network_image.dart';

/// Full-bleed appetite hero: brand first, real seller dishes when available.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    this.onExplore,
    this.mealImages = const [],
  });

  final VoidCallback? onExplore;
  final List<({String url, String title, String seller})> mealImages;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  int _index = 0;
  late final AnimationController _ken;

  static const _slideKeys = [
    'thieb',
    'yassa',
    'mafe',
    'jollof',
    'suya',
    'ndole',
  ];

  static const _assets = [
    'assets/images/food_hero_thieboudienne.png',
    'assets/images/food_hero_yassa.png',
    'assets/images/food_hero_mafe.png',
    'assets/images/food_hero_jollof.png',
    'assets/images/food_hero_suya.png',
    'assets/images/food_hero_ndole.png',
  ];

  bool get _useMeals => widget.mealImages.isNotEmpty;

  int get _count => _useMeals ? widget.mealImages.length : _assets.length;

  @override
  void initState() {
    super.initState();
    _ken = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _count == 0) return;
      setState(() => _index = (_index + 1) % _count);
    });
  }

  @override
  void didUpdateWidget(covariant HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_count > 0 && _index >= _count) {
      _index = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ken.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final safeIndex = _count == 0 ? 0 : _index % _count;
    final meal = _useMeals ? widget.mealImages[safeIndex] : null;
    final key = _slideKeys[safeIndex % _slideKeys.length];

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: ChezMamaTheme.dMed,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: AnimatedBuilder(
            key: ValueKey('${_useMeals}_$safeIndex'),
            animation: _ken,
            builder: (context, child) {
              final scale = 1.0 + (_ken.value * 0.06);
              return Transform.scale(scale: scale, child: child);
            },
            child: meal != null
                ? SizedBox.expand(
                    child: FoodNetworkImage(
                      url: meal.url,
                      memCacheWidth: 1200,
                    ),
                  )
                : Image.asset(
                    _assets[safeIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => Container(
                      color: ChezMamaTheme.brandBrown,
                    ),
                  ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.72),
              ],
              stops: const [0.0, 0.38, 1.0],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                ChezMamaTheme.brandOrange.withValues(alpha: 0.22),
                Colors.transparent,
              ],
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Text(
                  tr('app.name'),
                  style: t.textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                    height: 0.95,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: ChezMamaTheme.dFast,
                  child: Text(
                    meal?.title.isNotEmpty == true
                        ? meal!.title
                        : tr('hero.$key.title'),
                    key: ValueKey('t$safeIndex'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: ChezMamaTheme.dFast,
                  child: Text(
                    meal != null && meal.seller.isNotEmpty
                        ? trf('home.heroSeller', {'name': meal.seller})
                        : meal != null
                            ? tr('home.localSeller')
                            : tr('hero.$key.subtitle'),
                    key: ValueKey('s$safeIndex'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: tr('home.exploreCta'),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onExplore,
                          borderRadius:
                              BorderRadius.circular(ChezMamaTheme.rButton),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: ChezMamaTheme.brandGradient,
                              borderRadius:
                                  BorderRadius.circular(ChezMamaTheme.rButton),
                              boxShadow: ChezMamaTheme.glowShadow(
                                ChezMamaTheme.brandOrange,
                                opacity: 0.4,
                                blur: 18,
                                offset: const Offset(0, 8),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    tr('home.exploreCta'),
                                    style: t.textTheme.labelLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(_count.clamp(0, 8), (i) {
                        final active = i == safeIndex;
                        return AnimatedContainer(
                          duration: ChezMamaTheme.dFast,
                          margin: const EdgeInsets.only(left: 4),
                          width: active ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.35),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
