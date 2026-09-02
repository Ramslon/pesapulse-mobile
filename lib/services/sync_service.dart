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
    if (SyncStatus.instance.isSyncing.value) {
      return;
    }

    final database = await db.database;

    final queue = await database.query("sync_queue", orderBy: "id ASC");

    await _refreshPendingCounter();

    // Don't show the spinner when there is nothing to sync.
    if (queue.isEmpty) {
      return;
    }

    SyncStatus.instance.setSyncing(true);

    try {
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
    } finally {
      SyncStatus.instance.setSyncing(false);
    }
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

        // Deduplication check
        final existingServerId = await expenseRepository.findDuplicateOnServer(
          payload,
        );

        if (existingServerId != null) {
          // Update local record with serverId instead of creating duplicate
          final database = await db.database;
          await database.update(
            "expenses",
            {"server_id": existingServerId, "is_synced": 1},
            where: "id=?",
            whereArgs: [item["record_id"]],
          );

          // Remove the queue item since it's now linked
          await database.delete(
            "sync_queue",
            where: "id=?",
            whereArgs: [item["id"]],
          );

          return;
        }

        // No duplicate found → create normally
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
        final localId = item["record_id"] as int;

        final serverId = await _getServerGoalId(localId);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.updateGoalProgressOnline(
          localId,
          serverId,
          double.parse(payload["amount"].toString()),
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
          {"is_synced": 1, "is_archived": 1},
          where: "id=?",
          whereArgs: [item["record_id"]],
        );
        break;

      case "restore":
        final localGoalId = item["record_id"] as int;

        final serverId = await _getServerGoalId(localGoalId);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.restoreGoalOnline(localGoalId, serverId);

        final database = await db.database;

        // Remove any pending delete for this goal.
        await database.delete(
          "sync_queue",
          where: "table_name=? AND operation=? AND record_id=?",
          whereArgs: ["goals", "delete", localGoalId],
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
            // Goals must have serverId, so fail
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
          final database = await db.database;

          if (serverId == null) {
            // Guest record → just clear from local DB and queue
            await database.delete(
              "expenses",
              where: "id=?",
              whereArgs: [localId],
            );
            await database.delete(
              "sync_queue",
              where: "id=?",
              whereArgs: [item["id"]],
            );
            //  Do not throw, just return
            return;
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

  Future<void> refreshOfflineCaches({Set<String>? tables}) async {
    try {
      if (tables == null || tables.contains("dashboard")) {
        await dashboardRepository.refreshDashboard();
      }
      if (tables == null || tables.contains("insights")) {
        await insightsRepository.getInsights();
      }
      if (tables == null || tables.contains("goals")) {
        await goalsRepository.getGoals();
        await goalAnalyticsRepository.getGoalAnalytics();
        await goalDeadlineRepository.getUpcomingDeadlines();
        SyncEvents.instance.notifyGoalsUpdated();
      }
    } catch (_) {}
  }

  Future<void> cleanupGuestQueue() async {
    final database = await db.database;

    // Remove expense operations with no server_id
    await database.delete(
      "sync_queue",
      where:
          "table_name=? AND record_id NOT IN (SELECT id FROM expenses WHERE server_id IS NOT NULL)",
      whereArgs: ["expenses"],
    );

    // You can extend this for other tables if needed
  }
}
