import 'package:flutter/material.dart';

class CustomTheme {
  // Colores personalizados elegantes
  static const Color _goldAccent = Color(0xFFD4AF37); // Oro elegante
  static const Color _darkGold = Color(0xFFB8860B); // Oro oscuro
  static const Color _charcoal = Color(0xFF2C2C2C); // Carbón
  static const Color _deepNavy = Color(0xFF1A237E); // Azul marino profundo
  static const Color _slate = Color(0xFF37474F); // Pizarra
  static const Color _cream = Color(0xFFFAF9F6); // Crema
  static const Color _pearl = Color(0xFFF8F8FF); // Perla
  
  // Tema claro - Elegancia sofisticada con azul marino y oro
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: _deepNavy,
    scaffoldBackgroundColor: _pearl,
    colorScheme: ColorScheme.light(
      primary: _deepNavy,
      secondary: _goldAccent,
      tertiary: _darkGold,
      onPrimary: Colors.white,
      surface: _cream,
      onSurface: _charcoal,
      surfaceContainerHighest: Colors.white,
      outline: _slate.withValues(alpha: 0.3),
      error: const Color(0xFFB71C1C),
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _deepNavy,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: _charcoal.withValues(alpha: 0.3),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _goldAccent,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _charcoal,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _deepNavy,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _charcoal),
      bodyMedium: TextStyle(fontSize: 14, color: _slate),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _deepNavy,
      ),
    ),
    iconTheme: IconThemeData(
      color: _deepNavy,
      size: 24,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _deepNavy,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _deepNavy,
        side: BorderSide(color: _deepNavy, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: _deepNavy.withValues(alpha: 0.1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _cream,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _slate.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _deepNavy, width: 2),
      ),
      labelStyle: TextStyle(color: _deepNavy),
      hintStyle: TextStyle(color: _slate.withValues(alpha: 0.6)),
    ),
  );

  // Tema oscuro - Elegancia premium con negro y oro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: _goldAccent,
    scaffoldBackgroundColor: const Color(0xFF121212), // Negro profundo
    colorScheme: ColorScheme.dark(
      primary: _goldAccent,
      secondary: _darkGold,
      tertiary: const Color(0xFFFFD700), // Oro brillante
      onPrimary: Colors.black,
      surface: _charcoal,
      onSurface: Colors.white,
      surfaceContainerHighest: const Color(0xFF1E1E1E),
      outline: _goldAccent.withValues(alpha: 0.4),
      error: const Color(0xFFFF6B6B),
      onError: Colors.white,
      inversePrimary: _darkGold,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: _goldAccent,
      elevation: 2,
      shadowColor: _goldAccent.withValues(alpha: 0.2),
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _goldAccent,
        letterSpacing: 0.5,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _goldAccent,
      foregroundColor: Colors.black,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _goldAccent,
        letterSpacing: 0.5,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      bodyLarge: const TextStyle(fontSize: 16, color: Colors.white),
      bodyMedium: const TextStyle(fontSize: 14, color: Colors.white70),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: _goldAccent,
      ),
    ),
    iconTheme: IconThemeData(
      color: _goldAccent,
      size: 24,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _goldAccent,
        foregroundColor: Colors.black,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shadowColor: _goldAccent.withValues(alpha: 0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _goldAccent,
        side: BorderSide(color: _goldAccent, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    cardTheme: CardThemeData(
      color: _charcoal,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: _goldAccent.withValues(alpha: 0.1),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _charcoal,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _goldAccent.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _goldAccent, width: 2),
      ),
      labelStyle: TextStyle(color: _goldAccent),
      hintStyle: const TextStyle(color: Colors.white54),
    ),
  );
}
