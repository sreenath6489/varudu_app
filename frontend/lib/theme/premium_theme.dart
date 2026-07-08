import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumTheme {
  // Pure Apple Style Light Color Palette (Pure White background, Black fonts/borders)
  static const Color primaryBgLight = Color(0xFFFFFFFF);
  static const Color primaryBgDark = Color(0xFFFFFFFF); 
  static const Color primaryBgBlack = Color(0xFFFFFFFF); 
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color goldAccent = Color(0xFF000000); // Black accent
  static const Color goldLight = Color(0xFFE5E5EA); // Apple Light Gray border/accent
  static const Color crimsonRed = Color(0xFF000000); // Black highlights
  static const Color activeBlue = Color(0xFF000000); // Black action triggers
  static const Color textWhite = Color(0xFF000000); // Pure Black text
  static const Color textSilver = Color(0xFF1C1C1E); // Very dark gray body text
  static const Color textMuted = Color(0xFF8E8E93); // Muted gray text

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primaryBgLight, primaryBgLight],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, goldAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [goldAccent, goldAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: primaryBgLight,
      primaryColor: goldAccent,
      cardColor: surfaceCard,
      colorScheme: const ColorScheme.light(
        primary: goldAccent,
        secondary: crimsonRed,
        surface: surfaceCard,
        error: crimsonRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textWhite,
          letterSpacing: 0.5,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textSilver,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSilver,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: primaryBgLight, // White text on black button
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBgLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBgLight,
        selectedItemColor: goldAccent,
        unselectedItemColor: textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // Backwards compatibility getter
  static ThemeData get darkTheme => lightTheme;
}
