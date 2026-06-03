import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_strings.dart';
import '../../providers/bootstrap_provider.dart';
import '../../ui/african_pattern_painter.dart';
import '../../ui/chezmama_theme.dart';
import '../../widgets/brand_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
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
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: ChezMamaTheme.headerGradient(context),
            ),
          ),
          CustomPaint(
            painter: AfricanPatternPainter(
              a: ChezMamaTheme.brandOrange.withValues(alpha: 0.35),
              b: ChezMamaTheme.brandAmber.withValues(alpha: 0.25),
              c: ChezMamaTheme.brandBrown.withValues(alpha: 0.2),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandLogo(size: 104, radius: 26, showShadow: true),
                    const SizedBox(height: ChezMamaTheme.spaceLg),
                    Text(
                      tr('app.name'),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                          ),
                    ),
                    const SizedBox(height: 28),
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
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
