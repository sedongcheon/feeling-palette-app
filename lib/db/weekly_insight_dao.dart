import 'package:sqflite/sqflite.dart';

import '../models/weekly_insight.dart';
import 'database.dart';

class WeeklyInsightDao {
  Future<WeeklyInsight?> findLatest() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'weekly_insights',
      orderBy: 'generated_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeeklyInsight.fromRow(rows.first);
  }

  Future<WeeklyInsight?> findByAnchorDate(String anchorDate) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'weekly_insights',
      where: 'anchor_date = ?',
      whereArgs: [anchorDate],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WeeklyInsight.fromRow(rows.first);
  }

  /// Total insights generated in the given month (YYYY-MM). Used for quota math.
  Future<List<WeeklyInsight>> findByMonth(String monthKey) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'weekly_insights',
      where: 'month_key = ?',
      whereArgs: [monthKey],
      orderBy: 'generated_at DESC',
    );
    return rows.map(WeeklyInsight.fromRow).toList();
  }

  Future<void> upsert(WeeklyInsight insight) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'weekly_insights',
      insight.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
