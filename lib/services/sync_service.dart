import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../database/database_helper.dart';
import 'api_services.dart';

class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  final DatabaseHelper db = DatabaseHelper.instance;

  Stream<List<ConnectivityResult>>? _stream;

  void startListening() {
    syncPendingOperations();

    _stream ??= Connectivity().onConnectivityChanged;

    _stream!.listen((results) {
      final connected = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );

      if (connected) {
        syncPendingOperations();
      }
    });
  }

  Future<void> syncPendingOperations() async {
    final database = await db.database;

    final queue = await database.query("sync_queue", orderBy: "id ASC");

    for (final item in queue) {
      try {
        await _processItem(item);

        await database.delete(
          "sync_queue",
          where: "id=?",
          whereArgs: [item["id"]],
        );
      } catch (_) {
        break;
      }
    }
  }

  Future<void> _processItem(Map<String, dynamic> item) async {
    final payload = jsonDecode(item["payload"]);

    switch (item["action"]) {
      case "create":
        await ApiService.addExpense(
          payload["title"],
          payload["amount"].toString(),
          payload["category"],
          payload["expense_date"],
          payload["description"] ?? "",
        );

        break;

      case "update":
        await ApiService.updateExpense(
          item["record_id"],
          payload["title"],
          payload["amount"].toString(),
          payload["category"],
          payload["expense_date"],
          payload["description"] ?? "",
        );

        break;

      case "delete":
        await ApiService.deleteExpense(item["record_id"]);

        break;
    }
  }

  Future<int> pendingOperationsCount() async {
    final database = await db.database;

    final result = await database.rawQuery(
      "SELECT COUNT(*) as total FROM sync_queue",
    );

    return result.first["total"] as int;
  }
}
