import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumTheme {
  // Exact varudu.in Sunlit Sand & Warm Ivory Palette
  static const Color primaryBgLight = Color(0xFFF4EDE4); // Sunlit warm sand wall
  static const Color primaryBgDark = Color(0xFFEBE0D2);  // Soft shaded sand
  static const Color primaryBgBlack = Color(0xFFF4EDE4); // Backwards compat
  static const Color surfaceCard = Color(0xFFFFFDFB);    // Pure clean alabaster white
  static const Color surfaceElevated = Color(0xFFFAF6F0); // Off-white cream
  
  // Signature varudu.in Deep Coffee / Dark Chocolate Accent
  static const Color darkEspresso = Color(0xFF3E2D20);   // Dark coffee pill/button
  static const Color darkEspressoHover = Color(0xFF2E2016);
  
  // Accents & Golds from varudu.in
  static const Color goldAccent = Color(0xFFC59B4E);   // Warm metallic gold
  static const Color goldBright = Color(0xFFDFB76C);   // Radiant sun gold
  static const Color goldLight = Color(0xFFF0E7DA);    // Light champagne
  static const Color goldBorder = Color(0xFFE8DFD3);   // Soft hairline border
  static const Color crimsonRed = Color(0xFFD32F2F);   // Botanical rose red
  
  // Chat colors (from Image 6)
  static const Color activeBlue = Color(0xFF007AFF);   // Royal blue user message bubble
  static const Color partnerBubble = Color(0xFFF0ECE6); // Soft stone partner bubble
  
  // Typography
  static const Color textWhite = Color(0xFF241C15);    // Deep espresso charcoal for main titles & names
  static const Color textSilver = Color(0xFF756557);   // Warm muted mocha for subtitles
  static const Color textMuted = Color(0xFFA09285);    // Soft almond taupe
  static const Color badgeGreen = Color(0xFF2E7D32);   // Emerald online/verification dot

  // Gradients
  static const LinearGradient sunlitGradient = LinearGradient(
    colors: [Color(0xFFF7F2EB), Color(0xFFECE2D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logoGoldGradient = LinearGradient(
    colors: [Color(0xFFDFB76C), Color(0xFFB88E48), Color(0xFF9E722C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [Color(0xFF4A3728), Color(0xFF35261B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFDFB76C), Color(0xFFB88E48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFE53935), Color(0xFFC62828)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient beigeGradient = sunlitGradient;
  static const LinearGradient premiumGradient = sunlitGradient;
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFDFB), Color(0xFFFAF6F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Soft diffused drop shadow matching varudu.in cards
  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x0F4A3728),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> pillShadow = [
    BoxShadow(
      color: Color(0x143E2D20),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: primaryBgLight,
      primaryColor: darkEspresso,
      cardColor: surfaceCard,
      canvasColor: primaryBgLight,
      colorScheme: const ColorScheme.light(
        primary: darkEspresso,
        secondary: goldAccent,
        surface: surfaceCard,
        error: crimsonRed,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        titleLarge: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: textSilver,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13,
          color: textSilver,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
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
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textWhite,
          letterSpacing: 0.5,
        ),
        iconTheme: const IconThemeData(color: textWhite),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}
