import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class GoalDeadlineRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<List<dynamic>> getUpcomingDeadlines() async {
    final database = await db.database;

    try {
      final deadlines = await ApiService.getUpcomingGoalDeadlines();

      await database.insert(
        "goal_deadlines_cache",
        _toLocal(deadlines),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return deadlines;
    } catch (_) {
      final cached = await database.query(
        "goal_deadlines_cache",
        where: "id=1",
      );

      if (cached.isEmpty) {
        return [];
      }

      return _fromLocal(cached.first);
    }
  }

  Map<String, dynamic> _toLocal(List<dynamic> deadlines) {
    return {
      "id": 1,
      "data": jsonEncode(deadlines),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  List<dynamic> _fromLocal(Map<String, dynamic> cache) {
    return jsonDecode(cache["data"] as String);
  }
}
