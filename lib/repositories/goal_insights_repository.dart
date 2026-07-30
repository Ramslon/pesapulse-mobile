import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

class GoalInsightsRepository extends BaseRepository {
  Future<Map<String, dynamic>> getInsights(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final localInsights = await _calculateInsights(database, goalId, ownerId);

      await database.insert(
        "goal_insights_cache",
        _toLocal(goalId, localInsights, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return localInsights;
    } catch (_) {
      final cached = await database.query(
        "goal_insights_cache",
        where: "goal_id=? AND owner_id=?",
        whereArgs: [goalId, ownerId],
      );

      if (cached.isNotEmpty) {
        return jsonDecode(cached.first["data"] as String);
      }

      return await _calculateInsights(database, goalId, ownerId);
    }
  }

  Future<Map<String, dynamic>> _calculateInsights(
    Database database,
    int goalId,
    String ownerId,
  ) async {
    final rows = await database.query(
      "goals",
      where: "owner_id=? AND (server_id=? OR id=?)",
      whereArgs: [ownerId, goalId, goalId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception("Goal not found");
    }

    final goal = rows.first;

    final target = (goal["target_amount"] as num?)?.toDouble() ?? 0;

    final saved = (goal["saved_amount"] as num?)?.toDouble() ?? 0;

    final remaining = (target - saved).clamp(0, double.infinity);

    int daysRemaining = 0;

    if (goal["target_date"] != null) {
      final targetDate = DateTime.parse(goal["target_date"] as String);

      daysRemaining = targetDate.difference(DateTime.now()).inDays;
    }

    double monthlyNeeded = 0;

    if (daysRemaining > 0) {
      monthlyNeeded = remaining / (daysRemaining / 30);
    }

    String status;

    if (saved >= target) {
      status = "completed";
    } else if (daysRemaining <= 7) {
      status = "urgent";
    } else {
      status = "on_track";
    }

    return {
      "goal": goal["title"],
      "remaining_amount": remaining,
      "days_remaining": daysRemaining,
      "monthly_needed": monthlyNeeded,
      "status": status,
      "message": _insightMessage(status, monthlyNeeded),
    };
  }

  String _insightMessage(String status, double monthlyNeeded) {
    switch (status) {
      case "completed":
        return "Congratulations! Goal completed.";

      case "urgent":
        return "Increase savings to reach your goal before the deadline.";

      default:
        return monthlyNeeded > 0
            ? "Save ${monthlyNeeded.toStringAsFixed(0)} per month to stay on track."
            : "You're on track toward your goal.";
    }
  }

  Map<String, dynamic> _toLocal(
    int goalId,
    Map<String, dynamic> insights,
    String ownerId,
  ) {
    return {
      "owner_id": ownerId,
      "goal_id": goalId,
      "data": jsonEncode(insights),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
