import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../ui/chezmama_theme.dart';

class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    super.key,
    required this.height,
  });

  final double height;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final controller = PageController(viewportFraction: 0.92);
  Timer? timer;
  int index = 0;

  static const _slideKeys = [
    'mafe',
    'yassa',
    'suya',
    'thieb',
    'ndole',
    'jollof',
    'attieke',
    'plantain',
    'egusi',
    'brochettes',
    'drinks',
  ];

  static const _assets = [
    'assets/images/food_hero_mafe.png',
    'assets/images/food_hero_yassa.png',
    'assets/images/food_hero_suya.png',
    'assets/images/food_hero_thieboudienne.png',
    'assets/images/food_hero_ndole.png',
    'assets/images/food_hero_jollof.png',
    'assets/images/food_hero_attieke.png',
    'assets/images/food_hero_plantain.png',
    'assets/images/food_hero_egusi.png',
    'assets/images/food_hero_brochettes.png',
    'assets/images/food_hero_drinks.png',
  ];

  static const _gradients = [
    [Color(0xFFFF7A18), Color(0xFFFFC24C), Color(0xFFFFFBF6)],
    [Color(0xFF6E3B1F), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
    [Color(0xFFE2A83B), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
    [Color(0xFFFF7A18), Color(0xFF6E3B1F), Color(0xFFFFFBF6)],
    [Color(0xFF5BBF72), Color(0xFF6E3B1F), Color(0xFFFFFBF6)],
    [Color(0xFFFF7A18), Color(0xFFFFC24C), Color(0xFF6E3B1F)],
    [Color(0xFFFFC24C), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
    [Color(0xFFE2A83B), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
    [Color(0xFF6E3B1F), Color(0xFFB85C38), Color(0xFFFFFBF6)],
    [Color(0xFF1B1B1F), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
    [Color(0xFFE2A83B), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
  ];

  int get _count => _slideKeys.length;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      index = (index + 1) % _count;
      controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: _count,
              onPageChanged: (v) => setState(() => index = v),
              itemBuilder: (context, i) {
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final page = controller.hasClients &&
                            controller.position.haveDimensions
                        ? controller.page ?? controller.initialPage.toDouble()
                        : controller.initialPage.toDouble();
                    final delta = (page - i).abs().clamp(0.0, 1.0);
                    final scale = 1 - (0.04 * delta);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: _HeroCard(
                    title: tr('hero.${_slideKeys[i]}.title'),
                    subtitle: tr('hero.${_slideKeys[i]}.subtitle'),
                    gradient: _gradients[i],
                    asset: _assets[i],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_count, (i) {
              final active = i == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: active
                      ? ChezMamaTheme.brandOrange
                      : ChezMamaTheme.brandBrown.withValues(alpha: 0.25),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.asset,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: ChezMamaTheme.cardDecoration(
          context,
          radius: ChezMamaTheme.rCard,
          shadowOpacity: 0.14,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ChezMamaTheme.rCard),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                ),
              ),
              Image.asset(
                asset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
