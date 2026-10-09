import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameTheme {
  // Primary Dark Palette from PDF Design
  static const Color pureBlack = Color(0xFF0D0A14);
  static const Color background = Color(0xFF13111C);
  static const Color surface = Color(0xFF1F1C2E);
  static const Color surfaceElevated = Color(0xFF28243A);
  static const Color surfaceLighter = Color(0xFF332F4A);

  // Purple Tones
  static const Color primaryPurple = Color(0xFF9D84F6); // Primary filled action button light purple
  static const Color royalPurple = Color(0xFF7C5CFC);   // Circle step badge purple
  static const Color deepAmethyst = Color(0xFF6D28D9);
  static const Color vividViolet = Color(0xFFA855F7);
  static const Color neonLavender = Color(0xFFB197FC);
  static const Color softLilac = Color(0xFFDDD6FE);
  static const Color neonPurple = Color(0xFF9D84F6);

  // Accent & Action Colors (Exact matching PDF)
  static const Color neonCyan = Color(0xFF06B6D4);
  static const Color neonPink = Color(0xFFEE6083);      // Dare / Pink action color
  static const Color neonGreen = Color(0xFF4CD9A4);     // Truth / Mint green action color
  static const Color neonAmber = Color(0xFFF59E0B);     // Amber / Host badge / Wager color

  // PDF Palette colors for wheel & avatars
  static const Color wheelPink = Color(0xFFEE6083);
  static const Color wheelPurple = Color(0xFFB197FC);
  static const Color wheelOrange = Color(0xFFF59E0B);
  static const Color wheelGreen = Color(0xFF4CD9A4);

  // Warm Yellow & Orange Mix for Scoreboard & Rewards
  static const Color scoreLightYellow = Color(0xFFFEF08A);
  static const Color scoreAmber = Color(0xFFFBBF24);
  static const Color scoreOrange = Color(0xFFF97316);
  static const Color scoreDeepOrange = Color(0xFFEA580C);

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [scoreLightYellow, scoreAmber, scoreOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8B9E);

  static const List<Color> playerColors = [
    Color(0xFFF59E0B), // Yellow/Orange
    Color(0xFF4CD9A4), // Mint Green
    Color(0xFF9D84F6), // Light Purple
    Color(0xFFEE6083), // Pink Coral
    Color(0xFF06B6D4), // Cyan
    Color(0xFF3B82F6), // Blue
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
        secondary: royalPurple,
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

  static BoxDecoration cardBox({
    Color? borderColor,
    double radius = 20,
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? Colors.transparent,
        width: borderColor != null ? 1.5 : 0,
      ),
    );
  }

  static BoxDecoration purpleGlassBox({
    Color? borderColor,
    double radius = 20,
    double opacity = 1.0,
  }) {
    return cardBox(borderColor: borderColor, radius: radius);
  }

  static BoxDecoration glassBox({
    Color? borderColor,
    double radius = 20,
    double opacity = 1.0,
  }) {
    return cardBox(borderColor: borderColor, radius: radius);
  }

  static Widget buildStepBadge(String number, String title) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: royalPurple,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
