import 'dart:async';
import 'package:flutter/material.dart';
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

  final items = const <_HeroItem>[
    _HeroItem(
      title: 'Plats chauds, saveurs locales',
      subtitle: 'Découvre les meilleurs vendeurs près de toi',
      gradient: [Color(0xFFFF7A18), Color(0xFFFFC24C), Color(0xFFFFFBF6)],
      asset: null,
    ),
    _HeroItem(
      title: 'Shorts & vidéos',
      subtitle: 'Like, commente, abonne-toi',
      gradient: [Color(0xFF6E3B1F), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
      asset: null,
    ),
    _HeroItem(
      title: 'Commande en 3 clics',
      subtitle: 'Rapide, fluide et sécurisé',
      gradient: [Color(0xFFE2A83B), Color(0xFFFF7A18), Color(0xFFFFFBF6)],
      asset: null,
    ),
  ];

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      index = (index + 1) % items.length;
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
      child: PageView.builder(
        controller: controller,
        itemCount: items.length,
        onPageChanged: (v) => setState(() => index = v),
        itemBuilder: (context, i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.hasClients && controller.position.haveDimensions
                  ? controller.page ?? controller.initialPage.toDouble()
                  : controller.initialPage.toDouble();
              final delta = (page - i).abs().clamp(0.0, 1.0);
              final scale = 1 - (0.04 * delta);
              return Transform.scale(scale: scale, child: child);
            },
            child: _HeroCard(item: items[i]),
          );
        },
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});
  final _HeroItem item;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: ChezMamaTheme.softShadow(opacity: 0.12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: item.gradient,
                  ),
                ),
              ),
              if (item.asset != null)
                Image.asset(
                  item.asset!,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: t.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
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

class _HeroItem {
  const _HeroItem({
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.asset,
  });
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final String? asset;
}

