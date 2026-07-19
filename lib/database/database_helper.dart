import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, "pesapulse.db");

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
CREATE TABLE expenses(
id INTEGER PRIMARY KEY,
server_id INTEGER,
title TEXT,
amount REAL,
category TEXT,
expense_date TEXT,
description TEXT,
updated_at TEXT,
is_synced INTEGER DEFAULT 1,
is_deleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE goals(
id INTEGER PRIMARY KEY,
server_id INTEGER,
title TEXT,
target_amount REAL,
saved_amount REAL,
achievement TEXT,
completed_percentage REAL,
completed_at TEXT,
updated_at TEXT,
is_synced INTEGER DEFAULT 1,
is_deleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE savings(
id INTEGER PRIMARY KEY,
server_id INTEGER,
goal_id INTEGER,
amount REAL,
saving_date TEXT,
updated_at TEXT,
is_synced INTEGER DEFAULT 1,
is_deleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE budgets(
id INTEGER PRIMARY KEY,
server_id INTEGER,
category TEXT,
amount REAL,
month TEXT,
updated_at TEXT,
is_synced INTEGER DEFAULT 1,
is_deleted INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE sync_queue(
id INTEGER PRIMARY KEY AUTOINCREMENT,
table_name TEXT,
operation TEXT,
record_id INTEGER,
payload TEXT,
created_at TEXT
)
''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {}
}
