import '../models/diary.dart';
import 'database.dart';

class DiaryDao {
  Future<void> insert(DiaryEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.insert('diary_entries', entry.toRow());
  }

  Future<void> update(DiaryEntry entry) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'diary_entries',
      {
        'content': entry.content,
        'primary_emotion': entry.primaryEmotion.name,
        'emotions_json': entry.emotions.toJsonString(),
        'ai_comment': entry.aiComment,
        'color': entry.color,
        'updated_at': entry.updatedAt,
        'analysis_count': entry.analysisCount,
      },
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<DiaryEntry?> findById(String id) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DiaryEntry.fromRow(rows.first);
  }

  Future<List<DiaryEntry>> findAllByDate(String date) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'diary_entries',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'created_at ASC',
    );
    return rows.map(DiaryEntry.fromRow).toList();
  }

  Future<List<DiaryEntry>> findByMonth(String yearMonth) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'diary_entries',
      where: 'date LIKE ?',
      whereArgs: ['$yearMonth%'],
      orderBy: 'date ASC, created_at ASC',
    );
    return rows.map(DiaryEntry.fromRow).toList();
  }

  Future<List<DiaryEntry>> findAll({int limit = 50, int offset = 0}) async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query(
      'diary_entries',
      orderBy: 'date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(DiaryEntry.fromRow).toList();
  }
}
