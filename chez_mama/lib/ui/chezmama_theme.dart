import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system tuned for food appetite & conversion.
///
/// Research cues baked in:
/// - Warm paprika / saffron (appetite + adoption vs cool blues)
/// - Large food imagery surfaces (UberEats image→sales effect)
/// - Clear hierarchy: brand → desire → action
class ChezMamaTheme {
  // ---- Brand palette (Sahel dusk — appetite-forward, not purple/cream cliché)
  static const Color brandOrange = Color(0xFFE85D04); // paprika flame
  static const Color brandAmber = Color(0xFFF4A261); // millet / saffron
  static const Color brandBrown = Color(0xFF5C2E15); // roasted cocoa
  static const Color promoRed = Color(0xFFC1121F);
  static const Color soldOutGray = Color(0xFF7A736C);
  static const Color favorite = Color(0xFFE63946);
  static const Color openGreen = Color(0xFF2D6A4F); // trust / open-now
  static const Color mangoMist = Color(0xFFFFF4E8);
  static const Color spiceWash = Color(0xFFFFE8D0);

  static const Color gold = Color(0xFFE9B44C);
  static const Color goldLight = Color(0xFFF8E3A8);
  static const Color champagne = Color(0xFFF6E7C8);
  static const Color espresso = Color(0xFF241510);
  static const Color onyx = Color(0xFF120C09);

  static const Duration dFast = Duration(milliseconds: 220);
  static const Duration dMed = Duration(milliseconds: 420);
  static const Duration dSlow = Duration(milliseconds: 820);
  static const Curve easeLuxe = Curves.easeOutCubic;

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB8860B), gold, goldLight, gold, Color(0xFFB8860B)],
    stops: [0.0, 0.30, 0.5, 0.70, 1.0],
  );

  static RadialGradient haloGradient(BuildContext c) {
    return RadialGradient(
      colors: [
        brandAmber.withValues(alpha: _isDark(c) ? 0.42 : 0.55),
        brandOrange.withValues(alpha: 0.18),
        Colors.transparent,
      ],
      stops: const [0.0, 0.45, 1.0],
    );
  }

  static LinearGradient cinematicGradient(BuildContext c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _isDark(c)
          ? const [onyx, espresso, Color(0xFF3A2416), onyx]
          : const [
              Color(0xFFFFE8D0),
              Color(0xFFFFD4A8),
              Color(0xFFFFB86B),
              Color(0xFFFFF4E8),
            ],
      stops: const [0.0, 0.38, 0.66, 1.0],
    );
  }

  static BoxDecoration glassDecoration(
    BuildContext c, {
    double radius = rCard,
    double opacity = 0.14,
  }) {
    final dark = _isDark(c);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [
                Colors.white.withValues(alpha: opacity),
                Colors.white.withValues(alpha: opacity * 0.35),
              ]
            : [
                Colors.white.withValues(alpha: 0.55),
                Colors.white.withValues(alpha: 0.22),
              ],
      ),
      border: Border.all(
        color: Colors.white.withValues(alpha: dark ? 0.16 : 0.55),
        width: 1.2,
      ),
    );
  }

  static List<BoxShadow> glowShadow(
    Color color, {
    double opacity = 0.45,
    double blur = 28,
    double spread = 0,
    Offset offset = const Offset(0, 10),
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blur,
        spreadRadius: spread,
        offset: offset,
      ),
    ];
  }

  static const double spaceXs = 6;
  static const double spaceSm = 10;
  static const double spaceMd = 14;
  static const double spaceLg = 18;
  static const double spaceXl = 24;
  static const double navClearance = 110;

  static const Color ink = Color(0xFF1C1210);
  static const Color surface = mangoMist;
  static const Color surface2 = spiceWash;
  static const Color card = Color(0xFFFFFBF7);

  static const Color darkBg = Color(0xFF14100E);
  static const Color darkSurface = Color(0xFF1F1915);
  static const Color darkCard = Color(0xFF2A221C);
  static const Color darkSurface2 = Color(0xFF332A22);
  static const Color darkInk = Color(0xFFF6EFE6);

  static const double rField = 16;
  static const double rButton = 18;
  static const double rCard = 20;
  static const double rSheet = 28;
  static const double rChip = 999;

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  static Color cardColor(BuildContext c) => _isDark(c) ? darkCard : card;

  static Color subtleSurface(BuildContext c) =>
      _isDark(c) ? darkSurface2 : surface2;

  static Color inkColor(BuildContext c) => _isDark(c) ? darkInk : ink;

  static Color mutedInk(BuildContext c) =>
      (_isDark(c) ? darkInk : ink).withValues(alpha: 0.62);

  static LinearGradient headerGradient(BuildContext c) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _isDark(c)
          ? const [Color(0xFF2A1C10), darkBg]
          : const [Color(0xFFFFD9B0), mangoMist],
    );
  }

  /// Flame CTA gradient — warm hues linked to appetite / urgency.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2F02), brandOrange, brandAmber],
    stops: [0.0, 0.45, 1.0],
  );

  static BoxDecoration cardDecoration(
    BuildContext c, {
    double radius = rCard,
    double shadowOpacity = 0.10,
    Color? color,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? cardColor(c),
      borderRadius: BorderRadius.circular(radius),
      border: border,
      boxShadow: softShadow(opacity: shadowOpacity),
    );
  }

  static BoxDecoration subtleDecoration(BuildContext c, {double radius = rCard}) {
    return BoxDecoration(
      color: subtleSurface(c),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  static TextStyle? priceStyle(BuildContext c, ThemeData t, {bool promo = false}) {
    return t.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w900,
      color: promo ? promoRed : brandBrown,
      letterSpacing: -0.2,
    );
  }

  static TextStyle? sectionTitle(ThemeData t, BuildContext c) {
    return t.textTheme.titleMedium?.copyWith(
      fontFamily: GoogleFonts.fraunces().fontFamily,
      fontWeight: FontWeight.w700,
      color: inkColor(c),
      letterSpacing: -0.2,
      height: 1.15,
    );
  }

  static TextStyle? displayStyle(ThemeData t, BuildContext c) {
    return t.textTheme.headlineMedium?.copyWith(
      fontFamily: GoogleFonts.fraunces().fontFamily,
      fontWeight: FontWeight.w700,
      color: inkColor(c),
      letterSpacing: -0.6,
      height: 1.05,
    );
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? darkBg : surface;
    final surf = isDark ? darkSurface : surface;
    final cardC = isDark ? darkCard : card;
    final inkC = isDark ? darkInk : ink;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: brightness,
      primary: brandOrange,
      onPrimary: Colors.white,
      secondary: brandAmber,
      surface: surf,
      onSurface: inkC,
    );

    final body = GoogleFonts.manropeTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    final display = GoogleFonts.frauncesTextTheme(body);
    final textTheme = body.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w700),
      displayMedium:
          display.displayMedium?.copyWith(fontWeight: FontWeight.w700),
      displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineLarge:
          display.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
      headlineMedium:
          display.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall:
          display.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
    );

    final muted = inkC.withValues(alpha: 0.62);

    const transitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FadeUpTransitionsBuilder(),
        TargetPlatform.iOS: _FadeUpTransitionsBuilder(),
        TargetPlatform.linux: _FadeUpTransitionsBuilder(),
        TargetPlatform.macOS: _FadeUpTransitionsBuilder(),
        TargetPlatform.windows: _FadeUpTransitionsBuilder(),
        TargetPlatform.fuchsia: _FadeUpTransitionsBuilder(),
      },
    );

    return base.copyWith(
      pageTransitionsTheme: transitions,
      extensions: const [
        ChezMamaTokens(
          promoRed: promoRed,
          favorite: favorite,
          soldOutGray: soldOutGray,
        ),
      ],
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: inkC,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: inkC,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardC,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: cardC,
        selectedColor: brandOrange.withValues(alpha: 0.16),
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rChip),
        ),
        side: BorderSide(color: inkC.withValues(alpha: 0.08)),
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: inkC,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkSurface2 : Colors.white.withValues(alpha: 0.92),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        prefixIconColor: muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rField),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rField),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rField),
          borderSide: const BorderSide(color: brandOrange, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rField),
          borderSide: BorderSide(color: colorScheme.error, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandOrange,
          foregroundColor: Colors.white,
          disabledBackgroundColor: brandOrange.withValues(alpha: 0.4),
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandOrange,
          side: const BorderSide(color: brandOrange, width: 1.4),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandOrange,
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandOrange,
        foregroundColor: Colors.white,
        elevation: 3,
        highlightElevation: 6,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: brandOrange,
        unselectedLabelColor: muted,
        indicatorColor: brandOrange,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? brandOrange
                : cardC,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : inkC,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: inkC.withValues(alpha: 0.10)),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(rButton),
            ),
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? darkSurface : surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: isDark ? darkSurface : surface,
        showDragHandle: true,
        dragHandleColor: muted,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(rSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardC,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: inkC,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkCard : ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: brandAmber,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rField),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: inkC.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: brandBrown,
        textColor: inkC,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rField),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardC,
        selectedItemColor: brandOrange,
        unselectedItemColor: inkC.withValues(alpha: 0.55),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardC,
        indicatorColor: brandOrange.withValues(alpha: 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return base.textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? brandOrange : inkC.withValues(alpha: 0.55),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? brandOrange : inkC.withValues(alpha: 0.55),
            size: 24,
          );
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandOrange,
      ),
    );
  }

  static List<BoxShadow> softShadow({double opacity = 0.12}) {
    return [
      BoxShadow(
        color: const Color(0xFF5C2E15).withValues(alpha: opacity * 0.55),
        blurRadius: 22,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity * 0.35),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

class ChezMamaTokens extends ThemeExtension<ChezMamaTokens> {
  const ChezMamaTokens({
    required this.promoRed,
    required this.favorite,
    required this.soldOutGray,
  });

  final Color promoRed;
  final Color favorite;
  final Color soldOutGray;

  @override
  ChezMamaTokens copyWith({Color? promoRed, Color? favorite, Color? soldOutGray}) {
    return ChezMamaTokens(
      promoRed: promoRed ?? this.promoRed,
      favorite: favorite ?? this.favorite,
      soldOutGray: soldOutGray ?? this.soldOutGray,
    );
  }

  @override
  ChezMamaTokens lerp(ThemeExtension<ChezMamaTokens>? other, double t) {
    if (other is! ChezMamaTokens) return this;
    return ChezMamaTokens(
      promoRed: Color.lerp(promoRed, other.promoRed, t)!,
      favorite: Color.lerp(favorite, other.favorite, t)!,
      soldOutGray: Color.lerp(soldOutGray, other.soldOutGray, t)!,
    );
  }
}

class _FadeUpTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeUpTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
