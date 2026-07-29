import '../database/database_helper.dart';
import '../services/api_services.dart';
import '../services/session_service.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../services/sync_service.dart';

class ExpenseRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<String> _ownerId() async {
    return await SessionService.currentOwnerId();
  }

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
    final ownerId = await _ownerId();
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

  Future<void> addExpense({
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await _ownerId();
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
      // Offline

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

  Future<void> updateExpense({
    required int id,
    required String title,
    required String amount,
    required String category,
    required String expenseDate,
    required String description,
  }) async {
    final ownerId = await _ownerId();
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

  Future<void> deleteExpense(int id) async {
    final ownerId = await _ownerId();
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
}
