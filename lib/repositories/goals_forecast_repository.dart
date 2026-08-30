import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../exceptions/rate_limit_exception.dart';

import '../services/api_services.dart';

class GoalForecastRepository extends BaseRepository {
  Future<Map<String, dynamic>> getForecast(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final forecast = await ApiService.getGoalForecast(goalId);

      await database.insert(
        "goal_forecasts_cache",
        _toLocal(goalId, forecast, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return forecast;
    } on RateLimitException {
      // Do NOT fall back to cached/local data when the server
      // explicitly says the request has been rate limited.
      rethrow;
    } catch (_) {
      final cached = await database.query(
        "goal_forecasts_cache",
        where: "goal_id=? AND owner_id=?",
        whereArgs: [goalId, ownerId],
      );

      if (cached.isNotEmpty) {
        return jsonDecode(cached.first["data"] as String);
      }

      final localForecast = await _calculateForecast(database, goalId, ownerId);

      await database.insert(
        "goal_forecasts_cache",
        _toLocal(goalId, localForecast, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return localForecast;
    }
  }

  Future<Map<String, dynamic>> _calculateForecast(
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

    final remainingAmount = (target - saved).clamp(0, double.infinity);

    final today = DateTime.now();

    if (goal["target_date"] == null) {
      return {
        "goal": goal["title"],
        "forecast": "no_deadline",
        "message": "No deadline has been set for this goal.",
        "actual_progress": saved,
        "remaining_amount": remainingAmount,
      };
    }

    final targetDate = DateTime.parse(goal["target_date"] as String);

    final created = goal["created_at"] != null
        ? DateTime.parse(goal["created_at"] as String)
        : today;

    final remainingDays = targetDate.difference(today).inDays;

    final safeRemainingDays = remainingDays < 0 ? 0 : remainingDays;

    double expectedProgress = 0;

    final totalDays = targetDate.difference(created).inDays;

    if (totalDays > 0) {
      final elapsed = today.difference(created).inDays.clamp(0, totalDays);

      expectedProgress = target * (elapsed / totalDays);
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
      "recommended_daily_saving": safeRemainingDays > 0
          ? remainingAmount / safeRemainingDays
          : 0,
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

  Map<String, dynamic> _toLocal(
    int goalId,
    Map<String, dynamic> forecast,
    String ownerId,
  ) {
    return {
      "owner_id": ownerId,
      "goal_id": goalId,
      "data": jsonEncode(forecast),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
