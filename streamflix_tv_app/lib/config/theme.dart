import 'package:flutter/material.dart';

class TvTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF2196F3),
      surface: Color(0xFF141414),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
      titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
      bodyLarge: TextStyle(fontSize: 18, color: Colors.white70),
      labelLarge: TextStyle(fontSize: 16, color: Colors.white54),
    ),
  );

  static BoxDecoration focusedDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFF2196F3), width: 3),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF2196F3).withValues(alpha: 0.5),
        blurRadius: 8,
        spreadRadius: 2,
      ),
    ],
  );
}
