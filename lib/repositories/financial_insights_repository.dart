import 'dart:convert';

import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';
import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';
import '../services/session_service.dart';

class FinancialInsightsRepository extends BaseRepository {
  // ---------------------------------------------------------------------------
  // LOCAL SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toLocal({
    required Map<String, dynamic> insights,
    required String ownerId,
    required int month,
    required int year,
  }) {
    return {
      "owner_id": ownerId,

      "month": month,

      "year": year,

      "budget_status": insights["budget_status"],

      "payload": jsonEncode(insights),

      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> row) {
    final payload = row["payload"];

    if (payload is String && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);

        if (decoded is Map) {
          final result = Map<String, dynamic>.from(decoded);

          result["month"] ??= row["month"];
          result["year"] ??= row["year"];

          return result;
        }
      } catch (_) {
        // Fall through to empty insights.
      }
    }

    return _emptyInsights(
      month: row["month"] as int?,
      year: row["year"] as int?,
    );
  }

  // ---------------------------------------------------------------------------
  // CACHE
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _getCachedInsights(
    Database database,
    String ownerId,
    int month,
    int year,
  ) async {
    final cached = await database.query(
      "financial_insights_cache",
      where: '''
        owner_id = ?
        AND month = ?
        AND year = ?
      ''',
      whereArgs: [ownerId, month, year],
      limit: 1,
    );

    if (cached.isEmpty) {
      return null;
    }

    return _fromLocal(cached.first);
  }

  Future<void> _saveCachedInsights(
    Database database,
    Map<String, dynamic> insights,
    String ownerId,
    int month,
    int year,
  ) async {
    await database.insert(
      "financial_insights_cache",
      _toLocal(insights: insights, ownerId: ownerId, month: month, year: year),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------------------------------------------------------------------------
  // LOAD INSIGHTS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getInsights({
    bool useCache = false,
    int? month,
    int? year,
  }) async {
    final database = await db.database;

    final now = DateTime.now();

    final selectedMonth = month ?? now.month;

    final selectedYear = year ?? now.year;

    final ownerId = await this.ownerId;

    // -------------------------------------------------------------------------
    // CACHE ONLY
    // -------------------------------------------------------------------------

    if (useCache) {
      final cached = await _getCachedInsights(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      if (cached != null) {
        return cached;
      }

      return _emptyInsights(month: selectedMonth, year: selectedYear);
    }

    // -------------------------------------------------------------------------
    // GUEST USERS
    //
    // Guest users never call the backend.
    // -------------------------------------------------------------------------

    if (await SessionService.isGuest()) {
      final cached = await _getCachedInsights(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      if (cached != null) {
        return cached;
      }

      return _emptyInsights(month: selectedMonth, year: selectedYear);
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    // -------------------------------------------------------------------------

    try {
      final insights = await ApiService.getFinancialInsights(
        month: selectedMonth,
        year: selectedYear,
      );

      await _saveCachedInsights(
        database,
        insights,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      return {
        ...insights,
        "month": insights["month"] ?? selectedMonth,
        "year": insights["year"] ?? selectedYear,
      };
    } on RateLimitException {
      rethrow;
    } catch (_) {
      // -----------------------------------------------------------------------
      // Backend unavailable.
      //
      // Fall back to the selected period's cache.
      // -----------------------------------------------------------------------

      final cached = await _getCachedInsights(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      if (cached != null) {
        return cached;
      }

      return _emptyInsights(month: selectedMonth, year: selectedYear);
    }
  }

  // ---------------------------------------------------------------------------
  // EMPTY STATE
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _emptyInsights({int? month, int? year}) {
    final now = DateTime.now();

    return {
      "budget": 0,
      "spent": 0,
      "remaining": 0,
      "usage_percentage": 0,

      "status": "no_data",
      "budget_status": "no_data",

      "has_budget": false,
      "has_expenses": false,
      "has_enough_data_for_health": false,

      "recommendation": "",
      "top_category": null,
      "category_advice": "",
      "category_breakdown": [],

      "daily_spending": {
        "Mon": 0,
        "Tue": 0,
        "Wed": 0,
        "Thu": 0,
        "Fri": 0,
        "Sat": 0,
        "Sun": 0,
      },

      "highest_spending_day": {"day": null, "amount": 0},

      "average_daily_spending": 0,

      "estimated_month_end_spending": 0,

      "financial_health_score": 0,

      "financial_health_label": "No Data",

      "month": month ?? now.month,

      "year": year ?? now.year,
    };
  }
}
