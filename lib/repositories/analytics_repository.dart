import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';
import '../exceptions/rate_limit_exception.dart';

class AnalyticsRepository extends BaseRepository {
  Future<Map<String, dynamic>> getAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final results = await Future.wait([
        ApiService.getExpenses(),
        ApiService.getGoalAnalytics(),
        ApiService.getFinancialInsights(),
      ]);

      final expenses = results[0] as Map<String, dynamic>;
      final goalAnalytics = results[1] as Map<String, dynamic>;
      final financialInsights = results[2] as Map<String, dynamic>;

      await database.insert(
        "analytics_cache",
        _toLocal(expenses, goalAnalytics, financialInsights, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {
        "expenses": expenses,
        "goalAnalytics": goalAnalytics,
        "financialInsights": financialInsights,
      };
    } on RateLimitException {
      rethrow;
    } catch (_) {
      final cached = await database.query(
        "analytics_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

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
    String ownerId,
  ) {
    return {
      "owner_id": ownerId,
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
