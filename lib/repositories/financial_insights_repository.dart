import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';
import '../services/session_service.dart';

import '../services/api_services.dart';

class FinancialInsightsRepository extends BaseRepository {
  Map<String, dynamic> _toLocal(Map<String, dynamic> insights, String ownerId) {
    return {
      "owner_id": ownerId,

      "budget_status": insights["budget_status"],

      "payload": jsonEncode(insights),

      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> row) {
    return jsonDecode(row["payload"]);
  }

  Future<Map<String, dynamic>> getInsights({bool useCache = false}) async {
    final database = await db.database;
    final ownerId = await this.ownerId;

    if (useCache) {
      final cached = await database.query(
        "financial_insights_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isNotEmpty) {
        return _fromLocal(cached.first);
      }

      return _emptyInsights();
    }

    // Guest users: never call the backend
    if (await SessionService.isGuest()) {
      final cached = await database.query(
        "financial_insights_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isNotEmpty) {
        return _fromLocal(cached.first);
      }

      return _emptyInsights();
    }

    try {
      final insights = await ApiService.getFinancialInsights();

      await database.insert(
        "financial_insights_cache",
        _toLocal(insights, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return insights;
    } catch (_) {
      final cached = await database.query(
        "financial_insights_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isNotEmpty) {
        return _fromLocal(cached.first);
      }

      return _emptyInsights();
    }
  }

  Map<String, dynamic> _emptyInsights() {
    return {
      "budget": 0,
      "spent": 0,
      "remaining": 0,
      "usage_percentage": 0,
      "status": "healthy",
      "budget_status": "healthy",
      "recommendation": "Create a budget to receive financial insights.",
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
      "financial_health_score": 100,
      "financial_health_label": "No Data",
    };
  }
}
