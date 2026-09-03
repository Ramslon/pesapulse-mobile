import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../exceptions/rate_limit_exception.dart';
import '../services/api_services.dart';

class GoalInsightsRepository extends BaseRepository {
  // ============================================================
  // CACHE-FIRST
  // ============================================================

  /// Loads goal insights from the local SQLite cache.
  ///
  /// This method never contacts the API.
  ///
  /// If no cached insights exist, the insights are calculated
  /// directly from the local goals table.
  Future<Map<String, dynamic>> getCachedInsights(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final cached = await database.query(
      "goal_insights_cache",
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

    // No cached insights available.
    //
    // Calculate them locally from the current SQLite goal.
    final localInsights = await _calculateInsights(database, goalId, ownerId);

    // Store the locally calculated result so subsequent reads
    // can use the cache.
    await database.insert(
      "goal_insights_cache",
      _toLocal(goalId, localInsights, ownerId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return localInsights;
  }

  // ============================================================
  // API REFRESH
  // ============================================================

  /// Fetches fresh goal insights from Laravel and stores the
  /// result in the local SQLite cache.
  ///
  /// Used by background refreshes and explicit manual refreshes.
  Future<Map<String, dynamic>> refreshInsights(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final insights = await ApiService.getGoalInsights(goalId);

      await database.insert(
        "goal_insights_cache",
        _toLocal(goalId, insights, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return insights;
    } on RateLimitException {
      // Never hide a 429 response.
      rethrow;
    } catch (e) {
      debugPrint('Goal insights API refresh failed for goal $goalId: $e');

      // Do not fall back to cache here.
      //
      // The cache-first method is responsible for providing
      // data immediately before this background refresh runs.
      rethrow;
    }
  }

  // ============================================================
  // LOCAL INSIGHT CALCULATION
  // ============================================================

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

    final now = DateTime.now();

    int daysRemaining = 0;

    // ----------------------------------------------------------
    // Deadline
    // ----------------------------------------------------------

    if (goal["target_date"] != null &&
        goal["target_date"].toString().isNotEmpty) {
      try {
        final targetDate = DateTime.parse(goal["target_date"].toString());

        final today = DateTime(now.year, now.month, now.day);

        final targetDay = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        );

        daysRemaining = targetDay.difference(today).inDays;
      } catch (_) {
        daysRemaining = 0;
      }
    }

    // ----------------------------------------------------------
    // Monthly amount required
    // ----------------------------------------------------------

    double monthlyNeeded = 0;

    if (daysRemaining > 0) {
      monthlyNeeded = remaining / (daysRemaining / 30);
    }

    // ----------------------------------------------------------
    // Determine status
    // ----------------------------------------------------------

    String status;

    if (target > 0 && saved >= target) {
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

  // ============================================================
  // INSIGHT MESSAGE
  // ============================================================

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

  // ============================================================
  // SQLITE SERIALIZATION
  // ============================================================

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
