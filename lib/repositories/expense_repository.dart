import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../services/api_services.dart';
import '../services/startup_refresh_coordinator.dart';
import '../services/sync_events.dart';
import '../services/sync_service.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  // ---------------------------------------------------------------------------
  // DATE HELPERS
  // ---------------------------------------------------------------------------

  String _dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  DateTime _currentMonthStartDate() {
    final now = DateTime.now();

    return DateTime(now.year, now.month, 1);
  }

  DateTime _nextMonthStartDate() {
    final now = DateTime.now();

    return DateTime(now.year, now.month + 1, 1);
  }

  String _monthStart({required int month, required int year}) {
    return _dateOnly(DateTime(year, month, 1));
  }

  String _nextMonthStart({required int month, required int year}) {
    return _dateOnly(DateTime(year, month + 1, 1));
  }

  // ---------------------------------------------------------------------------
  // LOCAL EXPENSE MAPPING
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _expenseToLocal(
    Map<String, dynamic> expense,
    String ownerId,
  ) {
    return {
      "id": expense["id"],
      "server_id": expense["id"],
      "client_id": expense["client_id"],
      "owner_id": ownerId,
      "title": expense["title"],
      "amount": double.tryParse(expense["amount"].toString()) ?? 0,
      "category": expense["category"],
      "expense_date": expense["expense_date"],
      "description": expense["description"] ?? "",
      "updated_at": expense["updated_at"],
      "is_synced": 1,
      "is_deleted": 0,
    };
  }

  // ---------------------------------------------------------------------------
  // CURRENT MONTH LOCAL EXPENSES
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getCurrentMonthExpensesFromLocal() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final start = _dateOnly(_currentMonthStartDate());

    final end = _dateOnly(_nextMonthStartDate());

    final rows = await database.query(
      "expenses",
      where: '''
        owner_id = ?
        AND is_deleted = 0
        AND expense_date >= ?
        AND expense_date < ?
      ''',
      whereArgs: [ownerId, start, end],
      orderBy: "expense_date DESC, id DESC",
    );

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  // ---------------------------------------------------------------------------
  // LOCAL EXPENSES FOR A SPECIFIC MONTH
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getExpensesFromLocal({
    int? month,
    int? year,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now();

    final selectedMonth = month ?? now.month;
    final selectedYear = year ?? now.year;

    final start = _monthStart(month: selectedMonth, year: selectedYear);

    final end = _nextMonthStart(month: selectedMonth, year: selectedYear);

    final rows = await database.query(
      "expenses",
      where: '''
        owner_id = ?
        AND is_deleted = 0
        AND expense_date >= ?
        AND expense_date < ?
      ''',
      whereArgs: [ownerId, start, end],
      orderBy: "expense_date DESC, id DESC",
    );

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  // ---------------------------------------------------------------------------
  // ALL LOCAL EXPENSES
  //
  // Used when the application needs historical data.
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> getAllExpensesFromLocal() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final rows = await database.query(
      "expenses",
      where: "owner_id = ? AND is_deleted = 0",
      whereArgs: [ownerId],
      orderBy: "expense_date DESC, id DESC",
    );

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }

  // ---------------------------------------------------------------------------
  // API EXPENSES
  //
  // Defaults to the current month.
  //
  // Example:
  //
  // getExpenses()
  //     -> current month
  //
  // getExpenses(month: 9, year: 2026)
  //     -> September 2026
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getExpenses({
    int page = 1,
    int? month,
    int? year,
  }) async {
    final ownerId = await this.ownerId;

    try {
      final response = await ApiService.getExpenses(
        page: page,
        month: month,
        year: year,
      );

      final database = await db.database;

      if (page == 1) {
        final selectedMonth = month ?? DateTime.now().month;
        final selectedYear = year ?? DateTime.now().year;

        final start = _monthStart(month: selectedMonth, year: selectedYear);

        final end = _nextMonthStart(month: selectedMonth, year: selectedYear);

        // Only replace synced records belonging to the requested month.
        //
        // Historical months remain untouched.
        await database.delete(
          "expenses",
          where: '''
            owner_id = ?
            AND is_synced = 1
            AND expense_date >= ?
            AND expense_date < ?
          ''',
          whereArgs: [ownerId, start, end],
        );
      }

      for (final expense in response["data"] as List? ?? []) {
        await database.insert(
          "expenses",
          _expenseToLocal(Map<String, dynamic>.from(expense), ownerId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await SyncService.instance.getPendingChanges();

      return response;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('ExpenseRepository: API getExpenses failed: $e');

      final cached = await getExpensesFromLocal(month: month, year: year);

      return {"data": cached, "next_page_url": null};
    }
  }

  // ---------------------------------------------------------------------------
  // SHARED INITIAL EXPENSE REFRESH
  //
  // IMPORTANT:
  // This downloads all available server expenses/pages exposed by the API
  // response and keeps historical data locally.
  //
  // We deliberately DO NOT filter this method to the current month.
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> refreshExpenses() async {
    return await StartupRefreshCoordinator.instance.run('expenses', () async {
      final ownerId = await this.ownerId;

      try {
        debugPrint('ExpenseRepository: requesting all expenses from API...');

        final allExpenses = <Map<String, dynamic>>[];
        var page = 1;

        while (true) {
          debugPrint('ExpenseRepository: requesting expenses page $page...');

          final response = await ApiService.getAllExpenses(page: page);

          final pageExpenses = (response["data"] as List? ?? [])
              .map((expense) => Map<String, dynamic>.from(expense))
              .toList();

          allExpenses.addAll(pageExpenses);

          debugPrint(
            'ExpenseRepository: page $page returned '
            '${pageExpenses.length} expenses.',
          );

          final nextPageUrl = response["next_page_url"];

          if (nextPageUrl == null || nextPageUrl.toString().isEmpty) {
            break;
          }

          page++;
        }

        final database = await db.database;

        await database.transaction((txn) async {
          // Remove only server-synced records.
          //
          // Unsynced records are local/offline changes and must
          // remain untouched.
          await txn.delete(
            "expenses",
            where: "owner_id = ? AND is_synced = 1",
            whereArgs: [ownerId],
          );

          for (final expense in allExpenses) {
            await txn.insert(
              "expenses",
              _expenseToLocal(expense, ownerId)..["is_synced"] = 1,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });

        debugPrint(
          'ExpenseRepository: cached '
          '${allExpenses.length} server expenses '
          'across $page page(s).',
        );

        await SyncService.instance.getPendingChanges();

        debugPrint('ExpenseRepository: expenses refresh completed.');

        return {"data": allExpenses, "next_page_url": null};
      } on RateLimitException {
        rethrow;
      } catch (e) {
        debugPrint(
          'ExpenseRepository: API refresh failed, '
          'using cache: $e',
        );

        final cached = await getAllExpensesFromLocal();

        debugPrint(
          'ExpenseRepository: returning '
          '${cached.length} cached expenses.',
        );

        return {"data": cached, "next_page_url": null};
      }
    });
  }
  // ---------------------------------------------------------------------------
  // CREATE EXPENSE
  // ---------------------------------------------------------------------------

  Future<void> createExpense({
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    const uuid = Uuid();

    final clientId = uuid.v4();

    final expense = <String, dynamic>{
      "owner_id": ownerId,
      "client_id": clientId,
      "title": title.trim(),
      "amount": amount,
      "category": category,
      "expense_date": expenseDate,
      "description": description,
    };

    try {
      final response = await ApiService.addExpense(
        clientId: clientId,
        title: title,
        amount: amount,
        category: category,
        expenseDate: expenseDate,
        description: description,
      );

      final serverId = response["id"];

      if (serverId == null) {
        throw Exception(
          'Server returned a successful response '
          'without an expense id.',
        );
      }

      final localExpense = <String, dynamic>{
        "id": serverId,
        "server_id": serverId,
        "client_id": response["client_id"] ?? clientId,
        "owner_id": ownerId,
        "title": response["title"] ?? title,
        "amount":
            double.tryParse(response["amount"]?.toString() ?? amount) ?? 0,
        "category": response["category"] ?? category,
        "expense_date": response["expense_date"] ?? expenseDate,
        "description": response["description"] ?? description,
        "updated_at": response["updated_at"],
        "is_synced": 1,
        "is_deleted": 0,
      };

      await database.insert(
        "expenses",
        localExpense,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      SyncEvents.instance.notifyFinancialDataUpdated();

      debugPrint(
        'ExpenseRepository: online expense creation complete. '
        'client_id=$clientId, '
        'server_id=$serverId, '
        'deduplicated=${response["deduplicated"] ?? false}',
      );

      return;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('ExpenseRepository: online expense creation failed: $e');

      final localId = await database.insert("expenses", {
        ...expense,
        "is_synced": 0,
        "is_deleted": 0,
      });

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "expenses",
        "record_id": localId,
        "operation": "create",
        "payload": jsonEncode(expense),
      });

      await SyncService.instance.getPendingChanges();

      SyncEvents.instance.notifyFinancialDataUpdated();

      debugPrint(
        'ExpenseRepository: expense saved locally '
        'for synchronization. '
        'local_id=$localId, '
        'client_id=$clientId',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC OFFLINE CREATE
  // ---------------------------------------------------------------------------

  Future<void> syncOfflineExpense({
    required int localId,
    required String clientId,
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final response = await ApiService.addExpense(
      clientId: clientId,
      title: title,
      amount: amount,
      category: category,
      expenseDate: expenseDate,
      description: description,
    );

    final serverId = response["id"];

    if (serverId == null) {
      throw Exception(
        'Server returned a successful response '
        'without an expense id.',
      );
    }

    await database.update(
      "expenses",
      {
        "owner_id": ownerId,
        "server_id": serverId,
        "client_id": response["client_id"] ?? clientId,
        "title": response["title"] ?? title,
        "amount":
            double.tryParse(response["amount"]?.toString() ?? amount) ?? 0,
        "category": response["category"] ?? category,
        "expense_date": response["expense_date"] ?? expenseDate,
        "description": response["description"] ?? description,
        "updated_at":
            response["updated_at"] ?? DateTime.now().toIso8601String(),
        "is_synced": 1,
        "is_deleted": 0,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
    );

    debugPrint(
      'ExpenseRepository: offline expense synchronized. '
      'local_id=$localId, '
      'client_id=$clientId, '
      'server_id=$serverId, '
      'deduplicated=${response["deduplicated"] ?? false}',
    );
  }

  // ---------------------------------------------------------------------------
  // UPDATE EXPENSE
  // ---------------------------------------------------------------------------

  Future<void> updateExpense({
    required int id,
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final serverId = await getServerExpenseId(id);

    final expense = {
      "title": title,
      "amount": double.tryParse(amount) ?? 0,
      "category": category,
      "expense_date": expenseDate,
      "description": description,
      "updated_at": DateTime.now().toIso8601String(),
    };

    try {
      if (serverId != null) {
        await ApiService.updateExpense(
          serverId,
          title,
          amount,
          category,
          expenseDate,
          description,
        );
      } else {
        await database.update(
          "expenses",
          {...expense, "is_synced": 0},
          where: "id=? AND owner_id=?",
          whereArgs: [id, ownerId],
        );

        await database.insert("sync_queue", {
          "owner_id": ownerId,
          "table_name": "expenses",
          "record_id": id,
          "operation": "update",
          "payload": jsonEncode({...expense, "server_id": null}),
        });

        await SyncService.instance.getPendingChanges();

        SyncEvents.instance.notifyFinancialDataUpdated();

        if (ownerId != "guest") {
          await SyncService.instance.requestSync();
        }

        return;
      }

      await database.update(
        "expenses",
        {...expense, "server_id": serverId, "is_synced": 1, "is_deleted": 0},
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );

      SyncEvents.instance.notifyFinancialDataUpdated();

      debugPrint(
        'ExpenseRepository: expense updated successfully '
        '(localId=$id, serverId=$serverId).',
      );
    } on RateLimitException {
      rethrow;
    } catch (e) {
      await database.update(
        "expenses",
        {...expense, "is_synced": 0},
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "expenses",
        "record_id": id,
        "operation": "update",
        "payload": jsonEncode({...expense, "server_id": serverId}),
      });

      await SyncService.instance.getPendingChanges();

      SyncEvents.instance.notifyFinancialDataUpdated();

      if (ownerId != "guest") {
        await SyncService.instance.requestSync();
      }

      debugPrint(
        'ExpenseRepository: expense update failed remotely; '
        'change queued for automatic sync: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC OFFLINE UPDATE
  // ---------------------------------------------------------------------------

  Future<void> syncOfflineExpenseUpdate({
    required int localId,
    required int serverId,
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.updateExpense(
      serverId,
      title,
      amount,
      category,
      expenseDate,
      description,
    );

    await database.update(
      "expenses",
      {
        "title": title,
        "amount": double.tryParse(amount) ?? 0,
        "category": category,
        "expense_date": expenseDate,
        "description": description,
        "server_id": serverId,
        "updated_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
        "is_deleted": 0,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
    );

    debugPrint(
      'ExpenseRepository: offline expense update synced '
      '(localId=$localId, serverId=$serverId).',
    );
  }

  // ---------------------------------------------------------------------------
  // GET SERVER ID
  // ---------------------------------------------------------------------------

  Future<int?> getServerExpenseId(int localId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final rows = await database.query(
      "expenses",
      columns: ["server_id"],
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first["server_id"] as int?;
  }

  // ---------------------------------------------------------------------------
  // DELETE EXPENSE
  // ---------------------------------------------------------------------------

  Future<void> deleteExpense(int id) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final serverId = await getServerExpenseId(id);

    try {
      if (serverId != null) {
        await ApiService.deleteExpense(serverId);
      }

      await database.delete(
        "expenses",
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );

      SyncEvents.instance.notifyFinancialDataUpdated();

      debugPrint(
        'ExpenseRepository: expense deleted successfully '
        '(localId=$id, serverId=$serverId).',
      );
    } on RateLimitException {
      rethrow;
    } catch (e) {
      await database.delete(
        "expenses",
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "expenses",
        "record_id": id,
        "operation": "delete",
        "payload": jsonEncode({"server_id": serverId}),
      });

      await SyncService.instance.getPendingChanges();

      SyncEvents.instance.notifyFinancialDataUpdated();

      if (ownerId != "guest") {
        await SyncService.instance.requestSync();
      }

      debugPrint(
        'ExpenseRepository: expense deletion failed remotely; '
        'queued for automatic sync: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SYNC OFFLINE DELETE
  // ---------------------------------------------------------------------------

  Future<void> syncOfflineExpenseDelete({
    required int localId,
    required int serverId,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.deleteExpense(serverId);

    await database.delete(
      "expenses",
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
    );

    debugPrint(
      'ExpenseRepository: offline expense deletion synced '
      '(localId=$localId, serverId=$serverId).',
    );
  }
}
