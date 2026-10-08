import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:pesapulse_mobile/services/api_services.dart';
import 'package:pesapulse_mobile/services/sync_service.dart';
import 'package:pesapulse_mobile/services/sync_events.dart';
import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';

class BudgetRepository extends BaseRepository {
  static const Uuid _uuid = Uuid();

  // ---------------------------------------------------------------------------
  // PERIOD HELPERS
  // ---------------------------------------------------------------------------

  int _periodRecordId(int month, int year) {
    return year * 100 + month;
  }

  DateTime _normalizePeriod(int month, int year) {
    return DateTime(year, month);
  }

  // ---------------------------------------------------------------------------
  // LOCAL SERIALIZATION
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _toLocal({
    required Map<String, dynamic> summary,
    required String ownerId,
    required int month,
    required int year,
    String? clientId,
  }) {
    final now = DateTime.now();

    final resolvedClientId = clientId ?? summary["client_id"]?.toString();

    return {
      "owner_id": ownerId,

      "client_id": resolvedClientId,

      "budget": double.tryParse(summary["budget"]?.toString() ?? '0') ?? 0,

      "spent": double.tryParse(summary["spent"]?.toString() ?? '0') ?? 0,

      "remaining":
          double.tryParse(summary["remaining"]?.toString() ?? '0') ?? 0,

      "budget_count":
          int.tryParse(summary["budget_count"]?.toString() ?? '0') ?? 0,

      // Always use the selected period.
      "month": month,
      "year": year,

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

          result["client_id"] ??= row["client_id"];

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
    int month,
    int year,
  ) async {
    final rows = await database.query(
      'budget_summary_cache',
      columns: ['client_id'],
      where: '''
        owner_id = ?
        AND month = ?
        AND year = ?
      ''',
      whereArgs: [ownerId, month, year],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['client_id'];

    if (value == null) {
      return null;
    }

    final clientId = value.toString().trim();

    return clientId.isEmpty ? null : clientId;
  }

  Future<String> _getOrCreateClientId(
    Database database,
    String ownerId,
    int month,
    int year,
  ) async {
    final existing = await _getExistingClientId(database, ownerId, month, year);

    if (existing != null) {
      return existing;
    }

    return _uuid.v4();
  }

  // ---------------------------------------------------------------------------
  // LOCAL CACHE HELPERS
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>?> _getCachedSummary(
    Database database,
    String ownerId,
    int month,
    int year,
  ) async {
    final rows = await database.query(
      "budget_summary_cache",
      where: '''
        owner_id = ?
        AND month = ?
        AND year = ?
      ''',
      whereArgs: [ownerId, month, year],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromLocal(rows.first);
  }

  Future<void> _saveBudgetSummaryCache(
    Database database,
    Map<String, dynamic> data,
    String ownerId,
    String clientId,
    int month,
    int year,
  ) async {
    await database.insert(
      'budget_summary_cache',
      _toLocal(
        summary: data,
        ownerId: ownerId,
        clientId: clientId,
        month: month,
        year: year,
      ),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _deleteCachedSummary(
    Database database,
    String ownerId,
    int month,
    int year,
  ) async {
    await database.delete(
      "budget_summary_cache",
      where: '''
        owner_id = ?
        AND month = ?
        AND year = ?
      ''',
      whereArgs: [ownerId, month, year],
    );
  }

  // ---------------------------------------------------------------------------
  // LOAD BUDGET SUMMARY
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getBudgetSummary({
    bool useCache = false,
    int? month,
    int? year,
  }) async {
    final now = DateTime.now();

    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    _normalizePeriod(selectedMonth, selectedYear);

    final ownerId = await this.ownerId;
    final database = await db.database;

    final isGuest = ownerId == 'guest';

    // -------------------------------------------------------------------------
    // GUEST MODE
    // -------------------------------------------------------------------------

    if (isGuest) {
      final cached = await _getCachedSummary(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      if (cached == null) {
        return {
          "budget": 0,
          "spent": 0,
          "remaining": 0,
          "budget_count": 0,
          "month": selectedMonth,
          "year": selectedYear,
        };
      }

      return cached;
    }

    // -------------------------------------------------------------------------
    // CACHE ONLY
    // -------------------------------------------------------------------------

    if (useCache) {
      final cached = await _getCachedSummary(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      if (cached == null) {
        throw Exception("No cached budget available");
      }

      return cached;
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    // Try server first.
    // -------------------------------------------------------------------------

    try {
      final summary = await ApiService.getBudgetSummary(
        month: selectedMonth,
        year: selectedYear,
      );

      final existingClientId = await _getExistingClientId(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      final serverClientId = summary["client_id"]?.toString();

      final clientId =
          serverClientId != null && serverClientId.trim().isNotEmpty
          ? serverClientId
          : existingClientId;

      if (clientId != null) {
        await _saveBudgetSummaryCache(
          database,
          summary,
          ownerId,
          clientId,
          selectedMonth,
          selectedYear,
        );
      } else {
        // No client ID returned means there may be
        // no budget for this period.
        //
        // Still cache the period summary using an
        // empty client ID so historical no-budget
        // periods can be remembered.
        await _saveBudgetSummaryCache(
          database,
          summary,
          ownerId,
          '',
          selectedMonth,
          selectedYear,
        );
      }

      return {
        ...summary,
        if (clientId != null) "client_id": clientId,
        "month": summary["month"] ?? selectedMonth,
        "year": summary["year"] ?? selectedYear,
      };
    } on RateLimitException {
      rethrow;
    } catch (_) {
      // -----------------------------------------------------------------------
      // API unavailable.
      // Fall back to selected-period local cache.
      // -----------------------------------------------------------------------

      final cached = await _getCachedSummary(
        database,
        ownerId,
        selectedMonth,
        selectedYear,
      );

      if (cached == null) {
        throw Exception("No cached budget available");
      }

      return cached;
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE / UPDATE BUDGET
  // ---------------------------------------------------------------------------

  Future<void> saveBudget({
    required double amount,
    required int month,
    required int year,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    _normalizePeriod(month, year);

    // -------------------------------------------------------------------------
    // GUEST MODE
    // -------------------------------------------------------------------------

    if (ownerId == 'guest') {
      final existingClientId = await _getExistingClientId(
        database,
        ownerId,
        month,
        year,
      );

      final clientId = existingClientId ?? _uuid.v4();

      final cached = await _getCachedSummary(database, ownerId, month, year);

      double spent = 0;

      if (cached != null) {
        spent = double.tryParse(cached["spent"]?.toString() ?? '0') ?? 0;
      }

      final summary = {
        "budget": amount,
        "spent": spent,
        "remaining": amount - spent,
        "budget_count": 1,
        "month": month,
        "year": year,
        "client_id": clientId,
      };

      await _saveBudgetSummaryCache(
        database,
        summary,
        ownerId,
        clientId,
        month,
        year,
      );

      debugPrint(
        'Guest budget saved locally. '
        'period=$year-$month '
        'client_id=$clientId',
      );

      SyncEvents.instance.notifyFinancialDataUpdated();

      return;
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    // -------------------------------------------------------------------------

    final clientId = await _getOrCreateClientId(database, ownerId, month, year);

    try {
      // -----------------------------------------------------------------------
      // ONLINE
      // -----------------------------------------------------------------------

      final summary = await ApiService.setBudget(
        amount,
        clientId,
        month: month,
        year: year,
      );

      final returnedClientId = summary["client_id"]?.toString();

      final finalClientId =
          returnedClientId != null && returnedClientId.trim().isNotEmpty
          ? returnedClientId
          : clientId;

      await _saveBudgetSummaryCache(
        database,
        summary,
        ownerId,
        finalClientId,
        month,
        year,
      );

      debugPrint(
        'Budget saved online. '
        'period=$year-$month '
        'client_id=$finalClientId',
      );

      SyncEvents.instance.notifyFinancialDataUpdated();
    } on RateLimitException {
      rethrow;
    } on http.ClientException {
      // -----------------------------------------------------------------------
      // NETWORK FAILURE
      // Save selected period locally and queue it.
      // -----------------------------------------------------------------------

      final cached = await _getCachedSummary(database, ownerId, month, year);

      double spent = 0;

      if (cached != null) {
        spent = double.tryParse(cached["spent"]?.toString() ?? '0') ?? 0;
      }

      final summary = {
        "budget": amount,
        "spent": spent,
        "remaining": amount - spent,
        "budget_count": 1,
        "month": month,
        "year": year,
        "client_id": clientId,
      };

      await _saveBudgetSummaryCache(
        database,
        summary,
        ownerId,
        clientId,
        month,
        year,
      );

      final periodRecordId = _periodRecordId(month, year);

      // Only replace the pending operation for
      // THIS period.
      await database.delete(
        "sync_queue",
        where: '''
          owner_id = ?
          AND table_name = ?
          AND operation = ?
          AND record_id = ?
        ''',
        whereArgs: [ownerId, "budget", "upsert", periodRecordId],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "budget",
        "operation": "upsert",
        "record_id": periodRecordId,
        "payload": jsonEncode({
          "amount": amount,
          "client_id": clientId,
          "month": month,
          "year": year,
        }),
        "created_at": DateTime.now().toIso8601String(),
      });

      debugPrint(
        'Budget saved locally and queued. '
        'period=$year-$month '
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
    required int month,
    required int year,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final summary = await ApiService.setBudget(
      amount,
      clientId,
      month: month,
      year: year,
    );

    final returnedClientId = summary["client_id"]?.toString();

    final finalClientId =
        returnedClientId != null && returnedClientId.trim().isNotEmpty
        ? returnedClientId
        : clientId;

    await _saveBudgetSummaryCache(
      database,
      summary,
      ownerId,
      finalClientId,
      month,
      year,
    );

    debugPrint(
      'Offline budget synchronized. '
      'period=$year-$month '
      'client_id=$finalClientId',
    );
  }

  // ---------------------------------------------------------------------------
  // DELETE BUDGET
  // ---------------------------------------------------------------------------

  Future<void> deleteBudget({required int month, required int year}) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    _normalizePeriod(month, year);

    final periodRecordId = _periodRecordId(month, year);

    // -------------------------------------------------------------------------
    // GUEST MODE
    // -------------------------------------------------------------------------

    if (ownerId == 'guest') {
      await _deleteCachedSummary(database, ownerId, month, year);

      // Remove only this period's pending operations.
      await database.delete(
        "sync_queue",
        where: '''
          owner_id = ?
          AND table_name = ?
          AND record_id = ?
        ''',
        whereArgs: [ownerId, "budget", periodRecordId],
      );

      debugPrint(
        'Guest budget deleted locally. '
        'period=$year-$month',
      );

      SyncEvents.instance.notifyFinancialDataUpdated();

      return;
    }

    // -------------------------------------------------------------------------
    // AUTHENTICATED USER
    // -------------------------------------------------------------------------

    try {
      await ApiService.deleteBudget(month: month, year: year);

      await _deleteCachedSummary(database, ownerId, month, year);

      debugPrint(
        'Budget deleted online. '
        'period=$year-$month',
      );

      SyncEvents.instance.notifyFinancialDataUpdated();
    } on RateLimitException {
      rethrow;
    } on http.ClientException {
      // -----------------------------------------------------------------------
      // NETWORK UNAVAILABLE
      // Delete only this period locally.
      // -----------------------------------------------------------------------

      await _deleteCachedSummary(database, ownerId, month, year);

      // Remove previous pending operations ONLY
      // for this period.
      await database.delete(
        "sync_queue",
        where: '''
          owner_id = ?
          AND table_name = ?
          AND record_id = ?
        ''',
        whereArgs: [ownerId, "budget", periodRecordId],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "budget",
        "operation": "delete",
        "record_id": periodRecordId,
        "payload": jsonEncode({"month": month, "year": year}),
        "created_at": DateTime.now().toIso8601String(),
      });

      debugPrint(
        'Budget deleted locally and deletion queued. '
        'period=$year-$month',
      );

      await SyncService.instance.getPendingChanges();
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC OFFLINE BUDGET DELETE
  // ---------------------------------------------------------------------------

  Future<void> syncOfflineBudgetDelete({
    required int month,
    required int year,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.deleteBudget(month: month, year: year);

    await _deleteCachedSummary(database, ownerId, month, year);

    debugPrint(
      'Offline budget deletion synchronized. '
      'period=$year-$month',
    );
  }
}
