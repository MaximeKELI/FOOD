import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../onboarding/onboarding_controller.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/brand_logo.dart';
import '../shell/app_shell.dart';

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
      icon: Icons.restaurant_menu_rounded,
      titleKey: 'onboarding.slide1Title',
      bodyKey: 'onboarding.slide1Body',
    ),
    _Slide(
      icon: Icons.delivery_dining_rounded,
      titleKey: 'onboarding.slide2Title',
      bodyKey: 'onboarding.slide2Body',
    ),
    _Slide(
      icon: Icons.storefront_rounded,
      titleKey: 'onboarding.slide3Title',
      bodyKey: 'onboarding.slide3Body',
    ),
  ];

  Future<void> _finish() async {
    await OnboardingController.instance.markComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AppShell()),
    );
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(tr('onboarding.skip')),
              ),
            ),
            const BrandLogo(size: 72, radius: 20, showShadow: true),
            const SizedBox(height: ChezMamaTheme.spaceLg),
            Expanded(
              child: PageView.builder(
                controller: _page,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final slide = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ChezMamaTheme.spaceXl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: ChezMamaTheme.brandGradient,
                          ),
                          child: Icon(slide.icon, size: 44, color: Colors.white),
                        ),
                        const SizedBox(height: ChezMamaTheme.spaceXl),
                        Text(
                          tr(slide.titleKey),
                          textAlign: TextAlign.center,
                          style: t.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: ChezMamaTheme.spaceMd),
                        Text(
                          tr(slide.bodyKey),
                          textAlign: TextAlign.center,
                          style: t.textTheme.bodyLarge?.copyWith(
                            color: ChezMamaTheme.mutedInk(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: active
                        ? ChezMamaTheme.brandOrange
                        : ChezMamaTheme.brandBrown.withValues(alpha: 0.25),
                  ),
                );
              }),
            ),
            const SizedBox(height: ChezMamaTheme.spaceLg),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ChezMamaTheme.spaceXl,
                0,
                ChezMamaTheme.spaceXl,
                ChezMamaTheme.spaceLg,
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_index < _slides.length - 1) {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      _finish();
                    }
                  },
                  child: Text(
                    _index < _slides.length - 1
                        ? tr('onboarding.next')
                        : tr('onboarding.start'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide({
    required this.icon,
    required this.titleKey,
    required this.bodyKey,
  });
  final IconData icon;
  final String titleKey;
  final String bodyKey;
}
