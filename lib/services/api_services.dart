import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';

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

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard-summary'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    return jsonDecode(response.body);
  }

  static Future<void> updatePreferences(Map<String, dynamic> data) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/preferences'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update preferences');
    }
  }

  static Future<Map<String, dynamic>> getPreferences() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/preferences'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load preferences');
    }

    final data = jsonDecode(response.body);

    // 🔥 NORMALIZE (MERGE SAFETY LAYER)
    return {
      'dark_mode': data['dark_mode'] ?? false,
      'notifications_enabled': data['notifications_enabled'] ?? true,

      // old system fallback
      'daily_reminder': data['daily_reminder'] ?? false,
      'expense_alerts': data['expense_alerts'] ?? false,
      'weekly_summary': data['weekly_summary'] ?? false,
    };
  }

  static Future<UserPreferences> getUserPreferences() async {
    final data = await getPreferences();

    return UserPreferences.fromJson(data);
  }

  static Future<Map<String, dynamic>> getBudgetSummary() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/budget-summary'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> setBudget(double amount) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/budget'),

      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'amount': amount}),
    );

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getGoals() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final token = await getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/goals'),

      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'title': title,
        'target_amount': targetAmount,
        'target_date': targetDate,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateGoalProgress(
    int goalId,
    double amount,
  ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/goals/$goalId/progress'),

      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({'amount': amount}),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getGoalAnalytics() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/analytics'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }
}
