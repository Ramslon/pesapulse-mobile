import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../models/user_preferences.dart';
import '../services/startup_refresh_coordinator.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    loadTheme();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('darkMode', isDark);

    notifyListeners();

    // 🔥 sync to backend
    try {
      await ApiService.updatePreferences({'dark_mode': isDark});
    } catch (e) {
      // ignore network failure (offline support)
    }
  }

  void loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final isDark = prefs.getBool('darkMode') ?? false;

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

    notifyListeners();
  }

  Future<void> syncWithBackend() async {
    try {
      final data = await StartupRefreshCoordinator.instance.run(
        'preferences',
        () async {
          return await ApiService.getPreferences();
        },
      );

      final prefs = UserPreferences.fromJson(data);

      _themeMode = prefs.darkMode ? ThemeMode.dark : ThemeMode.light;

      final localPrefs = await SharedPreferences.getInstance();

      await localPrefs.setBool('darkMode', prefs.darkMode);

      notifyListeners();
    } catch (e) {
      debugPrint('Theme sync failed: $e');

      rethrow;
    }
  }
}
