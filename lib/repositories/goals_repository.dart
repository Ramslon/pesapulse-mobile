import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/api_services.dart';

class GoalsRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<List<dynamic>> getGoals() async {
    final database = await db.database;

    try {
      final activeGoals = await ApiService.getGoals();
      final archivedGoals = await ApiService.getArchivedGoals();

      final goals = [...activeGoals, ...archivedGoals];

      final serverIds = goals.map((g) => g["id"]).toList();

      await database.delete(
        "goals",
        where:
            "server_id IS NOT NULL AND server_id NOT IN (${List.filled(serverIds.length, "?").join(",")})",
        whereArgs: serverIds,
      );

      for (final goal in goals) {
        final existing = await database.query(
          "goals",
          where: "server_id=?",
          whereArgs: [goal["id"]],
          limit: 1,
        );

        final values = {
          "server_id": goal["id"],
          "title": goal["title"],
          "target_amount": goal["target_amount"],
          "saved_amount": goal["saved_amount"],
          "achievement": goal["achievement"] ?? "",
          "completed_percentage": goal["completed_percentage"] ?? 0,
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
            where: "server_id=?",
            whereArgs: [goal["id"]],
          );
        } else {
          await database.insert("goals", values);
        }
      }
      return await database.query(
        "goals",
        where: "is_archived = ? AND is_deleted = ?",
        whereArgs: [0, 0],
        orderBy: "updated_at DESC",
      );
    } catch (_) {
      return await database.query(
        "goals",
        where: "is_archived=? AND is_deleted=?",
        whereArgs: [0, 0],
        orderBy: "updated_at DESC",
      );
    }
  }

  Future<void> createGoalOffline({
    required String title,
    required double targetAmount,
    String? targetDate,
  }) async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();
    final localId = -DateTime.now().millisecondsSinceEpoch;

    // Check existing active goals
    final existing = await database.query(
      "goals",
      where:
          "LOWER(title)=LOWER(?) AND target_amount=? AND is_deleted=0 AND is_archived=0",
      whereArgs: [title.trim()],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw Exception("A goal with this title already exists.");
    }

    // Check queued creations
    final queued = await database.query(
      "sync_queue",
      where: "table_name=? AND operation=?",
      whereArgs: ["goals", "create"],
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
      "title": title,
      "target_amount": targetAmount,
      "target_date": targetDate,
    };

    // Only insert after all validation passes
    await database.insert("goals", {
      "id": localId,
      "server_id": null,
      "title": title,
      "target_amount": targetAmount,
      "saved_amount": 0,
      "achievement": "",
      "completed_percentage": 0,
      "completed_at": null,
      "updated_at": now,
      "is_synced": 0,
      "is_deleted": 0,
      "is_archived": 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await database.insert("sync_queue", {
      "table_name": "goals",
      "operation": "create",
      "record_id": localId,
      "payload": jsonEncode(payload),
      "created_at": now,
    });
  }

  Future<void> updateGoalProgressOffline(int goalId, double amount) async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    final goal = await database.query(
      "goals",
      where: "id=?",
      whereArgs: [goalId],
      limit: 1,
    );

    if (goal.isEmpty) {
      throw Exception("Goal not found");
    }

    final currentSaved = (goal.first["saved_amount"] as num?)?.toDouble() ?? 0;

    final targetAmount = (goal.first["target_amount"] as num?)?.toDouble() ?? 0;

    final newSaved = currentSaved + amount;

    final percentage = targetAmount == 0
        ? 0
        : ((newSaved / targetAmount) * 100).clamp(0, 100);

    await database.update(
      "goals",
      {
        "saved_amount": newSaved,
        "completed_percentage": percentage,
        "updated_at": now,
        "is_synced": 0,
      },
      where: "id=?",
      whereArgs: [goalId],
    );

    await database.insert("sync_queue", {
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
    final database = await db.database;

    final response = await ApiService.updateGoalProgress(serverGoalId, amount);

    final goal = response["goal"];

    await database.update(
      "goals",
      {
        "saved_amount": goal["saved_amount"],
        "updated_at": goal["updated_at"],
        "completed_percentage": response["percentage"],
        "completed_at": goal["saved_amount"] >= goal["target_amount"]
            ? goal["updated_at"]
            : null,
        "is_synced": 1,
      },
      where: "id=?",
      whereArgs: [localGoalId],
    );

    return response;
  }

  Future<void> archiveGoalOffline(int goalId) async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    // Mark the goal as archived locally
    await database.update(
      "goals",
      {
        "is_archived": 1,
        "completed_at": now,
        "updated_at": now,
        "is_synced": 0,
      },
      where: "id=?",
      whereArgs: [goalId],
    );

    // Queue the archive operation
    await database.insert("sync_queue", {
      "table_name": "goals",
      "operation": "archive",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
  }

  Future<void> archiveGoalOnline(int goalId) async {
    final database = await db.database;

    await ApiService.archiveGoal(goalId);

    await database.update(
      "goals",
      {
        "is_archived": 1,
        "completed_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
        "updated_at": DateTime.now().toIso8601String(),
      },
      where: "server_id=?",
      whereArgs: [goalId],
    );
  }

  Future<void> restoreGoalOffline(int goalId) async {
    final database = await db.database;

    final now = DateTime.now().toIso8601String();

    // Restore locally
    await database.update(
      "goals",
      {"is_archived": 0, "is_deleted": 0, "updated_at": now, "is_synced": 0},
      where: "id=?",
      whereArgs: [goalId],
    );

    // Queue restore operation
    await database.insert("sync_queue", {
      "table_name": "goals",
      "operation": "restore",
      "record_id": goalId,
      "payload": "{}",
      "created_at": now,
    });
  }

  Future<void> restoreGoalOnline(int goalId) async {
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
        "is_archived": 0,
        "is_deleted": 0,
        "updated_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
      },
      where: "id=?",
      whereArgs: [goalId],
    );
  }

  Future<List<Map<String, dynamic>>> getArchivedGoals() async {
    final database = await db.database;

    try {
      final archivedGoals = await ApiService.getArchivedGoals();

      for (final goal in archivedGoals) {
        final existing = await database.query(
          "goals",
          where: "server_id=?",
          whereArgs: [goal["id"]],
          limit: 1,
        );

        final values = {
          "server_id": goal["id"],
          "title": goal["title"],
          "target_amount": goal["target_amount"],
          "saved_amount": goal["saved_amount"],
          "achievement": goal["achievement"] ?? "",
          "completed_percentage": goal["completed_percentage"] ?? 0,
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
            where: "server_id=?",
            whereArgs: [goal["id"]],
          );
        } else {
          await database.insert("goals", values);
        }
      }
    } catch (_) {
      // offline → fall back to local DB
    }

    return await database.query(
      "goals",
      where: "is_archived=? AND is_deleted=0",
      whereArgs: [1],
      orderBy: "updated_at DESC",
    );
  }

  Future<List<Map<String, dynamic>>> getActiveGoals() async {
    final database = await db.database;

    return await database.query(
      "goals",
      where: "is_archived = ? AND is_deleted = ?",
      whereArgs: [0, 0],
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
    final database = await db.database;
    final now = DateTime.now().toIso8601String();

    // Mark the goal as deleted locally
    await database.update(
      "goals",
      {"is_deleted": 1, "updated_at": now, "is_synced": 0},
      where: "id=?",
      whereArgs: [goalId],
    );

    // Queue the delete operation
    await database.insert("sync_queue", {
      "table_name": "goals",
      "operation": "delete",
      "record_id": goalId,
      "payload": "{}", // no payload needed
      "created_at": now,
    });
  }

  Future<void> deleteGoalOnline(int serverGoalId) async {
    final database = await db.database;

    // Call API to delete goal
    await ApiService.deleteGoal(serverGoalId);

    // Mark as deleted locally
    await database.update(
      "goals",
      {
        "is_deleted": 1,
        "updated_at": DateTime.now().toIso8601String(),
        "is_synced": 1,
      },
      where: "server_id=?",
      whereArgs: [serverGoalId],
    );
  }
}
