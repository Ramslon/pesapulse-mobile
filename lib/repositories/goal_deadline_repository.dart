import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';
import '../exceptions/rate_limit_exception.dart';

class GoalDeadlineRepository extends BaseRepository {
  // ============================================================
  // CACHE-FIRST
  // ============================================================

  /// Returns upcoming deadlines from the local SQLite cache.
  ///
  /// This method NEVER contacts the API.
  ///
  /// If no cached deadlines exist, they are calculated directly
  /// from the local goals table.
  Future<List<Map<String, dynamic>>> getCachedUpcomingDeadlines() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final cached = await database.query(
      "goal_deadlines_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
      limit: 1,
    );

    if (cached.isNotEmpty) {
      final data = cached.first["data"];

      if (data is String && data.isNotEmpty) {
        final decoded = jsonDecode(data);

        if (decoded is List) {
          return decoded
              .map<Map<String, dynamic>>(
                (item) => Map<String, dynamic>.from(item),
              )
              .toList();
        }
      }
    }

    // No persistent cache available.
    //
    // Calculate deadlines directly from local goals.
    return _calculateUpcomingDeadlines(database, ownerId);
  }

  // ============================================================
  // API REFRESH
  // ============================================================

  /// Fetches fresh upcoming deadlines from Laravel and stores
  /// the result in SQLite.
  ///
  /// This method is intended for background refreshes and
  /// explicit manual refreshes.
  ///
  /// RateLimitException is deliberately rethrown.
  Future<List<Map<String, dynamic>>> refreshUpcomingDeadlines() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final deadlines = await ApiService.getUpcomingGoalDeadlines();

      final normalized = deadlines
          .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
          .toList();

      await database.insert(
        "goal_deadlines_cache",
        _toLocal(normalized, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return normalized;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      // Do not fall back to cache here.
      //
      // Cache-first loading has already happened before the
      // background refresh. The caller can safely ignore a
      // failed refresh while continuing to display cached data.
      rethrow;
    }
  }

  // ============================================================
  // LOCAL CALCULATION
  // ============================================================

  Future<List<Map<String, dynamic>>> _calculateUpcomingDeadlines(
    Database database,
    String ownerId,
  ) async {
    final rows = await database.query(
      "goals",
      where: """
        owner_id = ?
        AND is_deleted = 0
        AND is_archived = 0
        AND target_date IS NOT NULL
      """,
      whereArgs: [ownerId],
    );

    final now = DateTime.now();

    // Normalize to calendar date so that a goal due today
    // is correctly treated as due today rather than yesterday
    // because of the current time of day.
    final today = DateTime(now.year, now.month, now.day);

    final List<Map<String, dynamic>> deadlines = [];

    for (final goal in rows) {
      final targetDateString = goal["target_date"]?.toString();

      if (targetDateString == null || targetDateString.isEmpty) {
        continue;
      }

      final DateTime targetDate;

      try {
        targetDate = DateTime.parse(targetDateString);
      } catch (_) {
        // Ignore malformed local dates instead of allowing one
        // bad record to break the entire deadlines calculation.
        continue;
      }

      final targetDay = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      final daysRemaining = targetDay.difference(today).inDays;

      if (daysRemaining >= 0 && daysRemaining <= 3) {
        deadlines.add({
          // Server ID is preferred for API-related operations.
          // Offline-created goals fall back to their local ID.
          "goal_id": goal["server_id"] ?? goal["id"],
          "title": goal["title"],
          "target_date": goal["target_date"],
          "days_remaining": daysRemaining,
        });
      }
    }

    deadlines.sort(
      (a, b) =>
          (a["days_remaining"] as int).compareTo(b["days_remaining"] as int),
    );

    return deadlines;
  }

  // ============================================================
  // LOCAL SERIALIZATION
  // ============================================================

  Map<String, dynamic> _toLocal(
    List<Map<String, dynamic>> deadlines,
    String ownerId,
  ) {
    return {
      "owner_id": ownerId,
      "data": jsonEncode(deadlines),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }
}
