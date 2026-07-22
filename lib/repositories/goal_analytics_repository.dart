import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class GoalAnalyticsRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getGoalAnalytics() async {
    final database = await db.database;

    try {
      final analytics = await ApiService.getGoalAnalytics();

      await database.insert(
        "goal_analytics_cache",
        _toLocal(analytics),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return analytics;
    } catch (_) {
      return await _calculateLocalAnalytics(database);
    }
  }

  Future<Map<String, dynamic>> _calculateLocalAnalytics(
    Database database,
  ) async {
    final goals = await database.query(
      "goals",
      where: "is_deleted = ?",
      whereArgs: [0],
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

  Map<String, dynamic> _toLocal(Map<String, dynamic> analytics) {
    return {
      "id": 1,
      "data": jsonEncode(analytics),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
