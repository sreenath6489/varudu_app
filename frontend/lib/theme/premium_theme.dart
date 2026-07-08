import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumTheme {
  // Premium Color Palette
  static const Color primaryBgDark = Color(0xFF1C0006);
  static const Color primaryBgBlack = Color(0xFF0A0002);
  static const Color surfaceCard = Color(0xFF1E1215);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color crimsonRed = Color(0xFFE63946);
  static const Color activeBlue = Color(0xFF0071E3);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSilver = Color(0xFFD1D1D6);
  static const Color textMuted = Color(0xFF8E8E93);

  // Linear Gradient for premium surfaces
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [primaryBgDark, primaryBgBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [crimsonRed, Color(0xFF9E0B20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme Data mapping
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBgBlack,
      primaryColor: goldAccent,
      cardColor: surfaceCard,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: crimsonRed,
        surface: surfaceCard,
        error: crimsonRed,
      ),
      textTheme: TextTheme(
        // Serif Headers
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        titleLarge: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textWhite,
          letterSpacing: 0.5,
        ),
        // Sans-Serif body/labels
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textSilver,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textSilver,
        ),
        labelLarge: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textWhite,
        ),
        labelMedium: GoogleFonts.outfit(
          fontSize: 12,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryBgBlack,
        selectedItemColor: goldAccent,
        unselectedItemColor: textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
