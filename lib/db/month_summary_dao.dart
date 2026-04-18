import 'package:sqflite/sqflite.dart';

import '../models/month_summary.dart';
import 'database.dart';

class MonthSummaryDao {
  Future<MonthSummary?> findByMonth(String monthKey) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'month_summaries',
      where: 'month_key = ?',
      whereArgs: [monthKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MonthSummary.fromRow(rows.first);
  }

  Future<void> upsert(MonthSummary summary) async {
    final db = await AppDatabase.instance.database;
    await db.insert(
      'month_summaries',
      summary.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteByMonth(String monthKey) async {
    final db = await AppDatabase.instance.database;
    await db.delete(
      'month_summaries',
      where: 'month_key = ?',
      whereArgs: [monthKey],
    );
  }
}
