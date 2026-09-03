import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';

class MigrationRepository {
  MigrationRepository._();

  static final MigrationRepository instance = MigrationRepository._();

  final DatabaseHelper db = DatabaseHelper.instance;

  static const String guestOwnerId = 'guest';

  /// Checks whether there is any local guest data.
  Future<bool> hasGuestData() async {
    final database = await db.database;

    final tables = <String>[
      'expenses',
      'goals',
      'budgets',
      'settings',
      'sync_queue',
    ];

    for (final table in tables) {
      final result = await database.rawQuery(
        'SELECT COUNT(*) AS count FROM $table WHERE owner_id = ?',
        [guestOwnerId],
      );

      final count = (result.first['count'] as int?) ?? 0;

      if (count > 0) {
        return true;
      }
    }

    return false;
  }

  /// Returns the total number of local guest records.
  Future<int> guestDataCount() async {
    final database = await db.database;

    int total = 0;

    final tables = <String>[
      'expenses',
      'goals',
      'budgets',
      'settings',
      'sync_queue',
    ];

    for (final table in tables) {
      final result = await database.rawQuery(
        'SELECT COUNT(*) AS count FROM $table WHERE owner_id = ?',
        [guestOwnerId],
      );

      total += (result.first['count'] as int?) ?? 0;
    }

    return total;
  }

  /// Collects all guest-owned data that will be sent to the server.
  ///
  /// sync_queue is intentionally excluded from the migration payload.
  /// It contains local synchronization instructions, not actual user data.
  Future<Map<String, dynamic>> collectGuestData() async {
    final database = await db.database;

    // ------------------------------------------------------------
    // EXPENSES
    // ------------------------------------------------------------
    final expenses = await database.query(
      'expenses',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

    // ------------------------------------------------------------
    // GOALS
    // ------------------------------------------------------------
    final goals = await database.query(
      'goals',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

    // ------------------------------------------------------------
    // BUDGET
    //
    // PesaPulse supports one budget per user.
    // The current BudgetRepository stores it in
    // budget_summary_cache rather than a budgets table.
    // ------------------------------------------------------------
    final budgetRows = await database.query(
      'budget_summary_cache',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
      limit: 1,
    );

    final List<Map<String, dynamic>> budgets = [];

    if (budgetRows.isNotEmpty) {
      final row = budgetRows.first;

      final payload = row['payload'];

      if (payload is String && payload.isNotEmpty) {
        try {
          final decoded = jsonDecode(payload);

          if (decoded is Map) {
            final budget = Map<String, dynamic>.from(decoded);

            final amount =
                double.tryParse(budget['budget']?.toString() ?? '') ?? 0;

            if (amount > 0) {
              final now = DateTime.now();

              budgets.add({
                'client_id': 'guest-budget-1',
                'amount': amount,
                'month': now.month,
                'year': now.year,
              });
            }
          }
        } catch (e) {
          debugPrint('Failed to decode guest budget: $e');
        }
      }
    }

    // ------------------------------------------------------------
    // SETTINGS
    //
    // The settings table does NOT use owner_id.
    // Only migrate actual user preferences.
    // Cache/profile/sync keys must NOT be migrated.
    // ------------------------------------------------------------
    const allowedSettings = {
      'daily_reminder',
      'expense_alerts',
      'weekly_summary',
      'dark_mode',
      'notifications_enabled',
    };

    final settingRows = await database.query('settings');

    final List<Map<String, dynamic>> settings = [];

    for (final row in settingRows) {
      final key = row['key']?.toString();

      if (key == null || !allowedSettings.contains(key)) {
        continue;
      }

      final rawValue = row['value'];

      bool value;

      if (rawValue is bool) {
        value = rawValue;
      } else if (rawValue is num) {
        value = rawValue != 0;
      } else {
        final stringValue = rawValue?.toString().toLowerCase();

        value =
            stringValue == 'true' ||
            stringValue == '1' ||
            stringValue == 'yes' ||
            stringValue == 'on';
      }

      settings.add({'key': key, 'value': value});
    }

    return {
      'expenses': expenses,
      'goals': goals,
      'budgets': budgets,
      'settings': settings,
    };
  }

  /// Moves local guest records to the authenticated user's owner_id.
  ///
  /// This should ONLY be called after the backend confirms that the
  /// guest data was successfully migrated.
  Future<void> assignGuestDataToUser(String userId) async {
    final database = await db.database;

    await database.transaction((txn) async {
      await txn.update(
        'expenses',
        {'owner_id': userId},
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await txn.update(
        'goals',
        {'owner_id': userId},
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await txn.update(
        'budgets',
        {'owner_id': userId},
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await _migrateSettings(txn, userId);
    });
  }

  /// Migrates guest settings into the authenticated user's settings.
  ///
  /// settings has PRIMARY KEY(owner_id, key), so settings need special
  /// handling instead of simply updating owner_id.
  Future<void> _migrateSettings(DatabaseExecutor txn, String userId) async {
    final guestSettings = await txn.query(
      'settings',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

    for (final setting in guestSettings) {
      final key = setting['key'];

      final value = setting['value'];

      if (key == null) continue;

      await txn.insert('settings', {
        'owner_id': userId,
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await txn.delete(
      'settings',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );
  }

  Future<void> clearGuestSyncQueue() async {
    final database = await db.database;

    await database.delete(
      'sync_queue',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final database = await db.database;

    return await database.query('sync_queue', orderBy: 'id ASC');
  }
}
