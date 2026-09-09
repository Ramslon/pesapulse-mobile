import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../services/api_services.dart';
import '../services/sync_service.dart';
import '../services/sync_events.dart';
import '../exceptions/rate_limit_exception.dart';

class GoalsRepository extends BaseRepository {
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  // ============================================================
  // CACHE-FIRST GOAL LOADING
  // ============================================================

  /// Returns active goals directly from SQLite.
  ///
  /// This method NEVER contacts the API.
  ///
  /// Used during screen initialization so the UI can render
  /// immediately from locally available data.
  Future<List<Goal>> getCachedGoals() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final rows = await database.query(
      "goals",
      where: """
        owner_id=?
        AND is_archived=?
        AND is_deleted=?
      """,
      whereArgs: [ownerId, 0, 0],
      orderBy: "updated_at DESC",
    );

    return rows.map(Goal.fromMap).toList();
  }

  /// Returns archived goals directly from SQLite.
  ///
  /// This method NEVER contacts the API.
  Future<List<Map<String, dynamic>>> getCachedArchivedGoals() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    return await database.query(
      "goals",
      where: """
        owner_id=?
        AND is_archived=?
        AND is_deleted=?
      """,
      whereArgs: [ownerId, 1, 0],
      orderBy: "updated_at DESC",
    );
  }

  /// Refreshes goals from Laravel and updates the local SQLite cache.
  ///
  /// Important:
  /// - Synced local records may be updated by the server.
  /// - Unsynced local records are NEVER overwritten.
  /// - Stale synced server records can be removed.
  /// - Offline-created/local records remain untouched.
  Future<List<Goal>> refreshGoals() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      // --------------------------------------------------------
      // Refresh active goals
      // --------------------------------------------------------

      debugPrint('Goals repository: requesting active goals...');

      final activeGoals = await ApiService.getGoals();

      debugPrint('Goals repository: active goals completed.');

      // --------------------------------------------------------
      // Refresh archived goals
      // --------------------------------------------------------

      debugPrint('Goals repository: requesting archived goals...');

      final archivedGoals = await ApiService.getArchivedGoals();

      debugPrint('Goals repository: archived goals completed.');

      // --------------------------------------------------------
      // Combine server goals
      // --------------------------------------------------------

      final allServerGoals = [...activeGoals, ...archivedGoals];

      debugPrint(
        'Goals repository: '
        'active=${activeGoals.length}, '
        'archived=${archivedGoals.length}, '
        'total=${allServerGoals.length}',
      );

      await database.transaction((txn) async {
        final serverIds = allServerGoals
            .map((goal) => goal["id"])
            .where((id) => id != null)
            .toList();

        // --------------------------------------------------------
        // Remove stale SERVER-SYNCED records only.
        //
        // Never remove:
        // - offline-created goals
        // - locally modified unsynced goals
        // --------------------------------------------------------

        if (serverIds.isNotEmpty) {
          await txn.delete(
            "goals",
            where:
                """
            owner_id=?
            AND server_id IS NOT NULL
            AND is_synced=1
            AND server_id NOT IN (
              ${List.filled(serverIds.length, "?").join(",")}
            )
          """,
            whereArgs: [ownerId, ...serverIds],
          );
        }

        // --------------------------------------------------------
        // Insert/update server goals
        // --------------------------------------------------------

        for (final goal in allServerGoals) {
          final serverId = goal["id"];

          if (serverId == null) {
            continue;
          }

          final existing = await txn.query(
            "goals",
            where: "server_id=? AND owner_id=?",
            whereArgs: [serverId, ownerId],
            limit: 1,
          );

          final isArchived = goal["is_archived"] == true ? 1 : 0;

          final values = {
            "server_id": serverId,
            "owner_id": ownerId,
            "title": goal["title"],
            "target_amount": _toDouble(goal["target_amount"]),
            "target_date": goal["target_date"],
            "saved_amount": _toDouble(goal["saved_amount"]),
            "achievement": goal["achievement"] ?? "",
            "completed_percentage": _toDouble(goal["completed_percentage"]),
            "created_at":
                goal["created_at"] ?? DateTime.now().toIso8601String(),
            "completed_at": goal["completed_at"],
            "updated_at":
                goal["updated_at"] ?? DateTime.now().toIso8601String(),
            "is_archived": isArchived,
            "is_synced": 1,
            "is_deleted": 0,
          };

          if (existing.isNotEmpty) {
            final localGoal = existing.first;

            final localIsSynced = (localGoal["is_synced"] as int? ?? 1) == 1;

            // ----------------------------------------------------
            // CRITICAL:
            //
            // Never overwrite a locally modified/unsynced goal.
            // The sync queue must get a chance to push that
            // local change to the server first.
            // ----------------------------------------------------

            if (!localIsSynced) {
              continue;
            }

            await txn.update(
              "goals",
              values,
              where: "server_id=? AND owner_id=?",
              whereArgs: [serverId, ownerId],
            );
          } else {
            await txn.insert(
              "goals",
              values,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });

      return await getCachedGoals();
    } catch (e) {
      // The refresh failed.
      //
      // Do NOT hide the exception here.
      //
      // The controller/service can decide whether this is:
      // - rate limiting
      // - offline
      // - timeout
      // - another API failure

      rethrow;
    }
  }

  // ============================================================
  // BACKWARD-COMPATIBLE LOCAL METHODS
  // ============================================================

  /// Returns active goals from SQLite.
  ///
  /// Kept for existing callers that already expect a local-only
  /// active-goals query.
  Future<List<Goal>> getActiveGoals() async {
    return getCachedGoals();
  }

  /// Returns archived goals from SQLite.
  ///
  /// This is intentionally cache-only.
  Future<List<Map<String, dynamic>>> getArchivedGoals() async {
    return getCachedArchivedGoals();
  }

  // ============================================================
  // OFFLINE CREATE
  // ============================================================

  Future<void> createGoalOffline({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    const uuid = Uuid();

    final now = DateTime.now().toIso8601String();

    final localId = -DateTime.now().millisecondsSinceEpoch;

    // ------------------------------------------------------------
    // DUPLICATE CHECK
    // ------------------------------------------------------------

    final existing = await database.query(
      "goals",
      where: """
      owner_id=?
      AND LOWER(title)=LOWER(?)
      AND target_amount=?
      AND is_deleted=0
      AND is_archived=0
    """,
      whereArgs: [ownerId, title.trim(), targetAmount],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception("A goal with this title already exists.");
    }

    // ------------------------------------------------------------
    // CHECK FOR ALREADY QUEUED CREATE
    // ------------------------------------------------------------

    final queued = await database.query(
      "sync_queue",
      where: """
      owner_id=?
      AND table_name=?
      AND operation=?
    """,
      whereArgs: [ownerId, "goals", "create"],
    );

    final duplicateQueued = queued.any((row) {
      final payload = jsonDecode(row["payload"] as String);

      return payload["title"].toString().trim().toLowerCase() ==
          title.trim().toLowerCase();
    });

    if (duplicateQueued) {
      throw Exception("This goal is already waiting to be synced.");
    }

    // ------------------------------------------------------------
    // GENERATE STABLE CLIENT ID
    // ------------------------------------------------------------

    final clientId = uuid.v4();

    // ------------------------------------------------------------
    // SYNC QUEUE PAYLOAD
    // ------------------------------------------------------------

    final payload = {
      "client_id": clientId,
      "owner_id": ownerId,
      "title": title.trim(),
      "target_amount": targetAmount,
      "target_date": targetDate,
    };

    // ------------------------------------------------------------
    // LOCAL GOAL
    // ------------------------------------------------------------

    await database.insert("goals", {
      "id": localId,
      "client_id": clientId,
      "owner_id": ownerId,
      "server_id": null,
      "title": title.trim(),
      "target_amount": targetAmount,
      "target_date": targetDate,
      "saved_amount": 0,
      "achievement": "",
      "completed_percentage": 0,
      "created_at": now,
      "completed_at": null,
      "updated_at": now,
      "is_synced": 0,
      "is_deleted": 0,
      "is_archived": 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // ------------------------------------------------------------
    // QUEUE CREATE OPERATION
    // ------------------------------------------------------------

    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "create",
      "record_id": localId,
      "payload": jsonEncode(payload),
      "created_at": now,
    });

    await SyncService.instance.getPendingChanges();

    SyncEvents.instance.notifyGoalDataUpdated();

    // Guests remain local until authentication.
    if (ownerId != "guest") {
      await SyncService.instance.requestSync();
    }
  }

  // ============================================================
  // ONLINE CREATE
  // ============================================================

  Future<void> createGoalOnline({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final goal = await ApiService.createGoal(
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
    );

    await database.insert("goals", {
      "server_id": goal["id"],
      "client_id": goal["client_id"],
      "owner_id": ownerId,
      "title": goal["title"],
      "target_amount": goal["target_amount"],
      "target_date": goal["target_date"],
      "saved_amount": goal["saved_amount"] ?? 0,
      "achievement": goal["achievement"] ?? "",
      "completed_percentage": goal["completed_percentage"] ?? 0,
      "created_at": goal["created_at"],
      "completed_at": goal["completed_at"],
      "updated_at": goal["updated_at"],
      "is_synced": 1,
      "is_deleted": 0,
      "is_archived": 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    SyncEvents.instance.notifyGoalDataUpdated();
  }

  // ============================================================
  // SYNC OFFLINE CREATE
  // ============================================================

  Future<void> syncOfflineGoal({
    required int localId,
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final goal = await ApiService.createGoal(
      title: title,
      targetAmount: targetAmount,
      targetDate: targetDate,
    );

    await database.update(
      "goals",
      {
        "server_id": goal["id"],
        "client_id": goal["client_id"],
        "title": goal["title"],
        "target_amount": goal["target_amount"],
        "target_date": goal["target_date"],
        "saved_amount": goal["saved_amount"],
        "achievement": goal["achievement"] ?? "",
        "completed_percentage": goal["completed_percentage"] ?? 0,
        "created_at": goal["created_at"],
        "completed_at": goal["completed_at"],
        "updated_at": goal["updated_at"],
        "is_synced": 1,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [localId, ownerId],
    );
  }

  Future<void> createGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
    required bool isOnline,
  }) async {
    final ownerId = await this.ownerId;

    // ============================================================
    // GUEST MODE
    //
    // Guests ALWAYS save locally.
    //
    // This remains true even when the device is connected to
    // the internet. Guest data must never be sent to the API.
    // ============================================================
    if (ownerId == 'guest') {
      await createGoalOffline(
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );

      return;
    }

    // ============================================================
    // AUTHENTICATED USER
    // ============================================================
    if (isOnline) {
      await createGoalOnline(
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
    } else {
      await createGoalOffline(
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
      );
    }
  }

  // ============================================================
  // OFFLINE SAVINGS
  // ============================================================

  Future<Map<String, dynamic>> updateGoalProgressOffline(
    int goalId,
    double amount,
  ) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    final rows = await database.query(
      "goals",
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception("Goal not found");
    }

    final goal = rows.first;

    final currentSaved = _toDouble(goal["saved_amount"]);

    final targetAmount = _toDouble(goal["target_amount"]);

    final previousPercentage = targetAmount <= 0
        ? 0.0
        : ((currentSaved / targetAmount) * 100).clamp(0.0, 100.0);

    final newSaved = currentSaved + amount;

    final percentage = targetAmount <= 0
        ? 0.0
        : ((newSaved / targetAmount) * 100).clamp(0.0, 100.0);

    final completed = targetAmount > 0 && newSaved >= targetAmount;

    final completedAt = completed
        ? (goal["completed_at"]?.toString() ?? now)
        : null;

    await database.update(
      "goals",
      {
        "saved_amount": newSaved,
        "completed_percentage": percentage,
        "completed_at": completedAt,
        "updated_at": now,
        "is_synced": 0,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );

    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "update_progress",
      "record_id": goalId,
      "payload": jsonEncode({"amount": amount}),
      "created_at": now,
    });

    await SyncService.instance.getPendingChanges();

    SyncEvents.instance.notifyGoalDataUpdated();

    if (ownerId != "guest") {
      await SyncService.instance.requestSync();
    }

    Map<String, dynamic>? milestone;

    const milestones = [25, 50, 75, 100];

    for (final milestonePercentage in milestones) {
      if (previousPercentage < milestonePercentage &&
          percentage >= milestonePercentage) {
        milestone = {
          "percentage": milestonePercentage,
          "message": milestonePercentage == 100
              ? "Congratulations! You completed your goal."
              : "Great job! You've reached "
                    "$milestonePercentage% of your goal.",
        };

        break;
      }
    }

    return {
      "goal": {
        "id": goalId,
        "saved_amount": newSaved,
        "target_amount": targetAmount,
        "completed_percentage": percentage,
        "completed_at": completedAt,
      },
      "percentage": percentage,
      "milestone": milestone,
      "offline": true,
    };
  }

  // ============================================================
  // ONLINE SAVINGS
  // ============================================================

  Future<Map<String, dynamic>> updateGoalProgressOnline(
    int localGoalId,
    int serverGoalId,
    double amount,
  ) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final response = await ApiService.updateGoalProgress(serverGoalId, amount);

    final goal = Map<String, dynamic>.from(response["goal"]);

    final savedAmount = _toDouble(goal["saved_amount"]);

    final targetAmount = _toDouble(goal["target_amount"]);

    final percentage = _toDouble(response["percentage"]);

    final updatedAt = goal["updated_at"]?.toString();

    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "saved_amount": savedAmount,
        "updated_at": updatedAt,
        "completed_percentage": percentage,
        "completed_at": savedAmount >= targetAmount ? updatedAt : null,
        "is_synced": 1,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [localGoalId, ownerId],
    );

    SyncEvents.instance.notifyGoalDataUpdated();

    return response;
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<void> archiveGoalOffline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "is_archived": 1,
        "updated_at": now,
        "is_synced": 0,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );

    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "archive",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
    await SyncService.instance.getPendingChanges();

    SyncEvents.instance.notifyGoalDataUpdated();
    SyncEvents.instance.notifyArchivedUpdated();

    if (ownerId != "guest") {
      await SyncService.instance.requestSync();
    }
  }

  Future<void> archiveGoalOnline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.archiveGoal(goalId);

    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "is_archived": 1,
        "is_synced": 1,
        "updated_at": DateTime.now().toIso8601String(),
      },
      where: "server_id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );

    SyncEvents.instance.notifyGoalDataUpdated();
    SyncEvents.instance.notifyArchivedUpdated();
  }

  Future<void> archiveGoal(
    int localGoalId, {
    int? serverGoalId,
    required bool isOnline,
  }) async {
    if (isOnline && serverGoalId != null) {
      await archiveGoalOnline(serverGoalId);
    } else {
      await archiveGoalOffline(localGoalId);
    }
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<void> restoreGoalOffline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "is_archived": 0,
        "is_deleted": 0,
        "updated_at": now,
        "is_synced": 0,
      },
      where: "owner_id=? AND id=?",
      whereArgs: [ownerId, goalId],
    );

    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "restore",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
    await SyncService.instance.getPendingChanges();

    SyncEvents.instance.notifyGoalDataUpdated();
    SyncEvents.instance.notifyArchivedUpdated();

    if (ownerId != "guest") {
      await SyncService.instance.requestSync();
    }
  }

  Future<void> restoreGoalOnline(int localGoalId, int serverGoalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      await ApiService.restoreGoal(serverGoalId);
    } catch (e) {
      if (!e.toString().contains("Goal is already active")) {
        rethrow;
      }
    }

    // Read the existing local goal before changing its archive state.
    final rows = await database.query(
      "goals",
      where: "owner_id=? AND id=?",
      whereArgs: [ownerId, localGoalId],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw Exception('Cannot restore goal: local goal not found.');
    }

    final existingGoal = rows.first;

    final savedAmount = _toDouble(existingGoal["saved_amount"]);
    final targetAmount = _toDouble(existingGoal["target_amount"]);

    final isCompleted = targetAmount > 0 && savedAmount >= targetAmount;

    final completedPercentage = targetAmount <= 0
        ? 0.0
        : ((savedAmount / targetAmount) * 100).clamp(0.0, 100.0);

    final existingCompletedAt = existingGoal["completed_at"]?.toString();

    final now = DateTime.now().toIso8601String();

    await database.update(
      "goals",
      {
        "is_archived": 0,
        "is_deleted": 0,
        "completed_percentage": completedPercentage,
        "completed_at": isCompleted ? (existingCompletedAt ?? now) : null,
        "updated_at": now,
        "is_synced": 1,
      },
      where: "owner_id=? AND id=?",
      whereArgs: [ownerId, localGoalId],
    );

    debugPrint(
      'GoalsRepository: restored goal '
      '(localId=$localGoalId, serverId=$serverGoalId, '
      'completed=$isCompleted, '
      'percentage=$completedPercentage).',
    );

    SyncEvents.instance.notifyGoalDataUpdated();
    SyncEvents.instance.notifyArchivedUpdated();
  }
  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteGoalOffline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    await database.update(
      "goals",
      {"owner_id": ownerId, "is_deleted": 1, "updated_at": now, "is_synced": 0},
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );

    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "delete",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
    await SyncService.instance.getPendingChanges();

    SyncEvents.instance.notifyGoalDataUpdated();
    SyncEvents.instance.notifyArchivedUpdated();

    if (ownerId != "guest") {
      await SyncService.instance.requestSync();
    }
  }

  Future<void> deleteGoalOnline(int serverGoalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    await ApiService.deleteGoal(serverGoalId);

    final rowsUpdated = await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "is_deleted": 1,
        "updated_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
      },
      where: "server_id=? AND owner_id=?",
      whereArgs: [serverGoalId, ownerId],
    );

    debugPrint(
      'GoalsRepository: delete local update '
      'serverId=$serverGoalId rowsUpdated=$rowsUpdated',
    );

    final remaining = await database.query(
      "goals",
      where: "server_id=? AND owner_id=?",
      whereArgs: [serverGoalId, ownerId],
      limit: 1,
    );

    debugPrint(
      'GoalsRepository: post-delete local row: '
      '${remaining.isNotEmpty ? remaining.first : "NOT FOUND"}',
    );

    SyncEvents.instance.notifyGoalDataUpdated();
    SyncEvents.instance.notifyArchivedUpdated();
  }

  Future<void> deleteGoal(
    int localGoalId, {
    int? serverGoalId,
    bool isOnline = true,
  }) async {
    if (isOnline && serverGoalId != null) {
      await deleteGoalOnline(serverGoalId);
    } else {
      await deleteGoalOffline(localGoalId);
    }
  }

  Future<Map<String, dynamic>> refreshDerivedData() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      debugPrint('Goals derived data refresh: requesting API...');

      final data = await ApiService.getGoalsDerivedData();

      final now = DateTime.now().toIso8601String();

      await database.transaction((txn) async {
        // ------------------------------------------------------------
        // Find locally unsynchronized goals.
        //
        // These goals may contain newer local changes than the server.
        // Their forecast/insight cache must therefore be preserved.
        // ------------------------------------------------------------
        final unsyncedGoals = await txn.query(
          'goals',
          columns: ['server_id'],
          where: '''
          owner_id = ?
          AND is_synced = 0
          AND is_deleted = 0
          AND server_id IS NOT NULL
        ''',
          whereArgs: [ownerId],
        );

        final unsyncedServerIds = unsyncedGoals
            .map((row) => row['server_id'])
            .whereType<int>()
            .toSet();

        debugPrint(
          'Goals derived data refresh: '
          'unsynced server goals=${unsyncedServerIds.length}',
        );

        // ------------------------------------------------------------
        // ANALYTICS
        //
        // Analytics is global derived data rather than data belonging
        // to one specific goal, so it can still be refreshed from the
        // server.
        // ------------------------------------------------------------
        final analytics = data['analytics'];

        if (analytics is Map) {
          await txn.insert('goal_analytics_cache', {
            'owner_id': ownerId,
            'data': jsonEncode(Map<String, dynamic>.from(analytics)),
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        // ------------------------------------------------------------
        // FORECASTS
        //
        // Do NOT delete/rewrite forecasts belonging to unsynced goals.
        // ------------------------------------------------------------

        final forecasts = data['forecasts'];

        if (forecasts is Map) {
          for (final entry in forecasts.entries) {
            final goalId = int.tryParse(entry.key.toString());

            if (goalId == null || entry.value is! Map) {
              continue;
            }

            // Server-derived data must not overwrite a local goal's
            // derived cache while that goal still has unsynced changes.
            if (unsyncedServerIds.contains(goalId)) {
              debugPrint(
                'Goals derived data refresh: preserving local '
                'forecast for unsynced goal server_id=$goalId',
              );

              continue;
            }

            await txn.insert('goal_forecasts_cache', {
              'goal_id': goalId,
              'owner_id': ownerId,
              'data': jsonEncode(Map<String, dynamic>.from(entry.value)),
              'updated_at': now,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // ------------------------------------------------------------
        // INSIGHTS
        //
        // Same protection as forecasts.
        // ------------------------------------------------------------

        final insights = data['insights'];

        if (insights is Map) {
          for (final entry in insights.entries) {
            final goalId = int.tryParse(entry.key.toString());

            if (goalId == null || entry.value is! Map) {
              continue;
            }

            if (unsyncedServerIds.contains(goalId)) {
              debugPrint(
                'Goals derived data refresh: preserving local '
                'insight for unsynced goal server_id=$goalId',
              );

              continue;
            }

            await txn.insert('goal_insights_cache', {
              'goal_id': goalId,
              'owner_id': ownerId,
              'data': jsonEncode(Map<String, dynamic>.from(entry.value)),
              'updated_at': now,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }

        // ------------------------------------------------------------
        // DEADLINES
        //
        // This remains global derived data and can be refreshed normally.
        // ------------------------------------------------------------

        final deadlines = data['upcoming_deadlines'];

        if (deadlines is List) {
          await txn.insert('goal_deadlines_cache', {
            'owner_id': ownerId,
            'data': jsonEncode(
              deadlines
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList(),
            ),
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } else {
          await txn.insert('goal_deadlines_cache', {
            'owner_id': ownerId,
            'data': jsonEncode([]),
            'updated_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

      debugPrint('Goals derived data refresh: cache updated successfully.');

      return data;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Goals derived data API refresh failed: $e');

      rethrow;
    }
  }
}
