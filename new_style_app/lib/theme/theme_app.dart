import 'package:flutter/material.dart';

class CustomTheme {
  // Tema claro
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.blueAccent,
      onPrimary: Colors.white, // texto/icono sobre primary
      surface: Colors.white,
      onSurface: Colors.black, // texto sobre surface
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black, // nombre de usuario en claro
      ),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    ),
    iconTheme: const IconThemeData(
      color: Colors.blue, // íconos en claro
    ),
  );

  // Tema oscuro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF121212),
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white70,
      onPrimary: Colors.black, // texto/icono sobre primary
      surface: Color(0xFF1F1F1F),
      onSurface: Colors.white, // texto sobre surface
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF222222),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color.fromARGB(255, 190, 27, 27),
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white, // nombre de usuario en oscuro
      ),
      bodyMedium: TextStyle(fontSize: 16, color: Color(0xFFDDDDDD)),
    ),
    iconTheme: const IconThemeData(
      color: Colors.white, // íconos en oscuro
    ),
  );
}
