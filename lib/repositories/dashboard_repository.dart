import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';
import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';

class DashboardRepository extends BaseRepository {
  Map<String, dynamic> _dashboardToLocal(
    Map<String, dynamic> dashboard,
    String ownerId,
  ) {
    final summary = dashboard["summary"];

    return {
      "owner_id": ownerId,
      "total_expenses": summary["total_expenses"],
      "total_count": summary["total_count"],
      "total_categories": summary["categories"],
      "recent_expenses": jsonEncode(dashboard["recent_expenses"]),
      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _localToDashboard(Map<String, dynamic> row) {
    return {
      "summary": {
        "total_expenses": row["total_expenses"],
        "total_count": row["total_count"],
        "categories": row["total_categories"],
      },
      "recent_expenses": jsonDecode(row["recent_expenses"]),
    };
  }

  Future<Map<String, dynamic>> getCachedDashboard() async {
    final database = await db.database;
    final ownerId = await this.ownerId;

    final cached = await database.query(
      "dashboard_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
      limit: 1,
    );

    if (cached.isEmpty) {
      throw Exception("No cached dashboard");
    }

    return _localToDashboard(cached.first);
  }

  Future<Map<String, dynamic>> refreshDashboard() async {
    final database = await db.database;
    final ownerId = await this.ownerId;

    // ------------------------------------------------------------
    // GUEST MODE
    // Never call the authenticated dashboard API.
    // ------------------------------------------------------------
    if (ownerId == 'guest') {
      debugPrint('Dashboard API refresh skipped: guest user.');

      return getCachedDashboard();
    }

    try {
      final dashboard = await ApiService.getDashboard();

      await database.insert(
        "dashboard_cache",
        _dashboardToLocal(dashboard, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return dashboard;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Dashboard API request failed: $e');
      rethrow;
    }
  }
}
