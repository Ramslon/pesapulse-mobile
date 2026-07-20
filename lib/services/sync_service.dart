import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'api_services.dart';
import 'sync_status.dart';
import '../services/settings_service.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/financial_insights_repository.dart';

class SyncService {
  SyncService._();

  final DashboardRepository dashboardRepository = DashboardRepository();

  final FinancialInsightsRepository insightsRepository =
      FinancialInsightsRepository();

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

        await _refreshPendingCounter();
      } catch (_) {
        break;
      }
    }
    await _refreshPendingCounter();

    await refreshOfflineCaches();

    await SettingsService.saveLastSync(DateTime.now());
  }

  Future<void> _processItem(Map<String, dynamic> item) async {
    final payload = jsonDecode(item["payload"]);

    switch (item["operation"]) {
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

      case "upsert":
        if (item["table_name"] == "budget") {
          final payload = jsonDecode(item["payload"]);

          await ApiService.setBudget(
            double.parse(payload["amount"].toString()),
          );
        }
        break;

      case "delete":
        if (item["table_name"] == "budget") {
          await ApiService.deleteBudget();
        } else {
          await ApiService.deleteExpense(item["record_id"]);
        }
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

  Future<int> getPendingChanges() async {
    final database = await db.database;

    final count =
        Sqflite.firstIntValue(
          await database.rawQuery("SELECT COUNT(*) FROM sync_queue"),
        ) ??
        0;

    SyncStatus.instance.updatePending(count);

    return count;
  }

  Future<void> _refreshPendingCounter() async {
    await getPendingChanges();
  }

  Future<void> refreshOfflineCaches() async {
    try {
      await dashboardRepository.getDashboard();

      await insightsRepository.getInsights();
    } catch (_) {}
  }
}
