import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import '../exceptions/rate_limit_exception.dart';
import '../exceptions/auth_exception.dart';

class ApiService {
  static const String baseUrl = 'https://pesapulse-t9hk.onrender.com/api';
  static String token = '';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('token');
  }

  static Never _handleRateLimitResponse(http.Response response) {
    String message = 'Too many requests. Please try again later.';

    int? retryAfter;
    int? remaining;

    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          message = data['message'].toString();
        }

        if (data['retry_after'] != null) {
          retryAfter = int.tryParse(data['retry_after'].toString());
        }

        if (data['remaining'] != null) {
          remaining = int.tryParse(data['remaining'].toString());
        }
      }
    } catch (_) {
      // Ignore invalid JSON and continue using headers.
    }

    // Laravel Retry-After header takes precedence.
    final retryAfterHeader = response.headers['retry-after'];

    if (retryAfterHeader != null) {
      retryAfter = int.tryParse(retryAfterHeader);
    }

    final remainingHeader = response.headers['x-ratelimit-remaining'];

    if (remainingHeader != null) {
      remaining = int.tryParse(remainingHeader);
    }

    throw RateLimitException(
      message: message,
      retryAfter: retryAfter,
      remaining: remaining,
    );
  }

  static void _checkRateLimit(http.Response response) {
    if (response.statusCode == 429) {
      _handleRateLimitResponse(response);
    }
  }

  static int? _getRemainingAttempts(http.Response response) {
    final header = response.headers['x-ratelimit-remaining'];

    if (header == null) {
      return null;
    }

    return int.tryParse(header);
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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    final remaining = _getRemainingAttempts(response);

    throw AuthException(
      message: body["message"] ?? "Login failed",
      remaining: remaining,
    );
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/logout'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await prefs.remove('token');
      return;
    }

    throw Exception('Failed to logout (${response.statusCode}).');
  }

  static Future<void> deleteAccount(String password) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/delete-account'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'password': password}),
    );

    _checkRateLimit(response);

    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException(message: 'Invalid response from server.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // Laravel validation errors
    if (response.statusCode == 422 && body['errors'] != null) {
      throw AuthException(message: jsonEncode(body['errors']));
    }

    // Authentication/account/general error
    throw AuthException(
      message: body['message'] ?? 'Failed to delete account.',
    );
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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    final remaining = _getRemainingAttempts(response);

    throw AuthException(
      message: body["message"] ?? "Registration failed",
      remaining: remaining,
    );
  }

  static Future<Map<String, dynamic>> migrateGuestData({
    required String ownerId,
    required Map<String, dynamic> data,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw AuthException(message: 'Authentication token is missing.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/guest/migrate'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'owner_id': ownerId,
        'expenses': data['expenses'] ?? [],
        'goals': data['goals'] ?? [],
        'budgets': data['budgets'] ?? [],
        'settings': data['settings'] ?? [],
      }),
    );

    // 429 → RateLimitException
    _checkRateLimit(response);

    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw AuthException(
        message:
            'Invalid response from migration server '
            '(${response.statusCode}).',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw AuthException(
      message: body['message']?.toString() ?? 'Guest data migration failed.',
      remaining: _getRemainingAttempts(response),
    );
  }

  static Future<Map<String, dynamic>> addExpense(
    String title,
    String amount,
    String category,
    String expenseDate,
    String description,
  ) async {
    final token = await getToken();

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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to add expense.');
  }

  static Future<dynamic> getExpenses({int page = 1}) async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/expenses?page=$page'),

      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

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
    final token = await getToken();

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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to update expense.');
  }

  static Future<void> deleteExpense(int id) async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final body = jsonDecode(response.body);

      throw Exception(body['message'] ?? 'Failed to delete expense.');
    } catch (_) {
      throw Exception('Failed to delete expense (${response.statusCode}).');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
    String name,
    String email,
  ) async {
    final token = await getToken();

    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name, 'email': email}),
    );

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to update profile.');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to load profile');
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard-summary'),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    _checkRateLimit(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to load dashboard summary (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

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

    _checkRateLimit(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = jsonDecode(response.body);

    throw Exception(body['message'] ?? 'Failed to update preferences.');
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

    _checkRateLimit(response);

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

    // 429 → RateLimitException
    _checkRateLimit(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load budget summary (${response.statusCode})');
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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to set budget.');
  }

  static Future<void> deleteBudget() async {
    final token = await getToken();

    final response = await http.delete(
      Uri.parse('$baseUrl/budget'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    try {
      final body = jsonDecode(response.body);

      throw Exception(body['message'] ?? 'Failed to delete budget.');
    } catch (_) {
      throw Exception('Failed to delete budget (${response.statusCode}).');
    }
  }

  static Future<Map<String, dynamic>> getFinancialInsights() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/financial-insights'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

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

    _checkRateLimit(response);

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

    _checkRateLimit(response);

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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to create goal.');
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

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to update goal progress.');
  }

  static Future<List<dynamic>> getUpcomingGoalDeadlines() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/upcoming-deadlines'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Failed to load upcoming goal deadlines '
      '(${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> getGoalAnalytics() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/analytics'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getGoalForecast(int goalId) async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/$goalId/forecast'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    _checkRateLimit(response);

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

    _checkRateLimit(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = jsonDecode(response.body);

    throw Exception(body['message'] ?? 'Failed to archive goal.');
  }

  static Future<List<dynamic>> getArchivedGoals() async {
    final token = await getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/goals/archived'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    _checkRateLimit(response);
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
    _checkRateLimit(response);

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

    _checkRateLimit(response);

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
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return;
    }

    final remaining = _getRemainingAttempts(response);

    if (response.statusCode == 422 && body['errors'] != null) {
      throw AuthException(
        message: jsonEncode(body['errors']),
        remaining: remaining,
      );
    }

    throw AuthException(
      message: body['message'] ?? 'Failed to change password.',
      remaining: remaining,
    );
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email}),
    );

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Failed to send password reset OTP.');
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    _checkRateLimit(response);

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message'] ?? 'OTP verification failed.');
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reset-password'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': confirmPassword,
      }),
    );

    _checkRateLimit(response);

    final body = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body['message'] ?? 'Password reset failed.');
  }
}
