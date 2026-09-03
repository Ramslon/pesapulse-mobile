import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../exceptions/rate_limit_exception.dart';
import '../services/api_services.dart';

class GoalForecastRepository extends BaseRepository {
  // ============================================================
  // CACHE-FIRST
  // ============================================================

  /// Loads a forecast from SQLite.
  ///
  /// This method never contacts the API.
  ///
  /// If no cached forecast exists, the forecast is calculated
  /// directly from the local goals table.
  Future<Map<String, dynamic>> getCachedForecast(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final cached = await database.query(
      "goal_forecasts_cache",
      where: "goal_id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
      limit: 1,
    );

    if (cached.isNotEmpty) {
      final data = cached.first["data"];

      if (data is String && data.isNotEmpty) {
        final decoded = jsonDecode(data);

        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    }

    // No cached forecast.
    //
    // Calculate one locally using the current SQLite goal data.
    final localForecast = await _calculateForecast(database, goalId, ownerId);

    // Cache the locally calculated forecast so subsequent reads
    // do not need to calculate it again.
    await database.insert(
      "goal_forecasts_cache",
      _toLocal(goalId, localForecast, ownerId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return localForecast;
  }

  // ============================================================
  // API REFRESH
  // ============================================================

  /// Fetches the latest forecast from Laravel and stores it
  /// in the local SQLite cache.
  ///
  /// This method is used for background refreshes and explicit
  /// manual refreshes.
  Future<Map<String, dynamic>> refreshForecast(int goalId) async {
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
      // Never swallow rate-limit responses.
      rethrow;
    } catch (e) {
      debugPrint('Goal forecast API refresh failed for goal $goalId: $e');

      // Do not fall back to cache here.
      //
      // The cache should already have been loaded before the
      // background refresh starts.
      rethrow;
    }
  }

  // ============================================================
  // LOCAL FORECAST CALCULATION
  // ============================================================

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

    final now = DateTime.now();

    // ----------------------------------------------------------
    // No deadline
    // ----------------------------------------------------------

    if (goal["target_date"] == null || goal["target_date"].toString().isEmpty) {
      return {
        "goal": goal["title"],
        "forecast": "no_deadline",
        "message": "No deadline has been set for this goal.",
        "actual_progress": saved,
        "remaining_amount": remainingAmount,
      };
    }

    // ----------------------------------------------------------
    // Parse dates safely
    // ----------------------------------------------------------

    final DateTime targetDate;

    try {
      targetDate = DateTime.parse(goal["target_date"].toString());
    } catch (_) {
      return {
        "goal": goal["title"],
        "forecast": "no_deadline",
        "message": "The goal deadline could not be determined.",
        "actual_progress": saved,
        "remaining_amount": remainingAmount,
      };
    }

    final created = goal["created_at"] != null
        ? _parseDate(goal["created_at"].toString(), fallback: now)
        : now;

    // Normalize the current date for calendar-day calculations.
    final today = DateTime(now.year, now.month, now.day);

    final targetDay = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );

    // ----------------------------------------------------------
    // Remaining days
    // ----------------------------------------------------------

    final remainingDays = targetDay.difference(today).inDays;

    final safeRemainingDays = remainingDays < 0 ? 0 : remainingDays;

    // ----------------------------------------------------------
    // Expected progress
    // ----------------------------------------------------------

    double expectedProgress = 0;

    final totalDays = targetDay
        .difference(DateTime(created.year, created.month, created.day))
        .inDays;

    if (totalDays > 0) {
      final elapsed = today
          .difference(DateTime(created.year, created.month, created.day))
          .inDays
          .clamp(0, totalDays);

      expectedProgress = target * (elapsed / totalDays);
    }

    // ----------------------------------------------------------
    // Determine forecast
    // ----------------------------------------------------------

    String forecast;

    if (target > 0 && saved >= target) {
      forecast = "completed";
    } else if (saved >= expectedProgress) {
      forecast = "ahead";
    } else {
      forecast = "behind";
    }

    // ----------------------------------------------------------
    // Recommended savings
    // ----------------------------------------------------------

    final daily = safeRemainingDays > 0
        ? remainingAmount / safeRemainingDays
        : 0.0;

    final monthly = daily * 30;

    return {
      "goal": goal["title"],
      "forecast": forecast,
      "message": _forecastMessage(forecast),
      "actual_progress": saved,
      "expected_progress": expectedProgress,
      "remaining_amount": remainingAmount,
      "remaining_days": remainingDays,
      "estimated_completion_date": targetDay.toIso8601String().split("T").first,
      "recommended_daily_saving": safeRemainingDays > 0
          ? remainingAmount / safeRemainingDays
          : 0,
      "recommended_monthly_saving": monthly,
    };
  }

  // ============================================================
  // FORECAST MESSAGE
  // ============================================================

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

  // ============================================================
  // DATE PARSING
  // ============================================================

  DateTime _parseDate(String value, {required DateTime fallback}) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return fallback;
    }
  }

  // ============================================================
  // SQLITE SERIALIZATION
  // ============================================================

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
