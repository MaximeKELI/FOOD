import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised design system for the Food app.
///
/// Everything visual flows from here: a single set of brand colours, a small
/// scale of corner radii, and fully configured component themes so individual
/// screens stay clean and consistent in both light and dark mode.
class ChezMamaTheme {
  // ---- Brand palette ------------------------------------------------------
  static const Color brandOrange = Color(0xFFFF7A18);
  static const Color brandAmber = Color(0xFFFFC24C);
  static const Color brandBrown = Color(0xFF6E3B1F);

  // Light surfaces
  static const Color ink = Color(0xFF1B1B1F);
  static const Color surface = Color(0xFFFFFBF6); // warm off-white background
  static const Color surface2 = Color(0xFFFFF2E2); // peach tint blocks
  static const Color card = Color(0xFFFFFFFF);

  // Dark surfaces
  static const Color darkBg = Color(0xFF161310);
  static const Color darkSurface = Color(0xFF221E1A);
  static const Color darkCard = Color(0xFF2A2520);
  static const Color darkSurface2 = Color(0xFF332B22);
  static const Color darkInk = Color(0xFFF3EDE6);

  // ---- Radius scale -------------------------------------------------------
  static const double rField = 14;
  static const double rButton = 16;
  static const double rCard = 18;
  static const double rSheet = 26;
  static const double rChip = 999;

  // ---- Theme-aware helpers (use inside widgets) ---------------------------
  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Elevated surface colour (cards, nav bar, sheets).
  static Color cardColor(BuildContext c) => _isDark(c) ? darkCard : card;

  /// Subtle tinted block (price boxes, progress cards, inputs).
  static Color subtleSurface(BuildContext c) =>
      _isDark(c) ? darkSurface2 : surface2;

  /// Primary text colour.
  static Color inkColor(BuildContext c) => _isDark(c) ? darkInk : ink;

  /// Muted text colour.
  static Color mutedInk(BuildContext c) =>
      (_isDark(c) ? darkInk : ink).withValues(alpha: 0.62);

  /// Warm gradient used behind auth / splash / home header.
  static LinearGradient headerGradient(BuildContext c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: _isDark(c)
          ? const [Color(0xFF2A1C10), darkBg]
          : const [Color(0xFFFFE3C3), surface],
    );
  }

  // ---- Themes -------------------------------------------------------------
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

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.poppinsTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
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
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: inkC,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
          color: inkC,
        ),
      ),
      cardTheme: CardTheme(
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
          fontWeight: FontWeight.w600,
          color: inkC,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: muted, fontWeight: FontWeight.w500),
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
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
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
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
      tabBarTheme: TabBarTheme(
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
      dialogTheme: DialogTheme(
        backgroundColor: cardC,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
        ),
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
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
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: brandOrange,
      ),
    );
  }

  static List<BoxShadow> softShadow({double opacity = 0.12}) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: opacity * 0.6),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ];
  }
}
