import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTheme {
  // Midnight Obsidian & Electric Purple Palette
  static const Color pureBlack = Color(0xFF05030A);
  static const Color background = Color(0xFF090614);
  static const Color surface = Color(0xFF110D22);
  static const Color surfaceElevated = Color(0xFF1B1433);
  static const Color surfaceLighter = Color(0xFF261D46);

  // Purple Tones
  static const Color primaryPurple = Color(0xFF8B5CF6);
  static const Color royalPurple = Color(0xFF7C3AED);
  static const Color deepAmethyst = Color(0xFF6D28D9);
  static const Color vividViolet = Color(0xFFA855F7);
  static const Color neonLavender = Color(0xFFC084FC);
  static const Color softLilac = Color(0xFFDDD6FE);
  static const Color neonPurple = Color(0xFF8B5CF6);

  // Accent & Action Colors
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonPink = Color(0xFFF43F5E);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color neonAmber = Color(0xFFFBBF24);

  // Warm Yellow & Orange Mix for Scoreboard & Rewards
  static const Color scoreLightYellow = Color(0xFFFEF08A); // Light sunny yellow
  static const Color scoreAmber = Color(0xFFFBBF24);       // Golden amber
  static const Color scoreOrange = Color(0xFFF97316);      // Warm vibrant orange
  static const Color scoreDeepOrange = Color(0xFFEA580C);  // Sunset orange

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [scoreLightYellow, scoreAmber, scoreOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const List<Color> playerColors = [
    Color(0xFF8B5CF6), // Royal Purple
    Color(0xFFA855F7), // Vivid Violet
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Electric Blue
    Color(0xFFF43F5E), // Coral
  ];

  static const List<String> availableEmojis = [
    '😎', '🤠', '🦊', '🦁', '👑', '🔥', '⚡', '🎉',
    '👻', '🚀', '👽', '🦄', '🍕', '🎸', '🕹️', '💎'
  ];

  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: primaryPurple,
      colorScheme: const ColorScheme.dark(
        primary: primaryPurple,
        secondary: vividViolet,
        surface: surface,
        surfaceContainerHighest: surfaceElevated,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 34,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: 1.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          letterSpacing: 0.5,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 15,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 13,
          color: textSecondary,
        ),
      ),
    );
  }

  static BoxDecoration purpleGlassBox({
    Color? borderColor,
    double radius = 22,
    double opacity = 0.7,
  }) {
    return BoxDecoration(
      color: surface.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? primaryPurple.withValues(alpha: 0.35),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? royalPurple).withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration scoreGlassBox({
    double radius = 18,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          surfaceElevated,
          Color.alphaBlend(scoreOrange.withValues(alpha: 0.12), surfaceElevated),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: scoreAmber.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: scoreOrange.withValues(alpha: 0.15),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ],
    );
  }

  static BoxDecoration glassBox({
    Color? borderColor,
    double radius = 20,
    double opacity = 0.6,
  }) {
    return purpleGlassBox(
      borderColor: borderColor,
      radius: radius,
      opacity: opacity,
    );
  }
}
