import 'dart:convert';

import 'package:sqflite/sqflite.dart';

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

    final expenses = await database.query(
      'expenses',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

    final goals = await database.query(
      'goals',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

    final budgets = await database.query(
      'budgets',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

    final settings = await database.query(
      'settings',
      where: 'owner_id = ?',
      whereArgs: [guestOwnerId],
    );

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

  /// Transfers the guest sync queue to the authenticated user.
  ///
  /// The queue itself is local-only. Its payloads may contain owner_id,
  /// so the payload is rewritten before changing the queue owner.
  Future<void> migrateSyncQueue(String userId) async {
    final database = await db.database;

    await database.transaction((txn) async {
      final queue = await txn.query(
        'sync_queue',
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      for (final item in queue) {
        Map<String, dynamic> payload = {};

        final rawPayload = item['payload'];

        if (rawPayload != null && rawPayload.toString().trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(rawPayload.toString());

            if (decoded is Map<String, dynamic>) {
              payload = Map<String, dynamic>.from(decoded);
            }
          } catch (_) {
            // Keep the original payload if it is not valid JSON.
          }
        }

        payload['owner_id'] = userId;

        await txn.update(
          'sync_queue',
          {'owner_id': userId, 'payload': jsonEncode(payload)},
          where: 'id = ? AND owner_id = ?',
          whereArgs: [item['id'], guestOwnerId],
        );
      }
    });
  }

  /// Clears all remaining guest-owned local data.
  ///
  /// This is a safety cleanup operation and should only happen after
  /// successful migration.
  Future<void> clearGuestData() async {
    final database = await db.database;

    await database.transaction((txn) async {
      await txn.delete(
        'expenses',
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await txn.delete(
        'goals',
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await txn.delete(
        'budgets',
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await txn.delete(
        'settings',
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );

      await txn.delete(
        'sync_queue',
        where: 'owner_id = ?',
        whereArgs: [guestOwnerId],
      );
    });
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
