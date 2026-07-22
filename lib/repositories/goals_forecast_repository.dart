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
    } catch (_) {
      return await _calculateForecast(database, goalId);
    }
  }

  Future<Map<String, dynamic>> _calculateForecast(
    Database database,
    int goalId,
  ) async {
    final rows = await database.query(
      "goals",
      where: "id=?",
      whereArgs: [goalId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception("Goal not found");
    }

    final goal = rows.first;

    final target = (goal["target_amount"] as num?)?.toDouble() ?? 0;

    final saved = (goal["saved_amount"] as num?)?.toDouble() ?? 0;

    final remainingAmount = (target - saved).clamp(0, double.infinity);

    final today = DateTime.now();

    final targetDate = goal["target_date"] != null
        ? DateTime.parse(goal["target_date"] as String)
        : today;

    final remainingDays = targetDate.difference(today).inDays;

    double expectedProgress = 0;

    if (goal["target_date"] != null) {
      final created = goal["updated_at"] != null
          ? DateTime.parse(goal["updated_at"] as String)
          : today;

      final totalDays = targetDate.difference(created).inDays;

      if (totalDays > 0) {
        final elapsed = today.difference(created).inDays.clamp(0, totalDays);

        expectedProgress = target * (elapsed / totalDays);
      }
    }

    String forecast = "on_track";

    if (saved >= target) {
      forecast = "completed";
    } else if (saved >= expectedProgress) {
      forecast = "ahead";
    } else {
      forecast = "behind";
    }

    final daily = remainingDays > 0 ? remainingAmount / remainingDays : 0;

    final monthly = daily * 30;

    return {
      "goal": goal["title"],
      "forecast": forecast,
      "message": _forecastMessage(forecast),
      "actual_progress": saved,
      "expected_progress": expectedProgress,
      "remaining_amount": remainingAmount,
      "remaining_days": remainingDays,
      "estimated_completion_date": targetDate
          .toIso8601String()
          .split("T")
          .first,
      "recommended_daily_saving": daily,
      "recommended_monthly_saving": monthly,
    };
  }

  String _forecastMessage(String forecast) {
    switch (forecast) {
      case "ahead":
        return "Great job! You are ahead of schedule.";

      case "behind":
        return "You need to increase your savings to reach this goal.";

      case "completed":
        return "Congratulations! Goal completed.";

      default:
        return "Your savings are on track.";
    }
  }

  Map<String, dynamic> _toLocal(int goalId, Map<String, dynamic> forecast) {
    return {
      "goal_id": goalId,
      "data": jsonEncode(forecast),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
