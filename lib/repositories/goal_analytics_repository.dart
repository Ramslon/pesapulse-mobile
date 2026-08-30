import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';
import '../exceptions/rate_limit_exception.dart';

class GoalAnalyticsRepository extends BaseRepository {
  Future<Map<String, dynamic>> getGoalAnalytics() async {
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
    } catch (_) {
      final cached = await database.query(
        "goal_analytics_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isNotEmpty) {
        return jsonDecode(cached.first["data"] as String);
      }
      return await _calculateLocalAnalytics(database);
    }
  }

  Future<Map<String, dynamic>> _calculateLocalAnalytics(
    Database database,
  ) async {
    final goals = await database.query(
      "goals",
      where: "owner_id=? AND is_deleted=?",
      whereArgs: [ownerId, 0],
    );

    final totalGoals = goals.length;

    final completedGoals = goals.where((g) {
      final saved = (g["saved_amount"] as num?)?.toDouble() ?? 0;
      final target = (g["target_amount"] as num?)?.toDouble() ?? 0;

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
