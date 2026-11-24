import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';

/// Full-bleed appetite hero: brand first, one dish visual plane, soft crossfade.
///
/// Studies on OFD apps link large, warm, textured food imagery to desire and
/// conversion — inset “promo cards” fight that. This stays edge-to-edge.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    this.onExplore,
  });

  final VoidCallback? onExplore;

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

  @override
  void initState() {
    super.initState();
    _ken = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _assets.length);
    });
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
    final key = _slideKeys[_index];

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: ChezMamaTheme.dMed,
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: AnimatedBuilder(
            key: ValueKey(_index),
            animation: _ken,
            builder: (context, child) {
              final scale = 1.0 + (_ken.value * 0.06);
              return Transform.scale(scale: scale, child: child);
            },
            child: Image.asset(
              _assets[_index],
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
        // Warm vignette keeps food vivid while protecting text contrast.
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
                    tr('hero.$key.title'),
                    key: ValueKey('t$key'),
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
                    tr('hero.$key.subtitle'),
                    key: ValueKey('s$key'),
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
                      children: List.generate(_assets.length, (i) {
                        final active = i == _index;
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
