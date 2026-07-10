import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../providers/bootstrap_provider.dart';
import '../../ui/african_pattern_painter.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/animated_brand_logo.dart';
import '../../widgets/luxe.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _bg;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _bg = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutBack),
    );
    _c.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryNavigate());
  }

  void _tryNavigate() {
    if (!mounted || _navigated) return;
    final boot = ref.read(bootstrapProvider);
    if (!boot.done) return;
    _navigated = true;
    final path = boot.onboardingComplete ? '/home' : '/onboarding';
    context.go(path);
  }

  @override
  void dispose() {
    _c.dispose();
    _bg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BootstrapNotifier>(bootstrapProvider, (_, boot) {
      if (boot.done) _tryNavigate();
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _bg,
            builder: (context, _) {
              final t = _bg.value;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + 2 * t, -1),
                    end: Alignment(1 - 2 * t, 1),
                    colors: ChezMamaTheme.cinematicGradient(context).colors,
                    stops: ChezMamaTheme.cinematicGradient(context).stops,
                  ),
                ),
              );
            },
          ),
          CustomPaint(
            painter: AfricanPatternPainter(
              a: ChezMamaTheme.brandOrange.withValues(alpha: 0.35),
              b: ChezMamaTheme.brandAmber.withValues(alpha: 0.25),
              c: ChezMamaTheme.brandBrown.withValues(alpha: 0.2),
            ),
          ),
          const Positioned.fill(child: FloatingMotes(count: 22)),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AnimatedBrandLogo(size: 118, radius: 30),
                    const SizedBox(height: ChezMamaTheme.spaceLg),
                    ShimmerText(
                      tr('app.name'),
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('app.tagline'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: ChezMamaTheme.mutedInk(context),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor: AlwaysStoppedAnimation(
                          ChezMamaTheme.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
