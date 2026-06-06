import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://pesapulse-t9hk.onrender.com/api';
  static String token = '';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  static Future<Map<String, dynamic>> loginUser(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    await http.post(
      Uri.parse('$baseUrl/logout'),

      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    await prefs.remove('token');
  }

  static Future<Map<String, dynamic>> registerUser(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> addExpense(
    String title,
    String amount,
    String category,
    String expenseDate,
    String description,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'title': title,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate,
        'description': description,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<dynamic> getExpenses({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/expenses?page=$page'),

      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateExpense(
    int id,
    String title,
    String amount,
    String category,
    String expenseDate,
    String description,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/expenses/$id'),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },

      body: jsonEncode({
        'title': title,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate,
        'description': description,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<void> deleteExpense(int id) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),

      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
  }

  static Future<Map<String, dynamic>> updateProfile(
    String name,
    String email,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),

      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},

      body: {'name': name, 'email': email},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard-summary'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updatePreferences(
    bool dailyReminder,
    bool expenseAlerts,
    bool weeklySummary,
  ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/preferences'),

      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'daily_reminder': dailyReminder,
        'expense_alerts': expenseAlerts,
        'weekly_summary': weeklySummary,
      }),
    );

    return jsonDecode(response.body);
  }
}
