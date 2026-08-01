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
      version: 19,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await _createCoreTables(db);
    await _createCacheTables(db);
  }

  Future<void> _createCoreTables(Database db) async {
    await db.execute('''
CREATE TABLE expenses(
id INTEGER PRIMARY KEY,
owner_id TEXT DEFAULT 'guest',
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
id INTEGER PRIMARY KEY AUTOINCREMENT,
server_id INTEGER UNIQUE,
owner_id TEXT DEFAULT 'guest',
title TEXT,
target_amount REAL,
target_date TEXT,
saved_amount REAL,
achievement TEXT,
completed_percentage REAL,
created_at TEXT,
completed_at TEXT,
updated_at TEXT,
is_synced INTEGER DEFAULT 1,
is_deleted INTEGER DEFAULT 0,
is_archived INTEGER DEFAULT 0
)
''');

    await db.execute('''
CREATE TABLE savings(
id INTEGER PRIMARY KEY,
owner_id TEXT DEFAULT 'guest',
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
owner_id TEXT DEFAULT 'guest',
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
owner_id TEXT DEFAULT 'guest',
table_name TEXT,
operation TEXT,
record_id INTEGER,
payload TEXT,
created_at TEXT
)
''');

    await db.execute('''
CREATE TABLE settings(
    owner_id TEXT DEFAULT 'guest',

    key TEXT,

    value TEXT,

    PRIMARY KEY(owner_id, key)
)
''');
  }

  Future<void> _createCacheTables(Database db) async {
    await db.execute('''
CREATE TABLE dashboard_cache(
owner_id TEXT PRIMARY KEY,

total_expenses INTEGER,
total_count INTEGER,
total_categories INTEGER,

recent_expenses TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE financial_insights_cache(
owner_id TEXT PRIMARY KEY,

budget_status TEXT,

payload TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE budget_summary_cache(
owner_id TEXT PRIMARY KEY,

budget REAL,
budget_count INTEGER DEFAULT 0,
spent REAL,
remaining REAL,

payload TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE analytics_cache(
owner_id TEXT PRIMARY KEY,

expenses TEXT,

goal_analytics TEXT,

financial_insights TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goals_cache(
owner_id TEXT PRIMARY KEY,

goals TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_forecasts_cache(
goal_id INTEGER PRIMARY KEY,

owner_id TEXT,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_insights_cache(
goal_id INTEGER PRIMARY KEY,

owner_id TEXT,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_analytics_cache(
owner_id TEXT PRIMARY KEY,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_deadlines_cache(
owner_id TEXT PRIMARY KEY,

data TEXT,

updated_at TEXT
)
''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 11) {}

    if (oldVersion < 12) {
      await db.execute('''
    ALTER TABLE goals
    ADD COLUMN is_archived INTEGER DEFAULT 0
    ''');
    }

    if (oldVersion < 13) {
      // Remove duplicate goals that share the same server_id
      await db.execute("""
    DELETE FROM goals
    WHERE rowid NOT IN (
      SELECT MIN(rowid)
      FROM goals
      GROUP BY server_id
    )
    AND server_id IS NOT NULL;
  """);

      // Prevent future duplicates
      await db.execute("""
    CREATE UNIQUE INDEX IF NOT EXISTS idx_goals_server_id
    ON goals(server_id);
  """);
    }

    if (oldVersion < 14) {
      await db.execute("""
    ALTER TABLE expenses
    ADD COLUMN owner_id TEXT DEFAULT 'guest'
  """);

      await db.execute("""
    ALTER TABLE budgets
    ADD COLUMN owner_id TEXT DEFAULT 'guest'
  """);

      await db.execute("""
    ALTER TABLE goals
    ADD COLUMN owner_id TEXT DEFAULT 'guest'
  """);

      await db.execute("""
    ALTER TABLE savings
    ADD COLUMN owner_id TEXT DEFAULT 'guest'
  """);

      await db.execute("""
    ALTER TABLE sync_queue
    ADD COLUMN owner_id TEXT DEFAULT 'guest'
  """);
    }

    if (oldVersion < 15) {
      await db.execute("DROP TABLE IF EXISTS dashboard_cache");
      await db.execute("DROP TABLE IF EXISTS financial_insights_cache");
      await db.execute("DROP TABLE IF EXISTS budget_summary_cache");
      await db.execute("DROP TABLE IF EXISTS analytics_cache");
      await db.execute("DROP TABLE IF EXISTS goals_cache");
      await db.execute("DROP TABLE IF EXISTS goal_forecasts_cache");
      await db.execute("DROP TABLE IF EXISTS goal_insights_cache");
      await db.execute("DROP TABLE IF EXISTS goal_analytics_cache");
      await db.execute("DROP TABLE IF EXISTS goal_deadlines_cache");

      // Recreate them using the new schema
      await _createCacheTables(db);
    }

    if (oldVersion < 16) {
      await db.execute("DROP TABLE IF EXISTS settings");

      await db.execute('''
CREATE TABLE settings(
    owner_id TEXT DEFAULT 'guest',

    key TEXT,

    value TEXT,

    PRIMARY KEY(owner_id, key)
)
''');
    }

    if (oldVersion < 17) {
      await db.execute("""
    ALTER TABLE goals
    ADD COLUMN target_date TEXT
  """);
    }

    if (oldVersion < 18) {
      await db.execute("""
    ALTER TABLE goals
    ADD COLUMN created_at TEXT
  """);
    }

    if (oldVersion < 19) {
      await db.execute("""
    ALTER TABLE  budget_summary_cache
    ADD COLUMN budget_count INTEGER DEFAULT 0
  """);
    }
  }
}
