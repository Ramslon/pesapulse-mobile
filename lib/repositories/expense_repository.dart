import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';

import '../services/api_services.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:pesapulse_mobile/services/startup_refresh_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../services/sync_service.dart';
import '../services/sync_events.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
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

  /// Get expenses
  /// Get expenses from the API and update the local database.
  Future<Map<String, dynamic>> getExpenses({int page = 1}) async {
    final ownerId = await this.ownerId;

    try {
      final response = await ApiService.getExpenses(page: page);

      final database = await db.database;

      if (page == 1) {
        await database.delete(
          "expenses",
          where: "owner_id = ?",
          whereArgs: [ownerId],
        );
      }

      for (final expense in response["data"]) {
        await database.insert(
          "expenses",
          _expenseToLocal(expense, ownerId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await SyncService.instance.getPendingChanges();

      return response;
    } on RateLimitException {
      rethrow;
    } catch (_) {
      final database = await db.database;

      final cached = await database.query(
        "expenses",
        where: "owner_id = ?",
        whereArgs: [ownerId],
        orderBy: "expense_date DESC",
      );

      return {"data": cached, "next_page_url": null};
    }
  }

  /// Shared initial expenses refresh.
  ///
  /// This method returns the same API response used by
  /// Analytics and other startup consumers.
  Future<Map<String, dynamic>> refreshExpenses() async {
    return await StartupRefreshCoordinator.instance.run('expenses', () async {
      final ownerId = await this.ownerId;

      try {
        debugPrint('ExpenseRepository: requesting expenses from API...');

        final response = await ApiService.getExpenses();

        final database = await db.database;

        final expenses = (response["data"] as List? ?? [])
            .map((expense) => Map<String, dynamic>.from(expense))
            .toList();

        await database.transaction((txn) async {
          // Remove only records that were already synced.
          //
          // IMPORTANT:
          // is_synced = 0 records are local/offline changes and
          // must never be deleted by a server refresh.
          await txn.delete(
            "expenses",
            where: "owner_id = ? AND is_synced = 1",
            whereArgs: [ownerId],
          );

          for (final expense in expenses) {
            await txn.insert(
              "expenses",
              _expenseToLocal(expense, ownerId)..["is_synced"] = 1,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });

        debugPrint(
          'ExpenseRepository: cached ${expenses.length} server expenses.',
        );

        // Preserve the existing offline-sync behavior.
        await SyncService.instance.getPendingChanges();

        debugPrint('ExpenseRepository: expenses refresh completed.');

        return response;
      } on RateLimitException {
        rethrow;
      } catch (e) {
        debugPrint('ExpenseRepository: API refresh failed, using cache: $e');

        final database = await db.database;

        final cached = await database.query(
          "expenses",
          where: "owner_id = ?",
          whereArgs: [ownerId],
          orderBy: "expense_date DESC",
        );

        debugPrint(
          'ExpenseRepository: returning ${cached.length} cached expenses.',
        );

        return {"data": cached, "next_page_url": null};
      }
    });
  }

  Future<void> createExpense({
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    // One stable ID for the entire lifetime of this expense.
    //
    // The same client_id is used for:
    // - online creation
    // - local SQLite
    // - sync_queue
    // - retry after a failed/lost response
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
      // ------------------------------------------------------------
      // ONLINE CREATION
      // ------------------------------------------------------------

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
          'Server returned a successful response without an expense id.',
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

      debugPrint(
        'ExpenseRepository: online expense creation complete. '
        'client_id=$clientId, '
        'server_id=$serverId, '
        'deduplicated=${response["deduplicated"] ?? false}',
      );

      // No sync queue entry for a successful online creation.
      return;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      // ------------------------------------------------------------
      // ONLINE FAILED → LOCAL + SYNC QUEUE
      // ------------------------------------------------------------

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

      debugPrint(
        'ExpenseRepository: expense saved locally for synchronization. '
        'local_id=$localId, '
        'client_id=$clientId',
      );
    }
  }

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
        'Server returned a successful response without an expense id.',
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
      // If the record exists on the server, update the server record.
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
        // No server record yet. Keep the change local and sync later.
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

        debugPrint(
          'ExpenseRepository: local expense update queued '
          'because server_id is not available.',
        );

        return;
      }

      // Server update succeeded.
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
      // Keep the modification locally and queue it for retry.
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

    if (rows.isEmpty) return null;

    return rows.first["server_id"] as int?;
  }

  Future<void> deleteExpense(int id) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final serverId = await getServerExpenseId(id);

    try {
      // If the expense exists on the server, delete it there first.
      if (serverId != null) {
        await ApiService.deleteExpense(serverId);
      }

      // Remove the local record after successful server deletion.
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
      // If server deletion failed, remove it locally and queue the
      // deletion for automatic synchronization.
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

  Future<List<Map<String, dynamic>>> getExpensesFromLocal() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final rows = await database.query(
      "expenses",
      where: "owner_id = ? AND is_deleted = 0",
      whereArgs: [ownerId],
      orderBy: "expense_date DESC",
    );

    return rows.map((row) => Map<String, dynamic>.from(row)).toList();
  }
}
