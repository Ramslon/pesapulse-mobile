import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';
import 'dart:convert';

class DashboardRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Map<String, dynamic> _dashboardToLocal(
    Map<String, dynamic> dashboard,
    Map<String, dynamic> insights,
  ) {
    final summary = dashboard["summary"];

    return {
      "id": 1,

      "total_expenses": summary["total_expenses"],

      "total_count": summary["total_count"],

      "total_categories": summary["categories"],

      "recent_expenses": jsonEncode(dashboard["recent_expenses"]),

      "budget_status": insights["budget_status"],

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

      "budget_status": row["budget_status"],
    };
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final database = await db.database;

    try {
      final dashboard = await ApiService.getDashboard();

      final insights = await ApiService.getFinancialInsights();

      final local = _dashboardToLocal(dashboard, insights);

      await database.insert(
        "dashboard_cache",
        local,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {"dashboard": dashboard, "insights": insights};
    } catch (_) {
      final cached = await database.query("dashboard_cache", where: "id=1");

      if (cached.isEmpty) {
        throw Exception("No cached dashboard");
      }

      return {
        "dashboard": _localToDashboard(cached.first),

        "insights": {"budget_status": cached.first["budget_status"]},
      };
    }
  }
}
