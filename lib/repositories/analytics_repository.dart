import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:pesapulse_mobile/repositories/expense_repository.dart';

import '../services/api_services.dart';
import '../services/startup_refresh_coordinator.dart';
import '../exceptions/rate_limit_exception.dart';

class AnalyticsRepository extends BaseRepository {
  final ExpenseRepository expenseRepository = ExpenseRepository();

  // ============================================================
  // CACHE
  // ============================================================

  Future<Map<String, dynamic>> getCachedAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final cached = await database.query(
      "analytics_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
      limit: 1,
    );

    if (cached.isEmpty) {
      throw Exception("No cached analytics");
    }

    final analytics = _fromLocal(cached.first);

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // Goal statistics must always reflect the current local
    // SQLite goals table because goal mutations can occur after
    // analytics_cache was last generated.
    // ----------------------------------------------------------

    final localGoalAnalytics = await _getLocalGoalAnalytics();

    analytics["goalAnalytics"] = localGoalAnalytics;

    return analytics;
  }

  // ============================================================
  // NETWORK REFRESH
  // ============================================================

  Future<Map<String, dynamic>> refreshAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      debugPrint('Analytics refresh: requesting expenses...');

      final expenses = await expenseRepository.refreshExpenses();

      debugPrint('Analytics refresh: expenses completed.');

      debugPrint('Analytics refresh: requesting financial insights...');

      final financialInsights = await StartupRefreshCoordinator.instance.run(
        'financial-insights',
        () async {
          return await ApiService.getFinancialInsights();
        },
      );

      debugPrint('Analytics refresh: financial insights completed.');

      // --------------------------------------------------------
      // Goal analytics are derived from the current local goal
      // database so newly completed/archived/removed goals are
      // reflected immediately.
      // --------------------------------------------------------

      final goalAnalytics = await _getLocalGoalAnalytics();

      await database.insert(
        "analytics_cache",
        _toLocal(expenses, goalAnalytics, financialInsights, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Analytics refresh: cache updated successfully.');

      return {
        "expenses": expenses,
        "goalAnalytics": goalAnalytics,
        "financialInsights": financialInsights,
      };
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Analytics API refresh failed: $e');
      rethrow;
    }
  }

  // ============================================================
  // CACHED GOAL ANALYTICS
  // ============================================================

  Future<Map<String, dynamic>> getCachedGoalAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final cached = await database.query(
      "goal_analytics_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
      limit: 1,
    );

    if (cached.isEmpty) {
      throw Exception("No cached goal analytics");
    }

    final data = cached.first["data"];

    if (data is! String) {
      throw Exception("Invalid cached goal analytics");
    }

    final decoded = jsonDecode(data);

    if (decoded is! Map) {
      throw Exception("Invalid cached goal analytics format");
    }

    return Map<String, dynamic>.from(decoded);
  }

  // ============================================================
  // LOCAL GOAL ANALYTICS
  // ============================================================

  /// Builds goal statistics directly from SQLite.
  ///
  /// This is intentionally local-only so goal mutations are
  /// reflected immediately without requiring another API request.
  Future<Map<String, dynamic>> _getLocalGoalAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final totalResult = await database.rawQuery(
      """
      SELECT COUNT(*)
      FROM goals
      WHERE owner_id = ?
        AND is_archived = 0
        AND is_deleted = 0
      """,
      [ownerId],
    );

    final completedResult = await database.rawQuery(
      """
      SELECT COUNT(*)
      FROM goals
      WHERE owner_id = ?
        AND is_archived = 0
        AND is_deleted = 0
        AND completed_at IS NOT NULL
      """,
      [ownerId],
    );

    final totalGoals = Sqflite.firstIntValue(totalResult) ?? 0;

    final completedGoals = Sqflite.firstIntValue(completedResult) ?? 0;

    final activeGoals = totalGoals - completedGoals;

    final completionRate = totalGoals == 0
        ? 0.0
        : (completedGoals / totalGoals) * 100.0;

    return {
      "total_goals": totalGoals,
      "completed_goals": completedGoals,
      "active_goals": activeGoals,
      "completion_rate": completionRate,
    };
  }

  // ============================================================
  // CACHE SERIALIZATION
  // ============================================================

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
