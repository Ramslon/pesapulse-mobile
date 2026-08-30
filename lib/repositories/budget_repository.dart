import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../services/api_services.dart';
import '../services/sync_service.dart';

import 'package:http/http.dart' as http;
import '../exceptions/rate_limit_exception.dart';

class BudgetRepository extends BaseRepository {
  Map<String, dynamic> _toLocal(Map<String, dynamic> summary, String ownerId) {
    return {
      "owner_id": ownerId,

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

  Future<Map<String, dynamic>> getBudgetSummary({bool useCache = false}) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    if (useCache) {
      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isEmpty) {
        throw Exception("No cached budget available");
      }

      return _fromLocal(cached.first);
    }

    try {
      final summary = await ApiService.getBudgetSummary();

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return summary;
    } on RateLimitException {
      rethrow;
    } catch (_) {
      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      if (cached.isEmpty) {
        throw Exception("No cached budget available");
      }

      return _fromLocal(cached.first);
    }
  }

  Future<void> saveBudget(double amount) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final summary = await ApiService.setBudget(amount);

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } on RateLimitException {
      // Do NOT treat rate limiting as offline.
      rethrow;
    } on http.ClientException {
      // Offline

      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
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
        _toLocal(summary, ownerId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,

        "table_name": "budget",

        "operation": "upsert",

        "record_id": 1,

        "payload": jsonEncode({"amount": amount}),

        "created_at": DateTime.now().toIso8601String(),
      });

      await SyncService.instance.getPendingChanges();
    }
  }

  Future<void> syncOfflineBudgetUpsert(double amount) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final summary = await ApiService.setBudget(amount);

    await database.insert(
      "budget_summary_cache",
      _toLocal(summary, ownerId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBudget() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      await ApiService.deleteBudget();

      await database.delete(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );
    } on RateLimitException {
      // Rate limiting is NOT an offline condition.
      // Let the UI handle the 429 response.
      rethrow;
    } on http.ClientException {
      // Actual network failure → delete locally and queue
      // the operation for synchronization.
      await database.delete(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "budget",
        "operation": "delete",
        "record_id": 1,
        "payload": "{}",
        "created_at": DateTime.now().toIso8601String(),
      });

      await SyncService.instance.getPendingChanges();
    }
  }

  Future<void> syncOfflineBudgetDelete() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.deleteBudget();

    await database.delete(
      "budget_summary_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
    );
  }
}
