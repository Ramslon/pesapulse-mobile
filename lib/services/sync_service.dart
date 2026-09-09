import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

import 'sync_status.dart';
import 'sync_events.dart';
import 'session_service.dart';

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

  static final SyncService instance = SyncService._();

  // ---------------------------------------------------------------------------
  // REPOSITORIES
  // ---------------------------------------------------------------------------

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

  final DatabaseHelper db = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // CONNECTIVITY LISTENER
  // ---------------------------------------------------------------------------

  Stream<List<ConnectivityResult>>? _stream;

  bool _isListening = false;

  // ---------------------------------------------------------------------------
  // SYNC REQUEST STATE
  // ---------------------------------------------------------------------------

  bool _syncRequestScheduled = false;

  bool _syncAgainRequested = false;

  // ---------------------------------------------------------------------------
  // CHECK CURRENT NETWORK CONNECTIVITY
  // ---------------------------------------------------------------------------

  Future<bool> _hasNetworkConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();

      return results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );
    } catch (e) {
      debugPrint('SyncService: failed to check network connectivity: $e');

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // START AUTOMATIC SYNCHRONIZATION
  // ---------------------------------------------------------------------------

  Future<void> startListening() async {
    if (_isListening) {
      return;
    }

    final isGuest = await SessionService.isGuest();

    // Guest data is local-only.
    if (isGuest) {
      debugPrint(
        'SyncService: guest session detected. '
        'Automatic synchronization disabled.',
      );

      return;
    }

    _isListening = true;

    debugPrint('SyncService: automatic synchronization listener started.');

    // ----------------------------------------------------------
    // Process any operations that were pending before startup.
    // ----------------------------------------------------------

    await syncPendingOperations();

    // ----------------------------------------------------------
    // Listen for future connectivity changes.
    // ----------------------------------------------------------

    _stream ??= Connectivity().onConnectivityChanged;

    _stream!.listen((results) {
      final connected = results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (!connected) {
        return;
      }

      debugPrint('SyncService: network connection detected.');

      requestSync();
    });
  }

  // ---------------------------------------------------------------------------
  // REQUEST AUTOMATIC SYNCHRONIZATION
  // ---------------------------------------------------------------------------

  Future<void> requestSync() async {
    // ----------------------------------------------------------
    // Guest sessions never synchronize.
    // ----------------------------------------------------------

    final isGuest = await SessionService.isGuest();

    if (isGuest) {
      debugPrint(
        'SyncService: guest session. '
        'Ignoring automatic sync request.',
      );

      return;
    }

    // ----------------------------------------------------------
    // Do not even schedule synchronization while offline.
    // ----------------------------------------------------------

    final connected = await _hasNetworkConnection();

    if (!connected) {
      debugPrint(
        'SyncService: no network connection. '
        'Synchronization postponed.',
      );

      return;
    }

    // ----------------------------------------------------------
    // Avoid scheduling the same automatic sync multiple times.
    // ----------------------------------------------------------

    if (_syncRequestScheduled) {
      debugPrint('SyncService: sync request already scheduled.');

      return;
    }

    // ----------------------------------------------------------
    // If synchronization is already running, remember that
    // another pass is required after the current one finishes.
    // ----------------------------------------------------------

    if (SyncStatus.instance.isSyncing.value) {
      debugPrint(
        'SyncService: sync already running. '
        'Scheduling another sync after completion.',
      );

      _syncAgainRequested = true;

      return;
    }

    _syncRequestScheduled = true;

    try {
      // --------------------------------------------------------
      // Give the local database operation time to finish.
      // --------------------------------------------------------

      await Future.delayed(const Duration(milliseconds: 300));

      // --------------------------------------------------------
      // Network may have disappeared during the delay.
      // Check again before touching the queue.
      // --------------------------------------------------------

      final stillConnected = await _hasNetworkConnection();

      if (!stillConnected) {
        debugPrint(
          'SyncService: network unavailable after scheduling. '
          'Synchronization postponed.',
        );

        return;
      }

      await syncPendingOperations();
    } catch (e) {
      debugPrint('SyncService: automatic sync failed: $e');
    } finally {
      _syncRequestScheduled = false;
    }
  }
  // ---------------------------------------------------------------------------
  // SYNCHRONIZE PENDING OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> syncPendingOperations() async {
    // ----------------------------------------------------------
    // Prevent concurrent synchronization.
    // ----------------------------------------------------------

    if (SyncStatus.instance.isSyncing.value) {
      _syncAgainRequested = true;

      debugPrint(
        'SyncService: synchronization already running. '
        'Another pass requested.',
      );

      return;
    }

    // ----------------------------------------------------------
    // Guest protection.
    // ----------------------------------------------------------

    final isGuest = await SessionService.isGuest();

    if (isGuest) {
      await _refreshPendingCounter();

      debugPrint(
        'SyncService: guest session. '
        'No cloud synchronization performed.',
      );

      return;
    }

    // ----------------------------------------------------------
    // IMPORTANT:
    // Never process the synchronization queue while offline.
    //
    // The queue must remain untouched until connectivity returns.
    // ----------------------------------------------------------

    final connected = await _hasNetworkConnection();

    if (!connected) {
      debugPrint(
        'SyncService: no network connection. '
        'Pending operations will remain queued.',
      );

      await _refreshPendingCounter();

      return;
    }

    final database = await db.database;

    final ownerId = await SessionService.currentOwnerId();

    debugPrint('SyncService: authenticated ownerId=$ownerId');

    // ----------------------------------------------------------
    // Only process queue items belonging to the currently
    // authenticated owner.
    // ----------------------------------------------------------

    final queue = await database.query(
      "sync_queue",
      where: "owner_id=?",
      whereArgs: [ownerId],
      orderBy: "id ASC",
    );

    await _refreshPendingCounter();

    if (queue.isEmpty) {
      debugPrint('SyncService: no pending operations.');

      return;
    }

    debugPrint(
      'SyncService: ${queue.length} pending '
      'operation(s) found.',
    );

    SyncStatus.instance.setSyncing(true);

    bool dataChanged = false;

    try {
      // --------------------------------------------------------
      // FIFO processing.
      //
      // This is important for sequences such as:
      //
      // create goal
      // update progress
      // archive goal
      //
      // The create must happen first.
      // --------------------------------------------------------

      for (final item in queue) {
        try {
          debugPrint(
            'SyncService: processing queue item '
            'id=${item["id"]}, '
            'table=${item["table_name"]}, '
            'operation=${item["operation"]}',
          );

          await _processItem(item);

          // ----------------------------------------------------
          // Only SyncService removes successfully processed
          // queue entries.
          // ----------------------------------------------------

          await database.delete(
            "sync_queue",
            where: "id=? AND owner_id=?",
            whereArgs: [item["id"], ownerId],
          );

          dataChanged = true;

          await _refreshPendingCounter();

          debugPrint(
            'SyncService: queue item '
            'id=${item["id"]} synchronized successfully.',
          );
        } catch (e) {
          debugPrint(
            'SyncService: failed to process queue item '
            'id=${item["id"]}: $e',
          );

          // ----------------------------------------------------
          // Stop at the first failed operation.
          //
          // The failed item remains in the queue and will be
          // retried later.
          // ----------------------------------------------------

          break;
        }
      }

      await _refreshPendingCounter();

      // --------------------------------------------------------
      // Only refresh application caches when at least one
      // synchronization operation actually succeeded.
      // --------------------------------------------------------

      if (dataChanged) {
        debugPrint('SyncService: synchronized data detected.');

        await refreshOfflineCaches();

        await settingsRepository.saveLastSync(DateTime.now());

        // ------------------------------------------------------
        // ONE unified financial-data event.
        //
        // Do not dispatch additional dashboard/analytics/settings
        // events from this method.
        // ------------------------------------------------------

        SyncEvents.instance.notifyFinancialDataUpdated();

        debugPrint('SyncService: financial data update event dispatched.');
      }
    } finally {
      SyncStatus.instance.setSyncing(false);

      debugPrint('SyncService: synchronization finished.');

      // --------------------------------------------------------
      // If another operation was queued while synchronization
      // was running, perform another pass.
      // --------------------------------------------------------

      if (_syncAgainRequested) {
        _syncAgainRequested = false;

        debugPrint(
          'SyncService: another synchronization pass '
          'was requested.',
        );

        Future.microtask(() {
          requestSync();
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // PROCESS ONE QUEUE ITEM
  // ---------------------------------------------------------------------------

  Future<void> _processItem(Map<String, dynamic> item) async {
    final payload = jsonDecode(item["payload"]);

    final tableName = item["table_name"];

    final operation = item["operation"];

    switch (operation) {
      // =======================================================================
      // CREATE
      // =======================================================================

      case "create":
        // --------------------------------------------------------
        // GOAL CREATE
        // --------------------------------------------------------

        if (tableName == "goals") {
          await goalsRepository.syncOfflineGoal(
            localId: item["record_id"] as int,
            title: payload["title"],
            targetAmount: double.parse(payload["target_amount"].toString()),
            targetDate: payload["target_date"],
          );

          return;
        }

        // --------------------------------------------------------
        // EXPENSE CREATE
        // --------------------------------------------------------

        if (tableName == "expenses") {
          final existingServerId = await expenseRepository
              .findDuplicateOnServer(payload);

          if (existingServerId != null) {
            final database = await db.database;

            await database.update(
              "expenses",
              {"server_id": existingServerId, "is_synced": 1},
              where: "id=? AND owner_id=?",
              whereArgs: [
                item["record_id"],
                await SessionService.currentOwnerId(),
              ],
            );

            debugPrint(
              'SyncService: duplicate expense '
              'detected. Local record linked to '
              'server_id=$existingServerId.',
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

          return;
        }

        throw Exception('Unsupported create table: $tableName');

      // =======================================================================
      // UPDATE PROGRESS
      // =======================================================================

      case "update_progress":
        if (tableName != "goals") {
          throw Exception('Invalid update_progress table: $tableName');
        }

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

        return;

      // =======================================================================
      // ARCHIVE
      // =======================================================================

      case "archive":
        if (tableName != "goals") {
          throw Exception('Invalid archive table: $tableName');
        }

        final localId = item["record_id"] as int;

        final serverId = await _getServerGoalId(localId);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.archiveGoalOnline(serverId);

        final database = await db.database;

        await database.update(
          "goals",
          {"is_synced": 1, "is_archived": 1},
          where: "id=? AND owner_id=?",
          whereArgs: [localId, await SessionService.currentOwnerId()],
        );

        return;

      // =======================================================================
      // RESTORE
      // =======================================================================

      case "restore":
        if (tableName != "goals") {
          throw Exception('Invalid restore table: $tableName');
        }

        final localGoalId = item["record_id"] as int;

        final serverId = await _getServerGoalId(localGoalId);

        if (serverId == null) {
          throw Exception("Goal has no server id.");
        }

        await goalsRepository.restoreGoalOnline(localGoalId, serverId);

        final database = await db.database;

        // ------------------------------------------------------
        // Remove any obsolete pending delete for this goal.
        // ------------------------------------------------------

        await database.delete(
          "sync_queue",
          where:
              "owner_id=? "
              "AND table_name=? "
              "AND operation=? "
              "AND record_id=?",
          whereArgs: [
            await SessionService.currentOwnerId(),
            "goals",
            "delete",
            localGoalId,
          ],
        );

        return;

      // =======================================================================
      // EXPENSE UPDATE
      // =======================================================================

      case "update":
        if (tableName != "expenses") {
          throw Exception('Invalid update table: $tableName');
        }

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

        return;

      // =======================================================================
      // BUDGET UPSERT
      // =======================================================================

      case "upsert":
        if (tableName != "budget") {
          throw Exception('Invalid upsert table: $tableName');
        }

        final amount = double.parse(payload["amount"].toString());

        final clientId = payload["client_id"]?.toString();

        if (clientId == null || clientId.trim().isEmpty) {
          throw Exception("Budget sync failed: missing client_id.");
        }

        await budgetRepository.syncOfflineBudgetUpsert(
          amount: amount,
          clientId: clientId,
        );

        return;

      // =======================================================================
      // DELETE
      // =======================================================================

      case "delete":
        // --------------------------------------------------------
        // GOAL DELETE
        // --------------------------------------------------------

        if (tableName == "goals") {
          final localId = item["record_id"] as int;

          final serverId = await _getServerGoalId(localId);

          if (serverId == null) {
            throw Exception("Goal has no server id.");
          }

          await goalsRepository.deleteGoalOnline(serverId);

          final database = await db.database;

          await database.update(
            "goals",
            {"is_synced": 1},
            where: "id=? AND owner_id=?",
            whereArgs: [localId, await SessionService.currentOwnerId()],
          );

          return;
        }

        // --------------------------------------------------------
        // BUDGET DELETE
        // --------------------------------------------------------

        if (tableName == "budget") {
          await budgetRepository.syncOfflineBudgetDelete();

          return;
        }

        // --------------------------------------------------------
        // EXPENSE DELETE
        // --------------------------------------------------------

        if (tableName == "expenses") {
          final localId = item["record_id"] as int;

          final serverId = await expenseRepository.getServerExpenseId(localId);

          if (serverId == null) {
            // --------------------------------------------------
            // No server record exists.
            //
            // This can happen if a local expense was created
            // and deleted before synchronization.
            // --------------------------------------------------

            final database = await db.database;

            await database.delete(
              "expenses",
              where: "id=? AND owner_id=?",
              whereArgs: [localId, await SessionService.currentOwnerId()],
            );

            debugPrint(
              'SyncService: expense had no server id. '
              'Removed local record.',
            );

            return;
          }

          await expenseRepository.syncOfflineExpenseDelete(
            localId: localId,
            serverId: serverId,
          );

          return;
        }

        throw Exception('Unsupported delete table: $tableName');

      // =======================================================================
      // SETTINGS / PREFERENCES
      // =======================================================================

      case "preferences":
        if (tableName != "settings") {
          throw Exception('Invalid preferences table: $tableName');
        }

        await settingsRepository.updatePreferences(payload);

        return;

      default:
        throw Exception('Unsupported sync operation: $operation');
    }
  }

  // ---------------------------------------------------------------------------
  // GET SERVER GOAL ID
  // ---------------------------------------------------------------------------

  Future<int?> _getServerGoalId(int localId) async {
    final database = await db.database;

    final ownerId = await SessionService.currentOwnerId();

    final rows = await database.query(
      "goals",
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
  // PENDING OPERATION COUNT
  // ---------------------------------------------------------------------------

  Future<int> pendingOperationsCount() async {
    final database = await db.database;

    final isGuest = await SessionService.isGuest();

    if (isGuest) {
      return 0;
    }

    final ownerId = await SessionService.currentOwnerId();

    final result = await database.rawQuery(
      """
      SELECT COUNT(*) as total
      FROM sync_queue
      WHERE owner_id=?
      """,
      [ownerId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // UPDATE PENDING COUNTER
  // ---------------------------------------------------------------------------

  Future<int> getPendingChanges() async {
    final database = await db.database;

    final isGuest = await SessionService.isGuest();

    if (isGuest) {
      SyncStatus.instance.updatePending(0);

      return 0;
    }

    final ownerId = await SessionService.currentOwnerId();

    final result = await database.rawQuery(
      """
      SELECT COUNT(*)
      FROM sync_queue
      WHERE owner_id=?
      """,
      [ownerId],
    );

    final count = Sqflite.firstIntValue(result) ?? 0;

    SyncStatus.instance.updatePending(count);

    return count;
  }

  Future<void> _refreshPendingCounter() async {
    await getPendingChanges();
  }

  // ---------------------------------------------------------------------------
  // REFRESH LOCAL / SERVER CACHES
  // ---------------------------------------------------------------------------

  Future<void> refreshOfflineCaches({Set<String>? tables}) async {
    try {
      final isGuest = await SessionService.isGuest();

      // ==========================================================
      // GUEST
      // ==========================================================

      if (isGuest) {
        if (tables == null || tables.contains("goals")) {
          await goalsRepository.getCachedGoals();

          await goalAnalyticsRepository.getCachedGoalAnalytics();

          await goalDeadlineRepository.getCachedUpcomingDeadlines();
        }

        if (tables == null || tables.contains("insights")) {
          await insightsRepository.getInsights(useCache: true);
        }

        return;
      }

      // ==========================================================
      // AUTHENTICATED USER
      // ==========================================================

      // ----------------------------------------------------------
      // Dashboard
      // ----------------------------------------------------------

      if (tables == null || tables.contains("dashboard")) {
        try {
          await dashboardRepository.refreshDashboard();

          debugPrint('SyncService: dashboard cache refreshed.');
        } catch (e) {
          debugPrint('SyncService: dashboard cache refresh failed: $e');
        }
      }

      // ----------------------------------------------------------
      // Financial insights
      // ----------------------------------------------------------

      if (tables == null || tables.contains("insights")) {
        try {
          await insightsRepository.getInsights();

          debugPrint('SyncService: financial insights cache refreshed.');
        } catch (e) {
          debugPrint('SyncService: financial insights refresh failed: $e');
        }
      }

      // ----------------------------------------------------------
      // Goals
      // ----------------------------------------------------------

      if (tables == null || tables.contains("goals")) {
        try {
          await goalsRepository.getCachedGoals();

          await goalAnalyticsRepository.getCachedGoalAnalytics();

          await goalDeadlineRepository.getCachedUpcomingDeadlines();

          debugPrint('SyncService: goals caches refreshed.');
        } catch (e) {
          debugPrint('SyncService: goals cache refresh failed: $e');
        }
      }
    } catch (e) {
      debugPrint('SyncService: failed to refresh offline caches: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CLEANUP GUEST QUEUE
  // ---------------------------------------------------------------------------

  Future<void> cleanupGuestQueue() async {
    final database = await db.database;

    // ----------------------------------------------------------
    // Only remove guest expense operations whose local record
    // no longer has a server ID.
    // ----------------------------------------------------------

    await database.delete(
      "sync_queue",
      where:
          "owner_id=? "
          "AND table_name=? "
          "AND record_id NOT IN "
          "(SELECT id FROM expenses "
          "WHERE server_id IS NOT NULL)",
      whereArgs: ["guest", "expenses"],
    );
  }
}
