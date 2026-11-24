import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(
      asset: 'assets/images/food_hero_thieboudienne.png',
      titleKey: 'onboarding.slide1Title',
      bodyKey: 'onboarding.slide1Body',
    ),
    _Slide(
      asset: 'assets/images/food_hero_yassa.png',
      titleKey: 'onboarding.slide2Title',
      bodyKey: 'onboarding.slide2Body',
    ),
    _Slide(
      asset: 'assets/images/food_hero_mafe.png',
      titleKey: 'onboarding.slide3Title',
      bodyKey: 'onboarding.slide3Body',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingController.instance.markComplete();
    if (!mounted) return;
    context.go('/home');
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final slide = _slides[_index];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: ChezMamaTheme.dMed,
            child: Image.asset(
              slide.asset,
              key: ValueKey(slide.asset),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: ChezMamaTheme.brandBrown,
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.78),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: Text(
                      tr('onboarding.skip'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('app.name'),
                        style: t.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.22,
                        child: PageView.builder(
                          controller: _page,
                          itemCount: _slides.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, i) {
                            final s = _slides[i];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(s.titleKey),
                                  style: t.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tr(s.bodyKey),
                                  style: t.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: ChezMamaTheme.dFast,
                            margin: const EdgeInsets.only(right: 6),
                            width: active ? 22 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: active
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.35),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: _index < _slides.length - 1
                            ? tr('onboarding.next')
                            : tr('onboarding.start'),
                        icon: _index < _slides.length - 1
                            ? Icons.arrow_forward_rounded
                            : Icons.restaurant_rounded,
                        onPressed: () {
                          if (_index < _slides.length - 1) {
                            _page.nextPage(
                              duration: ChezMamaTheme.dMed,
                              curve: ChezMamaTheme.easeLuxe,
                            );
                          } else {
                            _finish();
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.asset,
    required this.titleKey,
    required this.bodyKey,
  });
  final String asset;
  final String titleKey;
  final String bodyKey;
}
