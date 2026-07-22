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
      final cached = await database.query(
        "goal_analytics_cache",
        where: "id=1",
      );

      if (cached.isEmpty) {
        throw Exception("No cached goal analytics");
      }

      return _fromLocal(cached.first);
    }
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> analytics) {
    return {
      "id": 1,
      "data": jsonEncode(analytics),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> cache) {
    return jsonDecode(cache["data"] as String);
  }
}
