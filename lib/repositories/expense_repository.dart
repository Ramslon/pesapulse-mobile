import '../database/database_helper.dart';
import '../services/api_services.dart';
import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../services/sync_service.dart';

class ExpenseRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  /// Get expenses
  Future<Map<String, dynamic>> getExpenses({int page = 1}) async {
    try {
      final response = await ApiService.getExpenses(page: page);

      final database = await db.database;

      if (page == 1) {
        await database.delete("expenses");
      }

      for (final expense in response["data"]) {
        await database.insert(
          "expenses",
          expense,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await SyncService.instance.getPendingChanges();

      return response;
    } catch (_) {
      final database = await db.database;

      final cached = await database.query(
        "expenses",
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
    final database = await db.database;

    final expense = {
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

      await database.insert("expenses", expense);
    } catch (_) {
      // Offline

      final id = await database.insert("expenses", expense);

      await database.insert("sync_queue", {
        "table_name": "expenses",
        "record_id": id,
        "action": "create",
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
        where: "id=?",
        whereArgs: [id],
      );
    } catch (_) {
      await database.update(
        "expenses",
        expense,
        where: "id=?",
        whereArgs: [id],
      );

      await database.insert("sync_queue", {
        "table_name": "expenses",
        "record_id": id,
        "action": "update",
        "payload": jsonEncode(expense),
      });

      await SyncService.instance.getPendingChanges();
    }
  }

  Future<void> deleteExpense(int id) async {
    final database = await db.database;

    try {
      await ApiService.deleteExpense(id);

      await database.delete("expenses", where: "id=?", whereArgs: [id]);
    } catch (_) {
      await database.delete("expenses", where: "id=?", whereArgs: [id]);

      await database.insert("sync_queue", {
        "table_name": "expenses",
        "record_id": id,
        "action": "delete",
        "payload": "{}",
      });
      await SyncService.instance.getPendingChanges();
    }
  }
}
