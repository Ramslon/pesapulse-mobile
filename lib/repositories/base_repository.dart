import '../database/database_helper.dart';
import '../services/session_service.dart';
import 'package:sqflite/sqflite.dart';

abstract class BaseRepository {
  final DatabaseHelper db = DatabaseHelper.instance;

  Future<String> get ownerId async => await SessionService.currentOwnerId();

  Future<Database> get database async => await db.database;

  Future<Map<String, Object?>> ownerWhere() async {
    final id = await ownerId;

    return {
      "where": "owner_id = ?",
      "args": [id],
    };
  }
}
