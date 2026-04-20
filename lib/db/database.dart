import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

const String _dbName = 'feelingpalette.db';
const int _dbVersion = 5;

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<void> wipe() async {
    final existing = _db;
    if (existing != null) {
      await existing.close();
      _db = null;
    }
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    await deleteDatabase(path);
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS diary_entries (
            id TEXT PRIMARY KEY NOT NULL,
            date TEXT NOT NULL,
            content TEXT NOT NULL,
            primary_emotion TEXT NOT NULL,
            emotions_json TEXT NOT NULL,
            ai_comment TEXT NOT NULL DEFAULT '',
            color TEXT NOT NULL DEFAULT '#9CA3AF',
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            analysis_count INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_diary_date ON diary_entries(date);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_diary_created ON diary_entries(created_at);');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS app_settings (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS month_summaries (
            month_key TEXT PRIMARY KEY NOT NULL,
            summary_text TEXT NOT NULL,
            dominant_emotion TEXT,
            generated_at INTEGER NOT NULL,
            regen_count INTEGER NOT NULL DEFAULT 0,
            ad_count INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS weekly_insights (
            anchor_date TEXT PRIMARY KEY NOT NULL,
            insight_text TEXT NOT NULL,
            trend TEXT NOT NULL,
            keyword TEXT,
            confidence TEXT NOT NULL,
            care_flag INTEGER NOT NULL DEFAULT 0,
            generated_at INTEGER NOT NULL,
            month_key TEXT NOT NULL,
            regen_count INTEGER NOT NULL DEFAULT 0,
            ad_count INTEGER NOT NULL DEFAULT 0
          );
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_weekly_generated ON weekly_insights(generated_at);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_weekly_month ON weekly_insights(month_key);',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE diary_entries ADD COLUMN analysis_count INTEGER NOT NULL DEFAULT 0;",
          );
          // Backfill: existing entries with an aiComment have been analyzed at least once
          await db.execute(
            "UPDATE diary_entries SET analysis_count = 1 WHERE ai_comment != '' AND analysis_count = 0;",
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS month_summaries (
              month_key TEXT PRIMARY KEY NOT NULL,
              summary_text TEXT NOT NULL,
              dominant_emotion TEXT,
              generated_at INTEGER NOT NULL
            );
          ''');
        }
        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE month_summaries ADD COLUMN regen_count INTEGER NOT NULL DEFAULT 0;",
          );
          await db.execute(
            "ALTER TABLE month_summaries ADD COLUMN ad_count INTEGER NOT NULL DEFAULT 0;",
          );
          // Existing rows created under the old quota scheme had exactly
          // one generation backing them — backfill so the budget math works.
          await db.execute(
            "UPDATE month_summaries SET regen_count = 1 WHERE regen_count = 0;",
          );
        }
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS weekly_insights (
              anchor_date TEXT PRIMARY KEY NOT NULL,
              insight_text TEXT NOT NULL,
              trend TEXT NOT NULL,
              keyword TEXT,
              confidence TEXT NOT NULL,
              care_flag INTEGER NOT NULL DEFAULT 0,
              generated_at INTEGER NOT NULL,
              month_key TEXT NOT NULL,
              regen_count INTEGER NOT NULL DEFAULT 0,
              ad_count INTEGER NOT NULL DEFAULT 0
            );
          ''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_weekly_generated ON weekly_insights(generated_at);',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_weekly_month ON weekly_insights(month_key);',
          );
        }
      },
    );
  }
}
