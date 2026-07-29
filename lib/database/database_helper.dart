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
      version: 14,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
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
CREATE TABLE dashboard_cache(
id INTEGER PRIMARY KEY,

total_expenses INTEGER,
total_count INTEGER,
total_categories INTEGER,

recent_expenses TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE financial_insights_cache(
id INTEGER PRIMARY KEY,

budget_status TEXT,

payload TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE budget_summary_cache(
id INTEGER PRIMARY KEY,

budget REAL,
spent REAL,
remaining REAL,

payload TEXT,

updated_at TEXT
);
''');

    await db.execute('''
CREATE TABLE analytics_cache(
id INTEGER PRIMARY KEY,

expenses TEXT,

goal_analytics TEXT,

financial_insights TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goals_cache(
id INTEGER PRIMARY KEY,

goals TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_forecasts_cache(
id INTEGER PRIMARY KEY,

goal_id INTEGER UNIQUE,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_insights_cache(
id INTEGER PRIMARY KEY,

goal_id INTEGER UNIQUE,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_analytics_cache(
id INTEGER PRIMARY KEY,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
CREATE TABLE goal_deadlines_cache(
id INTEGER PRIMARY KEY,

data TEXT,

updated_at TEXT
)
''');

    await db.execute('''
    CREATE TABLE goals(
id INTEGER PRIMARY KEY AUTOINCREMENT,
server_id INTEGER UNIQUE,
owner_id TEXT DEFAULT 'guest',
title TEXT,
target_amount REAL,
saved_amount REAL,
achievement TEXT,
completed_percentage REAL,
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
  key TEXT PRIMARY KEY,
  value TEXT
)
''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await db.execute('''
CREATE TABLE dashboard_cache(
id INTEGER PRIMARY KEY,
total_expenses INTEGER,
total_count INTEGER,
total_categories INTEGER,
recent_expenses TEXT,
budget_status TEXT,
updated_at TEXT
)
''');
    }

    if (oldVersion < 4) {
      await db.execute('''
CREATE TABLE financial_insights_cache(
id INTEGER PRIMARY KEY,

budget_status TEXT,

payload TEXT,

updated_at TEXT
)
''');
    }

    if (oldVersion < 5) {
      await db.execute('''
    CREATE TABLE IF NOT EXISTS budget_summary_cache(
      id INTEGER PRIMARY KEY,
      budget REAL,
      spent REAL,
      remaining REAL,
      payload TEXT,
      updated_at TEXT
    )
    ''');
    }

    if (oldVersion < 6) {
      await db.execute('''
CREATE TABLE analytics_cache(
id INTEGER PRIMARY KEY,

expenses TEXT,

goal_analytics TEXT,

financial_insights TEXT,

updated_at TEXT
)
''');
    }

    if (oldVersion < 7) {
      await db.execute('''
CREATE TABLE goals_cache(
id INTEGER PRIMARY KEY,

goals TEXT,

updated_at TEXT
)
''');
    }

    if (oldVersion < 8) {
      await db.execute('''
CREATE TABLE goal_forecasts_cache(
id INTEGER PRIMARY KEY,

goal_id INTEGER UNIQUE,

data TEXT,

updated_at TEXT
)
''');

      await db.execute('''
CREATE TABLE goal_insights_cache(
id INTEGER PRIMARY KEY,

goal_id INTEGER UNIQUE,

data TEXT,

updated_at TEXT
)
''');
    }

    if (oldVersion < 9) {
      await db.execute('''
CREATE TABLE goal_analytics_cache(
id INTEGER PRIMARY KEY,

data TEXT,

updated_at TEXT
)
''');
    }

    if (oldVersion < 10) {
      await db.execute('''
CREATE TABLE goal_deadlines_cache(
id INTEGER PRIMARY KEY,

data TEXT,

updated_at TEXT
)
''');
    }

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
  }
}
