import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';

class GoalDeadlineRepository extends BaseRepository {
  Future<List<dynamic>> getUpcomingDeadlines() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final deadlines = await ApiService.getUpcomingGoalDeadlines();

      await database.insert(
        "goal_deadlines_cache",
        _toLocal(deadlines, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return deadlines;
    } catch (_) {
      final cached = await database.query(
        "goal_deadlines_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isNotEmpty) {
        return jsonDecode(cached.first["data"] as String);
      }

      return await _calculateUpcomingDeadlines(database, ownerId);
    }
  }

  Future<List<Map<String, dynamic>>> _calculateUpcomingDeadlines(
    Database database,
    String ownerId,
  ) async {
    final rows = await database.query(
      "goals",
      where: """
      owner_id = ?
      is_deleted = 0
      AND is_archived = 0
      AND target_date IS NOT NULL
    """,
      whereArgs: [ownerId],
    );

    final now = DateTime.now();

    final List<Map<String, dynamic>> deadlines = [];

    for (final goal in rows) {
      final targetDate = DateTime.parse(goal["target_date"] as String);

      final daysRemaining = targetDate.difference(now).inDays;

      deadlines.add({
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

  Map<String, dynamic> _toLocal(List<dynamic> deadlines, String ownerId) {
    return {
      "owner_id": ownerId,
      "data": jsonEncode(deadlines),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
