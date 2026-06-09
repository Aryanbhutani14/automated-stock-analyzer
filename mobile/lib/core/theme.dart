import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      primaryColor: const Color(0xFF6366F1),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF6366F1),
        secondary: Color(0xFF06B6D4),
        surface: Color(0xFF161C2D),
        error: Color(0xFFEF4444),
      ),
      fontFamily: 'Plus Jakarta Sans',
      cardTheme: const CardTheme(
        color: Color(0xFF161C2D),
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B0F19),
        elevation: 0,
      ),
    );
  }
}
