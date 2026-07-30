import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

import 'sync_status.dart';
import 'sync_events.dart';
import '../repositories/settings_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/financial_insights_repository.dart';
import '../repositories/goals_repository.dart';
import '../repositories/goal_analytics_repository.dart';
import '../repositories/goal_deadline_repository.dart';
import '../repositories/goals_forecast_repository.dart';
import '../repositories/goal_insights_repository.dart';
import '../repositories/expense_repository.dart';
import '../repositories/budget_repository.dart';

class SyncService {
  SyncService._();

  final DashboardRepository dashboardRepository = DashboardRepository();

  final FinancialInsightsRepository insightsRepository =
      FinancialInsightsRepository();

  final GoalsRepository goalsRepository = GoalsRepository();

  final GoalAnalyticsRepository goalAnalyticsRepository =
      GoalAnalyticsRepository();

  final GoalDeadlineRepository goalDeadlineRepository =
      GoalDeadlineRepository();

  final GoalForecastRepository goalForecastRepository =
      GoalForecastRepository();

  final GoalInsightsRepository goalInsightsRepository =
      GoalInsightsRepository();

  final SettingsRepository settingsRepository = SettingsRepository();

  final ExpenseRepository expenseRepository = ExpenseRepository();

  final BudgetRepository budgetRepository = BudgetRepository();

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

    await settingsRepository.saveLastSync(DateTime.now());
  }

  Future<void> _processItem(Map<String, dynamic> item) async {
    final payload = jsonDecode(item["payload"]);

    switch (item["operation"]) {
      case "create":
        if (item["table_name"] == "goals") {
          await goalsRepository.syncOfflineGoal(
            localId: item["record_id"] as int,
            title: payload["title"],
            targetAmount: double.parse(payload["target_amount"].toString()),
            targetDate: payload["target_date"],
          );

          return;
        }
        await expenseRepository.syncOfflineExpense(
          localId: item["record_id"] as int,
          title: payload["title"],
          amount: payload["amount"].toString(),
          category: payload["category"],
          expenseDate: payload["expense_date"],
          description: payload["description"] ?? "",
        );

        break;

      case "update_progress":
        final serverId = await _getServerGoalId(item["record_id"] as int);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.updateGoalProgressOnline(
          item["record_id"] as int,
          serverId,
          double.parse(payload["amount"].toString()),
        );
        final database = await db.database;

        await database.update(
          "goals",
          {"is_synced": 1},
          where: "id=?",
          whereArgs: [item["record_id"]],
        );
        break;

      case "archive":
        final serverId = await _getServerGoalId(item["record_id"] as int);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.archiveGoalOnline(serverId);
        final database = await db.database;

        await database.update(
          "goals",
          {"is_synced": 1},
          where: "id=?",
          whereArgs: [item["record_id"]],
        );
        break;

      case "restore":
        final serverId = await _getServerGoalId(item["record_id"] as int);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.restoreGoalOnline(serverId);
        final database = await db.database;

        await database.update(
          "goals",
          {"is_synced": 1, "is_deleted": 0, "is_archived": 0},
          where: "id=?",
          whereArgs: [item["record_id"]],
        );
        // Remove any pending delete for this goal
        await database.delete(
          "sync_queue",
          where: "table_name=? AND operation=? AND record_id=?",
          whereArgs: ["goals", "delete", item["record_id"]],
        );
        break;

      case "update":
        final localId = item["record_id"] as int;
        final serverId = await expenseRepository.getServerExpenseId(localId);

        if (serverId == null) {
          throw Exception("Expense has no server id.");
        }

        await expenseRepository.syncOfflineExpenseUpdate(
          localId: localId,
          serverId: serverId,
          title: payload["title"],
          amount: payload["amount"].toString(),
          category: payload["category"],
          expenseDate: payload["expense_date"],
          description: payload["description"] ?? "",
        );

        break;

      case "upsert":
        if (item["table_name"] == "budget") {
          final payload = jsonDecode(item["payload"]);

          await budgetRepository.syncOfflineBudgetUpsert(
            double.parse(payload["amount"].toString()),
          );
        }
        break;

      case "delete":
        if (item["table_name"] == "goals") {
          final serverId = await _getServerGoalId(item["record_id"] as int);

          if (serverId == null) {
            throw Exception("Goal has no server id.");
          }

          await goalsRepository.deleteGoalOnline(serverId);

          final database = await db.database;
          await database.update(
            "goals",
            {"is_synced": 1},
            where: "id=?",
            whereArgs: [item["record_id"]],
          );
        } else if (item["table_name"] == "budget") {
          await budgetRepository.syncOfflineBudgetDelete();
        } else {
          final localId = item["record_id"] as int;

          final serverId = await expenseRepository.getServerExpenseId(localId);

          if (serverId == null) {
            throw Exception("Expense has no server id.");
          }

          await expenseRepository.syncOfflineExpenseDelete(
            localId: localId,
            serverId: serverId,
          );
        }
        break;

      case "preferences":
        final payloadMap = jsonDecode(item["payload"]);

        await settingsRepository.updatePreferences(payloadMap);

        break;
    }
  }

  Future<int?> _getServerGoalId(int localId) async {
    final database = await db.database;

    final rows = await database.query(
      "goals",
      columns: ["server_id"],
      where: "id=?",
      whereArgs: [localId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    return rows.first["server_id"] as int?;
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

      await goalsRepository.getGoals();

      await goalAnalyticsRepository.getGoalAnalytics();

      await goalDeadlineRepository.getUpcomingDeadlines();

      SyncEvents.instance.notifyGoalsUpdated();
    } catch (_) {}
  }
}
