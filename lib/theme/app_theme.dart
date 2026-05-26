import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    primarySwatch: Colors.green,

    scaffoldBackgroundColor: Colors.grey[100],

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),

        borderSide: BorderSide.none,
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    primarySwatch: Colors.green,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,

      fillColor: Colors.grey[900],

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),

        borderSide: BorderSide.none,
      ),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
