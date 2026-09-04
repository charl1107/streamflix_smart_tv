import 'package:flutter/material.dart';

class TvTheme {
  // Cineko / Streamflix-CF Color Tokens
  static const Color background = Color(0xFF09090B); // True obsidian black
  static const Color surface = Color(0xFF141417); // Frosted card dark
  static const Color surfaceBorder = Color(0x1FFFFFFF); // 12% white glass border
  static const Color primary = Color(0xFFE50914); // Cineko Crimson Red
  static const Color primaryVariant = Color(0xFFF43F5E); // Rose Coral
  static const Color accentRating = Color(0xFFFBBF24); // Warm Amber/Gold for Star Ratings

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accentRating,
      surface: surface,
    ),
    cardTheme: CardThemeData(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: surfaceBorder, width: 1),
      ),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
      labelLarge: TextStyle(fontSize: 14, color: Colors.white54, fontWeight: FontWeight.w500),
    ),
  );

  static BoxDecoration focusedDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: primary, width: 2.5),
    boxShadow: [
      BoxShadow(
        color: primary.withValues(alpha: 0.55),
        blurRadius: 18,
        spreadRadius: 3,
      ),
    ],
  );
}
