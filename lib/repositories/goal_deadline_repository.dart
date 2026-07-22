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
      return await _calculateUpcomingDeadlines(database);
    }
  }

  Future<List<Map<String, dynamic>>> _calculateUpcomingDeadlines(
    Database database,
  ) async {
    final rows = await database.query(
      "goals",
      where: """
      is_deleted = 0
      AND is_archived = 0
      AND target_date IS NOT NULL
    """,
    );

    final now = DateTime.now();

    final List<Map<String, dynamic>> deadlines = [];

    for (final goal in rows) {
      final targetDate = DateTime.parse(goal["target_date"] as String);

      final daysRemaining = targetDate.difference(now).inDays;

      deadlines.add({
        "id": goal["id"],
        "title": goal["title"],
        "target_date": goal["target_date"],
        "days_remaining": daysRemaining,
      });
    }

    deadlines.sort(
      (a, b) =>
          (a["days_remaining"] as int).compareTo(b["days_remaining"] as int),
    );

    return deadlines;
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
