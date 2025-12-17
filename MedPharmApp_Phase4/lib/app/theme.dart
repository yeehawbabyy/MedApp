import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.blue;

  static const Color accentColor = Colors.blueAccent;

  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 2,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),

      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
