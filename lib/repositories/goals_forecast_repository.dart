import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class GoalForecastRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getForecast(int goalId) async {
    final database = await db.database;

    try {
      final forecast = await ApiService.getGoalForecast(goalId);

      await database.insert(
        "goal_forecasts_cache",
        _toLocal(goalId, forecast),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return forecast;
    } catch (e) {
      final cached = await database.query(
        "goal_forecasts_cache",
        where: "goal_id=?",
        whereArgs: [goalId],
      );

      if (cached.isEmpty) {
        throw Exception("No cached forecast available");
      }

      return _fromLocal(cached.first);
    }
  }

  Map<String, dynamic> _toLocal(int goalId, Map<String, dynamic> forecast) {
    return {
      "goal_id": goalId,
      "data": jsonEncode(forecast),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> cache) {
    return Map<String, dynamic>.from(jsonDecode(cache["data"] as String));
  }
}
