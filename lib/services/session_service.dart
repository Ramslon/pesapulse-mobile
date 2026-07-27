import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _guestKey = "is_guest";

  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_guestKey, true);
  }

  static Future<void> loginUser() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_guestKey, false);
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_guestKey) ?? false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_guestKey);

    // remove authentication token
    await prefs.remove("token");
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    return token != null && token.isNotEmpty;
  }
}
