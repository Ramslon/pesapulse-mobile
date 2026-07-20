import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';
import '../services/sync_service.dart';

class BudgetRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Map<String, dynamic> _toLocal(Map<String, dynamic> summary) {
    return {
      "id": 1,

      "budget": double.tryParse(summary["budget"].toString()) ?? 0,

      "spent": double.tryParse(summary["spent"].toString()) ?? 0,

      "remaining": double.tryParse(summary["remaining"].toString()) ?? 0,

      "payload": jsonEncode(summary),

      "updated_at": DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> row) {
    return jsonDecode(row["payload"]);
  }

  Future<Map<String, dynamic>> getBudgetSummary() async {
    final database = await db.database;

    try {
      final summary = await ApiService.getBudgetSummary();

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return summary;
    } catch (_) {
      final cached = await database.query(
        "budget_summary_cache",
        where: "id=1",
      );

      if (cached.isEmpty) {
        throw Exception("No cached budget available");
      }

      return _fromLocal(cached.first);
    }
  }

  Future<void> saveBudget(double amount) async {
    final database = await db.database;

    try {
      final summary = await ApiService.setBudget(amount);

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Offline

      final cached = await database.query(
        "budget_summary_cache",
        where: "id=1",
      );

      Map<String, dynamic> summary;

      if (cached.isNotEmpty) {
        summary = _fromLocal(cached.first);
      } else {
        summary = {"budget": amount, "spent": 0, "remaining": amount};
      }

      summary["budget"] = amount;
      summary["remaining"] =
          amount - (double.tryParse(summary["spent"].toString()) ?? 0);

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await database.insert("sync_queue", {
        "table_name": "budget",

        "operation": "upsert",

        "record_id": 1,

        "payload": jsonEncode({"amount": amount}),

        "created_at": DateTime.now().toIso8601String(),
      });

      await SyncService.instance.getPendingChanges();
    }
  }

  Future<void> deleteBudget() async {
    final database = await db.database;

    try {
      await ApiService.deleteBudget();

      await database.delete("budget_summary_cache");
    } catch (_) {
      await database.delete("budget_summary_cache");

      await database.insert("sync_queue", {
        "table_name": "budget",

        "operation": "delete",

        "record_id": 1,

        "payload": "{}",

        "created_at": DateTime.now().toIso8601String(),
      });

      await SyncService.instance.getPendingChanges();
    }
  }
}
