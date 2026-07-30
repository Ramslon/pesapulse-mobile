import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<Map<String, dynamic>> getInsights() async {
    final database = await db.database;
    final ownerId = await this.ownerId;

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

      if (cached.isEmpty) {
        throw Exception("No cached financial insights");
      }

      return _fromLocal(cached.first);
    }
  }
}
