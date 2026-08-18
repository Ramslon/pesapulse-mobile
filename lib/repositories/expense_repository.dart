import '../services/api_services.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../services/sync_service.dart';
import 'base_repository.dart';

class ExpenseRepository extends BaseRepository {
  Map<String, dynamic> _expenseToLocal(
    Map<String, dynamic> expense,
    String ownerId,
  ) {
    return {
      "id": expense["id"],
      "server_id": expense["id"],
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

  Future<void> createExpense({
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final expense = {
      "owner_id": ownerId,
      "title": title,
      "amount": amount,
      "category": category,
      "expense_date": expenseDate,
      "description": description,
    };

    try {
      // Deduplication check
      final existingServerId = await findDuplicateOnServer(expense);

      if (existingServerId != null) {
        expense["id"] = existingServerId.toString();
        expense["server_id"] = existingServerId.toString();

        expense["is_synced"] = "1";
        expense["is_deleted"] = "0";

        await database.insert(
          "expenses",
          expense,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return;
      }

      // No duplicate found → create normally
      final response = await ApiService.addExpense(
        title,
        amount,
        category,
        expenseDate,
        description,
      );

      expense["id"] = response["id"];
      expense["server_id"] = response["id"];
      expense["is_synced"] = "1";
      expense["is_deleted"] = "0";

      await database.insert(
        "expenses",
        expense,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {
      // Offline fallback
      final id = await database.insert("expenses", expense);
      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "expenses",
        "record_id": id,
        "operation": "create",
        "payload": jsonEncode(expense),
      });
      await SyncService.instance.getPendingChanges();
    }
  }

  Future<void> syncOfflineExpense({
    required int localId,
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    // Deduplication check
    final existingServerId = await findDuplicateOnServer({
      "title": title,
      "amount": amount,
      "category": category,
      "expense_date": expenseDate,
    });

    if (existingServerId != null) {
      // Update local record with serverId instead of creating duplicate
      await database.update(
        "expenses",
        {"owner_id": ownerId, "server_id": existingServerId, "is_synced": 1},
        where: "id=? AND owner_id=?",
        whereArgs: [localId, ownerId],
      );
      return;
    }

    // No duplicate found → create normally
    final response = await ApiService.addExpense(
      title,
      amount,
      category,
      expenseDate,
      description,
    );

    await database.update(
      "expenses",
      {
        "owner_id": ownerId,
        "server_id": response["id"],
        "title": response["title"],
        "amount": response["amount"],
        "category": response["category"],
        "expense_date": response["expense_date"],
        "description": response["description"] ?? "",
        "updated_at": response["updated_at"],
        "is_synced": 1,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
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

    final expense = {
      "title": title,
      "amount": amount,
      "category": category,
      "expense_date": expenseDate,
      "description": description,
    };

    try {
      await ApiService.updateExpense(
        id,
        title,
        amount,
        category,
        expenseDate,
        description,
      );

      await database.update(
        "expenses",
        expense,
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );
    } catch (_) {
      await database.update(
        "expenses",
        expense,
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );

      await database.insert("sync_queue", {
        "owner_id": ownerId,
        "table_name": "expenses",
        "record_id": id,
        "operation": "update",
        "payload": jsonEncode(expense),
      });

      await SyncService.instance.getPendingChanges();
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
        "amount": amount,
        "category": category,
        "expense_date": expenseDate,
        "description": description,
        "updated_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
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

    try {
      await ApiService.deleteExpense(id);

      await database.delete(
        "expenses",
        where: "id=? AND owner_id=?",
        whereArgs: [id, ownerId],
      );
    } catch (_) {
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
        "payload": "{}",
      });
      await SyncService.instance.getPendingChanges();
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
  }

  Future<List<Map<String, dynamic>>> getExpensesFromServer({
    String? title,
    String? amount,
    String? category,
    String? expenseDate,
  }) async {
    final response = await ApiService.getExpenses(page: 1);
    final allExpenses = List<Map<String, dynamic>>.from(response["data"]);

    return allExpenses.where((exp) {
      return (title == null || exp["title"] == title) &&
          (amount == null || exp["amount"].toString() == amount) &&
          (category == null || exp["category"] == category) &&
          (expenseDate == null || exp["expense_date"] == expenseDate);
    }).toList();
  }

  Future<int?> findDuplicateOnServer(Map<String, dynamic> payload) async {
    final existing = await getExpensesFromServer(
      title: payload["title"],
      amount: payload["amount"].toString(),
      category: payload["category"],
      expenseDate: payload["expense_date"],
    );

    if (existing.isNotEmpty) {
      return existing.first["id"] as int?;
    }
    return null;
  }
}
