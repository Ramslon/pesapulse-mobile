import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:pesapulse_mobile/services/api_services.dart';
import 'package:pesapulse_mobile/services/sync_service.dart';
import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';

class BudgetRepository extends BaseRepository {
  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // LOCAL SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toLocal({
    required Map<String, dynamic> summary,
    required String ownerId,
    String? clientId,
  }) {
    final now = DateTime.now();

    return {
      "owner_id": ownerId,

      "client_id": clientId,

      "budget": double.tryParse(summary["budget"]?.toString() ?? '0') ?? 0,

      "spent": double.tryParse(summary["spent"]?.toString() ?? '0') ?? 0,

      "remaining":
          double.tryParse(summary["remaining"]?.toString() ?? '0') ?? 0,

      "budget_count":
          int.tryParse(summary["budget_count"]?.toString() ?? '0') ?? 0,

      "month": int.tryParse(summary["month"]?.toString() ?? '') ?? now.month,

      "year": int.tryParse(summary["year"]?.toString() ?? '') ?? now.year,

      "payload": jsonEncode(summary),

      "updated_at": now.toIso8601String(),
    };
  }

  Map<String, dynamic> _fromLocal(Map<String, dynamic> row) {
    final payload = row["payload"];

    if (payload is String && payload.isNotEmpty) {
      try {
        final decoded = jsonDecode(payload);

        if (decoded is Map) {
          final result = Map<String, dynamic>.from(decoded);

          // Make sure the local client ID is also available.
          if (!result.containsKey("client_id") || result["client_id"] == null) {
            result["client_id"] = row["client_id"];
          }

          // Make sure month/year are available.
          result["month"] ??= row["month"] ?? DateTime.now().month;
          result["year"] ??= row["year"] ?? DateTime.now().year;

          return result;
        }
      } catch (e) {
        debugPrint('Failed to decode local budget payload: $e');
      }
    }

    return {
      "budget": row["budget"] ?? 0,
      "spent": row["spent"] ?? 0,
      "remaining": row["remaining"] ?? 0,
      "budget_count": row["budget_count"] ?? 0,
      "client_id": row["client_id"],
      "month": row["month"] ?? DateTime.now().month,
      "year": row["year"] ?? DateTime.now().year,
    };
  }

  // ---------------------------------------------------------------------------
  // CLIENT ID
  // ---------------------------------------------------------------------------

  Future<String?> _getExistingClientId(
    Database database,
    String ownerId,
  ) async {
    final rows = await database.query(
      "budget_summary_cache",
      columns: ["client_id"],
      where: "owner_id=?",
      whereArgs: [ownerId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first["client_id"]?.toString();

    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return value;
  }

  Future<String> _getOrCreateClientId(Database database, String ownerId) async {
    final existing = await _getExistingClientId(database, ownerId);

    if (existing != null) {
      return existing;
    }

    return _uuid.v4();
  }

  // ---------------------------------------------------------------------------
  // LOAD BUDGET SUMMARY
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getBudgetSummary({bool useCache = false}) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final isGuest = ownerId == 'guest';

    // -------------------------------------------------------------------------
    // GUEST MODE
    // -------------------------------------------------------------------------
    //
    // Guest budgets are local only.
    // Never call the authenticated API.
    //
    if (isGuest) {
      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
        limit: 1,
      );

      if (cached.isEmpty) {
        return {
          "budget": 0,
          "spent": 0,
          "remaining": 0,
          "budget_count": 0,
          "month": DateTime.now().month,
          "year": DateTime.now().year,
        };
      }

      return _fromLocal(cached.first);
    }

    // -------------------------------------------------------------------------
    // CACHE ONLY
    // -------------------------------------------------------------------------

    if (useCache) {
      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
        limit: 1,
      );

      if (cached.isEmpty) {
        throw Exception("No cached budget available");
      }

      return _fromLocal(cached.first);
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    // Try server first.
    // -------------------------------------------------------------------------

    try {
      final summary = await ApiService.getBudgetSummary();

      final existingClientId = await _getExistingClientId(database, ownerId);

      final serverClientId = summary["client_id"]?.toString();

      final clientId =
          serverClientId != null && serverClientId.trim().isNotEmpty
          ? serverClientId
          : existingClientId;

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary: summary, ownerId: ownerId, clientId: clientId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      return {...summary, if (clientId != null) "client_id": clientId};
    } on RateLimitException {
      rethrow;
    } catch (_) {
      // -----------------------------------------------------------------------
      // API unavailable.
      // Fall back to local cache.
      // -----------------------------------------------------------------------

      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
        limit: 1,
      );

      if (cached.isEmpty) {
        throw Exception("No cached budget available");
      }

      return _fromLocal(cached.first);
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE / UPDATE BUDGET
  // ---------------------------------------------------------------------------

  Future<void> saveBudget({required double amount}) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now();

    final budgetMonth = now.month;
    final budgetYear = now.year;

    // -------------------------------------------------------------------------
    // GUEST MODE
    // -------------------------------------------------------------------------
    //
    // Guest budget remains entirely local.
    //
    if (ownerId == 'guest') {
      final existingClientId = await _getExistingClientId(database, ownerId);

      final clientId = existingClientId ?? _uuid.v4();

      Map<String, dynamic> summary = {
        "budget": amount,
        "spent": 0,
        "remaining": amount,
        "budget_count": 1,
        "month": budgetMonth,
        "year": budgetYear,
        "client_id": clientId,
      };

      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
        limit: 1,
      );

      if (cached.isNotEmpty) {
        final existing = _fromLocal(cached.first);

        final spent =
            double.tryParse(existing["spent"]?.toString() ?? '0') ?? 0;

        summary = {
          ...existing,
          "budget": amount,
          "spent": spent,
          "remaining": amount - spent,
          "budget_count": 1,
          "month": budgetMonth,
          "year": budgetYear,
          "client_id": clientId,
        };
      }

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary: summary, ownerId: ownerId, clientId: clientId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Guest budget saved locally. client_id=$clientId');

      return;
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    //
    // Preserve the same client ID for updates.
    // -------------------------------------------------------------------------

    final clientId = await _getOrCreateClientId(database, ownerId);

    try {
      // -----------------------------------------------------------------------
      // ONLINE
      //
      // Important:
      // ApiService will send amount + clientId.
      // Laravel determines month/year.
      // -----------------------------------------------------------------------

      final summary = await ApiService.setBudget(amount, clientId);

      final returnedClientId = summary["client_id"]?.toString();

      final finalClientId =
          returnedClientId != null && returnedClientId.trim().isNotEmpty
          ? returnedClientId
          : clientId;

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary: summary, ownerId: ownerId, clientId: finalClientId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('Budget saved online. client_id=$finalClientId');
    } on RateLimitException {
      // -----------------------------------------------------------------------
      // Rate limiting is NOT an offline condition.
      // -----------------------------------------------------------------------
      rethrow;
    } on http.ClientException {
      // -----------------------------------------------------------------------
      // ACTUAL NETWORK FAILURE
      //
      // Save locally and queue for synchronization.
      // -----------------------------------------------------------------------

      final cached = await database.query(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
        limit: 1,
      );

      Map<String, dynamic> summary;

      if (cached.isNotEmpty) {
        summary = _fromLocal(cached.first);
      } else {
        summary = {
          "budget": amount,
          "spent": 0,
          "remaining": amount,
          "budget_count": 1,
          "month": budgetMonth,
          "year": budgetYear,
          "client_id": clientId,
        };
      }

      final spent = double.tryParse(summary["spent"]?.toString() ?? '0') ?? 0;

      summary["budget"] = amount;
      summary["spent"] = spent;
      summary["remaining"] = amount - spent;
      summary["budget_count"] = 1;
      summary["month"] = budgetMonth;
      summary["year"] = budgetYear;
      summary["client_id"] = clientId;

      await database.insert(
        "budget_summary_cache",
        _toLocal(summary: summary, ownerId: ownerId, clientId: clientId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // -----------------------------------------------------------------------
      // Remove an older pending budget upsert for this owner.
      //
      // This prevents multiple offline edits from creating unnecessary
      // synchronization operations.
      // -----------------------------------------------------------------------

      await database.delete(
        "sync_queue",
        where: "owner_id=? AND table_name=? AND operation=?",
        whereArgs: [ownerId, "budget", "upsert"],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "budget",
        "operation": "upsert",
        "record_id": 1,
        "payload": jsonEncode({"amount": amount, "client_id": clientId}),
        "created_at": DateTime.now().toIso8601String(),
      });

      debugPrint(
        'Budget saved locally and queued for sync. '
        'client_id=$clientId',
      );

      await SyncService.instance.getPendingChanges();
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC OFFLINE BUDGET UPDATE
  // ---------------------------------------------------------------------------

  Future<void> syncOfflineBudgetUpsert({
    required double amount,
    required String clientId,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final summary = await ApiService.setBudget(amount, clientId);

    final returnedClientId = summary["client_id"]?.toString();

    final finalClientId =
        returnedClientId != null && returnedClientId.trim().isNotEmpty
        ? returnedClientId
        : clientId;

    await database.insert(
      "budget_summary_cache",
      _toLocal(summary: summary, ownerId: ownerId, clientId: finalClientId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    debugPrint(
      'Offline budget synchronized successfully. '
      'client_id=$finalClientId',
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE BUDGET
  // ---------------------------------------------------------------------------

  Future<void> deleteBudget() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    // -------------------------------------------------------------------------
    // GUEST MODE
    // -------------------------------------------------------------------------

    if (ownerId == 'guest') {
      await database.delete(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      // Remove any guest budget synchronization operations.
      await database.delete(
        "sync_queue",
        where: "owner_id=? AND table_name=?",
        whereArgs: [ownerId, "budget"],
      );

      debugPrint('Guest budget deleted locally.');

      return;
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    // -------------------------------------------------------------------------

    try {
      await ApiService.deleteBudget();

      await database.delete(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      debugPrint('Budget deleted online.');
    } on RateLimitException {
      rethrow;
    } on http.ClientException {
      // -----------------------------------------------------------------------
      // Network unavailable.
      // Delete locally and queue deletion.
      // -----------------------------------------------------------------------

      await database.delete(
        "budget_summary_cache",
        where: "owner_id=?",
        whereArgs: [ownerId],
      );

      // Remove previous pending budget operations.
      await database.delete(
        "sync_queue",
        where: "owner_id=? AND table_name=?",
        whereArgs: [ownerId, "budget"],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "budget",
        "operation": "delete",
        "record_id": 1,
        "payload": "{}",
        "created_at": DateTime.now().toIso8601String(),
      });

      debugPrint('Budget deleted locally and deletion queued.');

      await SyncService.instance.getPendingChanges();
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC OFFLINE BUDGET DELETE
  // ---------------------------------------------------------------------------

  Future<void> syncOfflineBudgetDelete() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.deleteBudget();

    await database.delete(
      "budget_summary_cache",
      where: "owner_id=?",
      whereArgs: [ownerId],
    );

    debugPrint('Offline budget deletion synchronized.');
  }
}
