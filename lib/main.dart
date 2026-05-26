import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'PesaPulse',

      themeMode: themeProvider.themeMode,

      theme: ThemeData(
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

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,

          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),

            borderSide: BorderSide.none,
          ),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,

        primarySwatch: Colors.green,

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
