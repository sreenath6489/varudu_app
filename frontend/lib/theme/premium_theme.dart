import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumTheme {
  // Luxurious Royal Beige Color Palette
  static const Color primaryBgLight = Color(0xFFF9F6F0); // Warm ivory linen
  static const Color primaryBgDark = Color(0xFFF2ECE1);  // Warm sand
  static const Color primaryBgBlack = Color(0xFFF9F6F0); // Replaced black with warm beige
  static const Color surfaceCard = Color(0xFFFFFDF9);    // Pure alabaster ivory silk
  static const Color surfaceElevated = Color(0xFFFAF4EA); // Slightly warm golden cream
  
  // Accents
  static const Color goldAccent = Color(0xFFC5933A);   // Royal Champagne Antique Gold
  static const Color goldBright = Color(0xFFE5B558);   // Radiant warm gold
  static const Color goldLight = Color(0xFFEFE8DC);    // Soft champagne sand border
  static const Color goldBorder = Color(0xFFE4D8C4);   // Refined beige card border
  static const Color crimsonRed = Color(0xFFA82845);   // Regal Ruby Rose Maroon
  static const Color activeBlue = Color(0xFF9E6E24);   // Royal Bronze Amber
  
  // High-contrast readable typography on beige
  static const Color textWhite = Color(0xFF241C15);    // Deepest Royal Espresso Noir
  static const Color textSilver = Color(0xFF5C4E42);   // Warm Roasted Mocha
  static const Color textMuted = Color(0xFF9E8E80);    // Warm Sand Biscuit Tan
  static const Color badgeGreen = Color(0xFF2E7D32);   // Emerald verification badge

  // Gradients
  static const LinearGradient beigeGradient = LinearGradient(
    colors: [Color(0xFFFAF7F2), Color(0xFFF0E8DC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFFFFDF9), Color(0xFFF6EFE3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFDFB76C), Color(0xFFBD8C38)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFFC5933A), Color(0xFFA67426)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFDF9), Color(0xFFF8F3EA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFC43856), Color(0xFF9B1D38)],
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
      canvasColor: primaryBgLight,
      colorScheme: const ColorScheme.light(
        primary: goldAccent,
        secondary: crimsonRed,
        surface: surfaceCard,
        error: crimsonRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textWhite,
          letterSpacing: 0.5,
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
          color: Colors.white, // White text on gold button
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          color: textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textWhite,
          letterSpacing: 1.0,
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
        elevation: 0,
      ),
    );
  }

  // Backwards compatibility getter
  static ThemeData get darkTheme => lightTheme;
}
