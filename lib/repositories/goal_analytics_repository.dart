import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';
import '../exceptions/rate_limit_exception.dart';

class GoalAnalyticsRepository extends BaseRepository {
  // ============================================================
  // CACHE-FIRST
  // ============================================================

  /// Returns cached goal analytics from SQLite.
  ///
  /// This method NEVER contacts the API.
  ///
  /// If no cached analytics exist, the values are calculated
  /// directly from the local goals table.
  Future<Map<String, dynamic>> getCachedGoalAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final cached = await database.query(
      "goal_analytics_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
      limit: 1,
    );

    if (cached.isNotEmpty) {
      final data = cached.first["data"];

      if (data is String && data.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(data) as Map);
      }
    }

    // No cached analytics available.
    // Calculate them from the local goals database.
    return _calculateLocalAnalytics(database, ownerId);
  }

  // ============================================================
  // API REFRESH
  // ============================================================

  /// Fetches fresh goal analytics from Laravel and stores
  /// the result in SQLite.
  ///
  /// This method is intended for background refreshes and
  /// explicit manual refreshes.
  ///
  /// RateLimitException is deliberately rethrown so the caller
  /// can handle HTTP 429 responses properly.
  Future<Map<String, dynamic>> refreshGoalAnalytics() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final analytics = await ApiService.getGoalAnalytics();

      await database.insert(
        "goal_analytics_cache",
        _toLocal(analytics, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return analytics;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      // Do not silently replace a failed refresh with cached
      // data here. The caller already has cache-first behavior.
      //
      // Keeping this exception visible allows the controller
      // to know that the background refresh failed.
      rethrow;
    }
  }

  // ============================================================
  // LOCAL ANALYTICS
  // ============================================================

  Future<Map<String, dynamic>> _calculateLocalAnalytics(
    Database database,
    String ownerId,
  ) async {
    final goals = await database.query(
      "goals",
      where: """
        owner_id=?
        AND is_deleted=?
        AND is_archived=?
      """,
      whereArgs: [ownerId, 0, 0],
    );

    final totalGoals = goals.length;

    final completedGoals = goals.where((goal) {
      final saved = (goal["saved_amount"] as num?)?.toDouble() ?? 0.0;

      final target = (goal["target_amount"] as num?)?.toDouble() ?? 0.0;

      return target > 0 && saved >= target;
    }).length;

    final activeGoals = totalGoals - completedGoals;

    final completionRate = totalGoals == 0
        ? 0
        : ((completedGoals / totalGoals) * 100).round();

    return {
      "total_goals": totalGoals,
      "completed_goals": completedGoals,
      "active_goals": activeGoals,
      "completion_rate": completionRate,
    };
  }

  // ============================================================
  // LOCAL CACHE SERIALIZATION
  // ============================================================

  Map<String, dynamic> _toLocal(
    Map<String, dynamic> analytics,
    String ownerId,
  ) {
    return {
      "owner_id": ownerId,
      "data": jsonEncode(analytics),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
