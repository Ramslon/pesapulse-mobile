import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class AnalyticsRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getAnalytics() async {
    final database = await db.database;

    try {
      final expenses = await ApiService.getExpenses();

      final goalAnalytics = await ApiService.getGoalAnalytics();

      final financialInsights = await ApiService.getFinancialInsights();

      await database.insert(
        "analytics_cache",
        _toLocal(expenses, goalAnalytics, financialInsights),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {
        "expenses": expenses,
        "goalAnalytics": goalAnalytics,
        "financialInsights": financialInsights,
      };
    } catch (_) {
      final cached = await database.query("analytics_cache", where: "id=1");

      if (cached.isEmpty) {
        throw Exception("No cached analytics");
      }

      return _fromLocal(cached.first);
    }
  }

  Map<String, dynamic> _toLocal(
    Map<String, dynamic> expenses,
    Map<String, dynamic> goals,
    Map<String, dynamic> insights,
  ) {
    return {
      "id": 1,
      "expenses": jsonEncode(expenses),
      "goal_analytics": jsonEncode(goals),
      "financial_insights": jsonEncode(insights),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> cache) {
    return {
      "expenses": jsonDecode(cache["expenses"] as String),
      "goalAnalytics": jsonDecode(cache["goal_analytics"] as String),
      "financialInsights": jsonDecode(cache["financial_insights"] as String),
    };
  }
}
