import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class GoalInsightsRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getInsights(int goalId) async {
    final database = await db.database;

    try {
      final insights = await ApiService.getGoalInsights(goalId);

      await database.insert(
        "goal_insights_cache",
        _toLocal(goalId, insights),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return insights;
    } catch (e) {
      final cached = await database.query(
        "goal_insights_cache",
        where: "goal_id=?",
        whereArgs: [goalId],
      );

      if (cached.isEmpty) {
        throw Exception("No cached insights available");
      }

      return _fromLocal(cached.first);
    }
  }

  Map<String, dynamic> _toLocal(int goalId, Map<String, dynamic> insights) {
    return {
      "goal_id": goalId,
      "data": jsonEncode(insights),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> cache) {
    return Map<String, dynamic>.from(jsonDecode(cache["data"] as String));
  }
}
