import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTheme {
  static const Color background = Color(0xFF090614);
  static const Color surface = Color(0xFF140F26);
  static const Color surfaceElevated = Color(0xFF1F173B);
  
  static const Color neonPink = Color(0xFFF43F5E);
  static const Color neonPurple = Color(0xFF8B5CF6);
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color neonGreen = Color(0xFF10B981);
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);

  static const List<Color> playerColors = [
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Coral Red
    Color(0xFFA855F7), // Violet
  ];

  static const List<String> availableEmojis = [
    '😎', '🤠', '🦊', '🦁', '👑', '🔥', '⚡', '🎉',
    '👻', '🚀', '👽', '🦄', '🍕', '🎸', '🕹️', '💎'
  ];

  static ThemeData get themeData {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: background,
      primaryColor: neonPurple,
      colorScheme: const ColorScheme.dark(
        primary: neonPurple,
        secondary: neonPink,
        surface: surface,
        surfaceContainerHighest: surfaceElevated,
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: textPrimary,
          letterSpacing: 1.2,
        ),
        headlineMedium: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
    );
  }

  static BoxDecoration glassBox({
    Color? borderColor,
    double radius = 20,
    double opacity = 0.6,
  }) {
    return BoxDecoration(
      color: surfaceElevated.withValues(alpha: opacity),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? neonPurple.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: (borderColor ?? neonPurple).withValues(alpha: 0.15),
          blurRadius: 16,
          spreadRadius: -2,
        ),
      ],
    );
  }
}
