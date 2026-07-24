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

  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard');
    }

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

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value is int) return value == 1;

    if (value is String) {
      return value == "1" || value.toLowerCase() == "true";
    }

    return false;
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
      'dark_mode': _toBool(data['dark_mode']),
      'notifications_enabled': _toBool(data['notifications_enabled']),

      // old system fallback
      'daily_reminder': _toBool(data['daily_reminder']),
      'expense_alerts': _toBool(data['expense_alerts']),
      'weekly_summary': _toBool(data['weekly_summary']),
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

  static Future<void> deleteBudget() async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/budget'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete budget');
    }
  }

  static Future<Map<String, dynamic>> getFinancialInsights() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/financial-insights'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load financial insights');
  }

  static Future<Map<String, dynamic>> getGoalInsights(int goalId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/$goalId/insights'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Insights ${response.statusCode}: ${response.body}");
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

    final body = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return body;
    }

    throw Exception(body["message"] ?? "Failed to create goal");
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

  static Future<List<dynamic>> getUpcomingGoalDeadlines() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/upcoming-deadlines'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
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

  static Future<Map<String, dynamic>> getGoalForecast(int goalId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/$goalId/forecast'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception("Forecast ${response.statusCode}: ${response.body}");
  }

  static Future<void> archiveGoal(int goalId) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/goals/$goalId/archive'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  static Future<List<dynamic>> getArchivedGoals() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/archived'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    throw Exception('Failed to load archived goals');
  }

  static Future<void> restoreGoal(int goalId) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/goals/$goalId/restore'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }
  }

  static Future<void> deleteGoal(int goalId) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/goals/$goalId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Failed to delete goal',
      );
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/change-password'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      },
    );

    if (response.statusCode == 200) {
      return;
    }

    final body = jsonDecode(response.body);

    if (body['errors'] != null) {
      throw Exception(body['errors']);
    }

    throw Exception(body['message'] ?? 'Failed to change password.');
  }
}
