import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import '../exceptions/rate_limit_exception.dart';
import '../exceptions/auth_exception.dart';

class ApiService {
  static const String baseUrl = 'https://pesapulse-t9hk.onrender.com/api';
  static String token = '';
  static const Duration _requestTimeout = Duration(seconds: 15);

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('token');

    if (storedToken != null && storedToken.isNotEmpty) {
      token = storedToken;
      return storedToken;
    }

    return null;
  }

  static Future<http.Response> _request({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    bool authenticated = true,
  }) async {
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (authenticated) {
      final storedToken = await getToken();

      final authToken = storedToken != null && storedToken.isNotEmpty
          ? storedToken
          : token;

      if (authToken.isNotEmpty) {
        requestHeaders['Authorization'] = 'Bearer $authToken';
      }
    }

    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http
              .get(uri, headers: requestHeaders)
              .timeout(_requestTimeout);

          break;

        case 'POST':
          response = await http
              .post(uri, headers: requestHeaders, body: body)
              .timeout(_requestTimeout);

          break;

        case 'PUT':
          response = await http
              .put(uri, headers: requestHeaders, body: body)
              .timeout(_requestTimeout);

          break;

        case 'PATCH':
          response = await http
              .patch(uri, headers: requestHeaders, body: body)
              .timeout(_requestTimeout);

          break;

        case 'DELETE':
          response = await http
              .delete(uri, headers: requestHeaders, body: body)
              .timeout(_requestTimeout);

          break;

        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      _checkRateLimit(response);

      if (response.statusCode == 401) {
        throw AuthException(
          message: 'Your session has expired. Please log in again.',
        );
      }

      return response;
    } on TimeoutException {
      throw Exception(
        'The request timed out. Please check your internet connection and try again.',
      );
    } on http.ClientException {
      rethrow;
    }
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
    final response = await _request(
      method: 'POST',
      endpoint: '/login',
      authenticated: false,
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final data = _decodeResponseBody(response);

    final remaining = _getRemainingAttempts(response);

    throw AuthException(
      message: data["message"] ?? "Login failed",
      remaining: remaining,
    );
  }

  static Map<String, dynamic> _decodeResponseBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {};
  }

  static Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();

    final response = await _request(method: 'POST', endpoint: '/logout');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await prefs.remove('token');
      token = '';
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(
      body['message']?.toString() ??
          'Failed to logout (${response.statusCode}).',
    );
  }

  static Future<void> deleteAccount(String password) async {
    final response = await _request(
      method: 'DELETE',
      endpoint: '/delete-account',
      body: jsonEncode({'password': password}),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 422 && body['errors'] != null) {
      throw AuthException(message: jsonEncode(body['errors']));
    }

    throw AuthException(
      message: body['message']?.toString() ?? 'Failed to delete account.',
    );
  }

  static Future<Map<String, dynamic>> registerUser(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await _request(
      method: 'POST',
      endpoint: '/register',
      authenticated: false,
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final data = _decodeResponseBody(response);

    final remaining = _getRemainingAttempts(response);

    throw AuthException(
      message: data['message']?.toString() ?? 'Registration failed.',
      remaining: remaining,
    );
  }

  static Future<Map<String, dynamic>> migrateGuestData({
    required Map<String, dynamic> data,
  }) async {
    final storedToken = await getToken();

    if (storedToken == null || storedToken.isEmpty) {
      throw AuthException(message: 'Authentication token is missing.');
    }

    final response = await _request(
      method: 'POST',
      endpoint: '/guest/migrate',
      body: jsonEncode({
        'expenses': data['expenses'] ?? [],
        'goals': data['goals'] ?? [],
        'budgets': data['budgets'] ?? [],
        'settings': data['settings'] ?? [],
      }),
    );

    final body = _decodeResponseBody(response);

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
    final response = await _request(
      method: 'POST',
      endpoint: '/expenses',
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate,
        'description': description,
      }),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message']?.toString() ?? 'Failed to add expense.');
  }

  static Future<Map<String, dynamic>> getExpenses() async {
    final response = await _request(method: 'GET', endpoint: '/expenses');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load expenses (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> updateExpense(
    int id,
    String title,
    String amount,
    String category,
    String expenseDate,
    String description,
  ) async {
    final response = await _request(
      method: 'PUT',
      endpoint: '/expenses/$id',
      body: jsonEncode({
        'title': title,
        'amount': amount,
        'category': category,
        'expense_date': expenseDate,
        'description': description,
      }),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message']?.toString() ?? 'Failed to update expense.');
  }

  static Future<void> deleteExpense(int id) async {
    final response = await _request(
      method: 'DELETE',
      endpoint: '/expenses/$id',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(
      body['message']?.toString() ??
          'Failed to delete expense (${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> updateProfile(
    String name,
    String email,
  ) async {
    final response = await _request(
      method: 'PUT',
      endpoint: '/profile',
      body: jsonEncode({'name': name, 'email': email}),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message']?.toString() ?? 'Failed to update profile.');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await _request(method: 'GET', endpoint: '/profile');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;
      }
    }

    throw Exception('Failed to load profile (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getDashboardSummary() async {
    final response = await _request(
      method: 'GET',
      endpoint: '/dashboard-summary',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to load dashboard summary (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await _request(method: 'GET', endpoint: '/dashboard');

    if (response.statusCode != 200) {
      throw Exception('Failed to load dashboard (${response.statusCode})');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> updatePreferences(Map<String, dynamic> data) async {
    final response = await _request(
      method: 'PUT',
      endpoint: '/preferences',
      body: jsonEncode(data),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(
      body['message']?.toString() ?? 'Failed to update preferences.',
    );
  }

  static Future<Map<String, dynamic>> getPreferences() async {
    final response = await _request(method: 'GET', endpoint: '/preferences');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load preferences (${response.statusCode})');
  }

  static Future<UserPreferences> getUserPreferences() async {
    final data = await getPreferences();

    return UserPreferences.fromJson(data);
  }

  static Future<Map<String, dynamic>> getBudgetSummary() async {
    final response = await _request(method: 'GET', endpoint: '/budget-summary');

    final body = _decodeResponseBody(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(
      body['message']?.toString() ??
          'Failed to load budget summary (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> setBudget(
    double amount,
    String clientId,
  ) async {
    final response = await _request(
      method: 'POST',
      endpoint: '/budget',
      body: jsonEncode({'amount': amount, 'client_id': clientId}),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return body;
    }

    throw Exception(body['message']?.toString() ?? 'Failed to set budget.');
  }

  static Future<void> deleteBudget() async {
    final response = await _request(method: 'DELETE', endpoint: '/budget');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(
      body['message']?.toString() ??
          'Failed to delete budget (${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> getFinancialInsights() async {
    final response = await _request(
      method: 'GET',
      endpoint: '/financial-insights',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to load financial insights (${response.statusCode})',
    );
  }

  static Future<Map<String, dynamic>> getGoalInsights(int goalId) async {
    final response = await _request(
      method: 'GET',
      endpoint: '/goals/$goalId/insights',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Insights ${response.statusCode}: ${response.body}');
  }

  static Future<List<dynamic>> getGoals() async {
    final response = await _request(method: 'GET', endpoint: '/goals');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is List<dynamic>) {
        return data;
      }

      throw Exception('Invalid goals response from server.');
    }

    final body = _decodeResponseBody(response);

    throw Exception(
      body['message']?.toString() ??
          'Failed to load goals (${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> createGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final response = await _request(
      method: 'POST',
      endpoint: '/goals',
      body: jsonEncode({
        'title': title,
        'target_amount': targetAmount,
        'target_date': targetDate,
      }),
    );

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
    final response = await _request(
      method: 'PUT',
      endpoint: '/goals/$goalId/progress',
      body: jsonEncode({'amount': amount}),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(
      body['message']?.toString() ?? 'Failed to update goal progress.',
    );
  }

  static Future<List<dynamic>> getUpcomingGoalDeadlines() async {
    final response = await _request(
      method: 'GET',
      endpoint: '/goals/upcoming-deadlines',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body);

      if (data is List<dynamic>) {
        return data;
      }

      throw Exception('Invalid upcoming goal deadlines response.');
    }

    throw Exception(
      'Failed to load upcoming goal deadlines '
      '(${response.statusCode}).',
    );
  }

  static Future<Map<String, dynamic>> getGoalAnalytics() async {
    final response = await _request(
      method: 'GET',
      endpoint: '/goals/analytics',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load goal analytics (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getGoalForecast(int goalId) async {
    final response = await _request(
      method: 'GET',
      endpoint: '/goals/$goalId/forecast',
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Forecast ${response.statusCode}: ${response.body}');
  }

  static Future<void> archiveGoal(int goalId) async {
    final response = await _request(
      method: 'PUT',
      endpoint: '/goals/$goalId/archive',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(body['message']?.toString() ?? 'Failed to archive goal.');
  }

  static Future<List<dynamic>> getArchivedGoals() async {
    final response = await _request(method: 'GET', endpoint: '/goals/archived');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List<dynamic>) {
        return data;
      }

      throw Exception('Invalid archived goals response.');
    }

    throw Exception(
      'Failed to load archived goals '
      '(${response.statusCode}).',
    );
  }

  static Future<void> restoreGoal(int goalId) async {
    final response = await _request(
      method: 'PUT',
      endpoint: '/goals/$goalId/restore',
    );

    if (response.statusCode == 200) {
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(body['message']?.toString() ?? 'Failed to restore goal.');
  }

  static Future<void> deleteGoal(int goalId) async {
    final response = await _request(
      method: 'DELETE',
      endpoint: '/goals/$goalId',
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = _decodeResponseBody(response);

    throw Exception(body['message']?.toString() ?? 'Failed to delete goal.');
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _request(
      method: 'PUT',
      endpoint: '/change-password',
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      }),
    );

    final body = _decodeResponseBody(response);
    final remaining = _getRemainingAttempts(response);

    if (response.statusCode == 200) {
      return;
    }

    if (response.statusCode == 422 && body['errors'] != null) {
      throw AuthException(
        message: jsonEncode(body['errors']),
        remaining: remaining,
      );
    }

    throw AuthException(
      message: body['message']?.toString() ?? 'Failed to change password.',
      remaining: remaining,
    );
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await _request(
      method: 'POST',
      endpoint: '/forgot-password',
      authenticated: false,
      body: jsonEncode({'email': email}),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(
      body['message']?.toString() ?? 'Failed to send password reset OTP.',
    );
  }

  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    final response = await _request(
      method: 'POST',
      endpoint: '/verify-otp',
      authenticated: false,
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    final data = _decodeResponseBody(response);

    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['message']?.toString() ?? 'OTP verification failed.');
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _request(
      method: 'POST',
      endpoint: '/reset-password',
      authenticated: false,
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': confirmPassword,
      }),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body['message']?.toString() ?? 'Password reset failed.');
  }
}
