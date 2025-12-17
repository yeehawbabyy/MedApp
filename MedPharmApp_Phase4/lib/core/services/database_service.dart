import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  DatabaseService._internal();

  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    final path = join(dbPath, 'medpharm.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');

    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        study_id TEXT NOT NULL UNIQUE,
        enrollment_code TEXT NOT NULL,
        enrolled_at TEXT NOT NULL,
        consent_accepted INTEGER DEFAULT 0,
        consent_accepted_at TEXT,
        tutorial_completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE assessments (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        nrs_score INTEGER NOT NULL CHECK(nrs_score >= 0 AND nrs_score <= 10),
        vas_score INTEGER NOT NULL CHECK(vas_score >= 0 AND vas_score <= 100),
        timestamp TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_assessments_timestamp
      ON assessments(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_assessments_synced
      ON assessments(is_synced)
    ''');

    await db.execute('''
      CREATE TABLE gamification_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        study_id TEXT NOT NULL UNIQUE,
        total_points INTEGER DEFAULT 0,
        current_level INTEGER DEFAULT 1,
        assessments_completed INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_assessment_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        item_type TEXT NOT NULL,
        data_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT,
        synced_at TEXT,
        deadline TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_status
      ON sync_queue(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_deadline
      ON sync_queue(deadline)
    ''');

    await db.execute('''
      CREATE TABLE user_stats (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL UNIQUE,
        total_points INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_assessments INTEGER DEFAULT 0,
        early_completions INTEGER DEFAULT 0,
        last_assessment_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_badges (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        badge_type TEXT NOT NULL,
        earned_at TEXT NOT NULL,
        UNIQUE(study_id, badge_type)
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_user_badges_study_id
      ON user_badges(study_id)
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        action TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        before_value TEXT,
        after_value TEXT,
        metadata TEXT,
        session_id TEXT,
        timestamp TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        synced_at TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_audit_logs_study_id
      ON audit_logs(study_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_audit_logs_timestamp
      ON audit_logs(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_audit_logs_synced
      ON audit_logs(is_synced)
    ''');

    print('Database tables created successfully!');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('Upgrading database from v$oldVersion to v$newVersion...');

    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS audit_logs (
          id TEXT PRIMARY KEY,
          study_id TEXT NOT NULL,
          action TEXT NOT NULL,
          entity_type TEXT NOT NULL,
          entity_id TEXT,
          before_value TEXT,
          after_value TEXT,
          metadata TEXT,
          session_id TEXT,
          timestamp TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          synced_at TEXT
        )
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_audit_logs_study_id
        ON audit_logs(study_id)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp
        ON audit_logs(timestamp)
      ''');

      await db.execute('''
        CREATE INDEX IF NOT EXISTS idx_audit_logs_synced
        ON audit_logs(is_synced)
      ''');

      print('Added audit_logs table');
    }

    print('Database upgraded successfully!');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('Database closed');
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medpharm.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('Database deleted');
  }
}
