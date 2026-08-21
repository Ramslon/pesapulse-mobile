import 'dart:convert';

import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../models/goal.dart';

import '../services/api_services.dart';

class GoalsRepository extends BaseRepository {
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0.0;
  }

  Future<List<Goal>> getGoals() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final activeGoals = await ApiService.getGoals();
      final archivedGoals = await ApiService.getArchivedGoals();

      final goals = [...activeGoals, ...archivedGoals];

      final serverIds = goals.map((g) => g["id"]).toList();

      await database.delete(
        "goals",
        where:
            "owner_id=? AND server_id IS NOT NULL AND server_id NOT IN (${List.filled(serverIds.length, "?").join(",")}) ",
        whereArgs: [ownerId, ...serverIds],
      );

      for (final goal in goals) {
        final existing = await database.query(
          "goals",
          where: "server_id=? AND owner_id=?",
          whereArgs: [goal["id"], ownerId],
          limit: 1,
        );

        final values = {
          "server_id": goal["id"],
          "owner_id": ownerId,
          "title": goal["title"],
          "target_amount": _toDouble(goal["target_amount"]),
          "target_date": goal["target_date"],
          "saved_amount": _toDouble(goal["saved_amount"]),
          "achievement": goal["achievement"] ?? "",
          "completed_percentage": _toDouble(goal["completed_percentage"]),
          "created_at": goal["created_at"] ?? DateTime.now().toIso8601String(),
          "completed_at": goal["completed_at"],
          "updated_at": goal["updated_at"] ?? DateTime.now().toIso8601String(),
          "is_archived": goal["is_archived"] == true ? 1 : 0,
          "is_synced": 1,
          "is_deleted": 0,
        };

        if (existing.isNotEmpty) {
          await database.update(
            "goals",
            values,
            where: "server_id=? AND owner_id=?",
            whereArgs: [goal["id"], ownerId],
          );
        } else {
          await database.insert(
            "goals",
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      final rows = await database.query(
        "goals",
        where: "owner_id=? AND is_archived=? AND is_deleted=?",
        whereArgs: [ownerId, 0, 0],
        orderBy: "updated_at DESC",
      );

      return rows.map(Goal.fromMap).toList();
    } catch (_) {
      final rows = await database.query(
        "goals",
        where: "owner_id=? AND is_archived=? AND is_deleted=?",
        whereArgs: [ownerId, 0, 0],
        orderBy: "updated_at DESC",
      );

      return rows.map(Goal.fromMap).toList();
    }
  }

  Future<void> createGoalOffline({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();
    final localId = -DateTime.now().millisecondsSinceEpoch;

    // Check existing active goals
    final existing = await database.query(
      "goals",
      where:
          "owner_id=? AND LOWER(title)=LOWER(?) AND target_amount=? AND is_deleted=0 AND is_archived=0",
      whereArgs: [ownerId, title.trim(), targetAmount],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception("A goal with this title already exists.");
    }

    // Check queued creations
    final queued = await database.query(
      "sync_queue",
      where: "owner_id=? AND  table_name=? AND operation=?",
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

    final payload = {
      "owner_id": ownerId,
      "title": title,
      "target_amount": targetAmount,
      "target_date": targetDate,
    };

    // Only insert after all validation passes
    await database.insert("goals", {
      "id": localId,
      "owner_id": ownerId,
      "server_id": null,
      "title": title,
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

    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "create",
      "record_id": localId,
      "payload": jsonEncode(payload),
      "created_at": now,
    });
  }

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
  }

  Future<void> syncOfflineGoal({
    required int localId,
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
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
      where: "id=?",
      whereArgs: [localId],
    );
  }

  Future<void> createGoal({
    required String title,
    required double targetAmount,
    String? targetDate,
    required bool isOnline,
  }) async {
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

  Future<void> updateGoalProgressOffline(int goalId, double amount) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    final goal = await database.query(
      "goals",
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
      limit: 1,
    );

    if (goal.isEmpty) {
      throw Exception("Goal not found");
    }

    final currentSaved = _toDouble(goal.first["saved_amount"]);
    final targetAmount = _toDouble(goal.first["target_amount"]);

    final newSaved = currentSaved + amount;

    final percentage = targetAmount == 0
        ? 0.0
        : ((newSaved / targetAmount) * 100).clamp(0, 100);

    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "saved_amount": newSaved,
        "completed_percentage": percentage,
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
  }

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

    return response;
  }

  Future<void> archiveGoalOffline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    // Mark the goal as archived locally
    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "is_archived": 1,
        "completed_at": now,
        "updated_at": now,
        "is_synced": 0,
      },
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );

    // Queue the archive operation
    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "archive",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
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
        "completed_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
        "updated_at": DateTime.now().toIso8601String(),
      },
      where: "server_id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );
  }

  Future<void> restoreGoalOffline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    // Restore locally
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

    // Queue restore operation
    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "restore",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
  }

  Future<void> restoreGoalOnline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      await ApiService.restoreGoal(goalId);
    } catch (e) {
      if (!e.toString().contains("Goal is already active")) {
        rethrow;
      }
    }

    await database.update(
      "goals",
      {
        "owner_id": ownerId,
        "is_archived": 0,
        "is_deleted": 0,
        "updated_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
      },
      where: "owner_id=? AND id=?",
      whereArgs: [ownerId, goalId],
    );
  }

  Future<List<Map<String, dynamic>>> getArchivedGoals() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    try {
      final archivedGoals = await ApiService.getArchivedGoals();

      for (final goal in archivedGoals) {
        final existing = await database.query(
          "goals",
          where: "server_id=? AND owner_id=?",
          whereArgs: [goal["id"], ownerId],
          limit: 1,
        );

        final values = {
          "server_id": goal["id"],
          "owner_id": ownerId,
          "title": goal["title"],
          "target_amount": _toDouble(goal["target_amount"]),
          "target_date": goal["target_date"],
          "saved_amount": _toDouble(goal["saved_amount"]),
          "achievement": goal["achievement"] ?? "",
          "completed_percentage": _toDouble(goal["completed_percentage"]),
          "created_at": goal["created_at"],
          "completed_at": goal["completed_at"],
          "updated_at": goal["updated_at"],
          "is_archived": 1,
          "is_synced": 1,
          "is_deleted": 0,
        };

        if (existing.isNotEmpty) {
          await database.update(
            "goals",
            values,
            where: "server_id=? AND owner_id=?",
            whereArgs: [goal["id"], ownerId],
          );
        } else {
          await database.insert(
            "goals",
            values,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    } catch (_) {
      // offline → fall back to local DB
    }

    return await database.query(
      "goals",
      where: "owner_id=? AND is_archived=? AND is_deleted=0",
      whereArgs: [ownerId, 1],
      orderBy: "updated_at DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getActiveGoals() async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    return await database.query(
      "goals",
      where: "owner_id=? AND is_archived = ? AND is_deleted = ?",
      whereArgs: [ownerId, 0, 0],
      orderBy: "updated_at DESC",
    );
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

  Future<void> deleteGoalOffline(int goalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    // Mark the goal as deleted locally
    await database.update(
      "goals",
      {"owner_id": ownerId, "is_deleted": 1, "updated_at": now, "is_synced": 0},
      where: "id=? AND owner_id=?",
      whereArgs: [goalId, ownerId],
    );

    // Queue the delete operation
    await database.insert("sync_queue", {
      "owner_id": ownerId,
      "table_name": "goals",
      "operation": "delete",
      "record_id": goalId,
      "payload": "{}", // no payload needed
      "created_at": now,
    });
  }

  Future<void> deleteGoalOnline(int serverGoalId) async {
    final ownerId = await this.ownerId;
    final database = await db.database;

    // Call API to delete goal
    await ApiService.deleteGoal(serverGoalId);

    // Mark as deleted locally
    await database.update(
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
}
