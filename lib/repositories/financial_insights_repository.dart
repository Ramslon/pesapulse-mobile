import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class FinancialInsightsRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Map<String, dynamic> _toLocal(Map<String, dynamic> insights) {
    return {
      "id": 1,

      "budget_status": insights["budget_status"],

      "payload": jsonEncode(insights),

      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> row) {
    return jsonDecode(row["payload"]);
  }

  Future<Map<String, dynamic>> getInsights() async {
    final database = await db.database;

    try {
      final insights = await ApiService.getFinancialInsights();

      await database.insert(
        "financial_insights_cache",
        _toLocal(insights),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return insights;
    } catch (_) {
      final cached = await database.query(
        "financial_insights_cache",
        where: "id=1",
      );

      if (cached.isEmpty) {
        throw Exception("No cached financial insights");
      }

      return _fromLocal(cached.first);
    }
  }
}
