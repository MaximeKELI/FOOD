import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChezMamaTheme {
  static const Color brandOrange = Color(0xFFFF7A18);
  static const Color brandAmber = Color(0xFFFFC24C);
  static const Color brandBrown = Color(0xFF6E3B1F);
  static const Color ink = Color(0xFF1B1B1F);
  static const Color surface = Color(0xFFFFFBF6);
  static const Color surface2 = Color(0xFFFFF2E2);

  static const double rCard = 18;
  static const double rChip = 999;

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: brandOrange,
      brightness: Brightness.light,
      primary: brandOrange,
      secondary: brandAmber,
      surface: surface,
      onSurface: ink,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.poppinsTextTheme(),
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rCard),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rChip),
        ),
        side: const BorderSide(color: Color(0x00000000)),
        labelStyle: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: brandOrange,
        unselectedItemColor: ink.withValues(alpha: 0.55),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: base.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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

