import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _guestKey = "is_guest";

  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_guestKey, true);

    await prefs.setString("owner_id", "guest");

    await prefs.remove("token");
  }

  static Future<void> logoutGuest() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_guestKey);
    await prefs.remove("owner_id");
  }

  static Future<void> loginUser(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_guestKey, false);

    await prefs.setString("owner_id", ownerId);
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

    await prefs.remove("owner_id");
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    return token != null && token.isNotEmpty;
  }

  static Future<String> currentOwnerId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("owner_id") ?? "guest";
  }
}
