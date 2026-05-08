import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.5.50.86:8000/api';

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

  static Future<List<dynamic>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/expenses'),

      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    return jsonDecode(response.body);
  }
}
