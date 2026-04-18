import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database.dart';
import '../db/diary_dao.dart';
import '../models/diary.dart';

class BackupResult {
  final int total;
  final int inserted;
  final int updated;
  const BackupResult({
    required this.total,
    required this.inserted,
    required this.updated,
  });
}

class BackupService {
  static const int _schemaVersion = 1;

  /// Serializes all entries to a JSON file in the temp directory and returns it.
  Future<File> exportToFile() async {
    final dao = DiaryDao();
    final entries = await dao.findAll(limit: 1 << 20);

    final payload = {
      'app': 'feeling_palette',
      'schema_version': _schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'count': entries.length,
      'entries': entries.map(_entryToJson).toList(),
    };

    final dir = await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/feeling-palette-backup-$ts.json');
    await file.writeAsString(jsonEncode(payload), flush: true);
    return file;
  }

  /// Imports entries from a JSON file. Existing rows with the same id are replaced.
  Future<BackupResult> importFromBytes(List<int> bytes) async {
    final raw = utf8.decode(bytes);
    final decoded = jsonDecode(raw);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('백업 파일 형식이 올바르지 않습니다.');
    }
    if (decoded['app'] != 'feeling_palette') {
      throw const FormatException('Feeling Palette 백업 파일이 아닙니다.');
    }
    final list = decoded['entries'];
    if (list is! List) {
      throw const FormatException('백업 데이터가 비어있습니다.');
    }

    final db = await AppDatabase.instance.database;
    int inserted = 0;
    int updated = 0;

    await db.transaction((txn) async {
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final entry = _entryFromJson(raw);
        if (entry == null) continue;

        final existing = await txn.query(
          'diary_entries',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [entry.id],
          limit: 1,
        );
        await txn.insert(
          'diary_entries',
          entry.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        if (existing.isEmpty) {
          inserted++;
        } else {
          updated++;
        }
      }
    });

    return BackupResult(
      total: inserted + updated,
      inserted: inserted,
      updated: updated,
    );
  }

  Map<String, dynamic> _entryToJson(DiaryEntry entry) => {
        'id': entry.id,
        'date': entry.date,
        'content': entry.content,
        'primary_emotion': entry.primaryEmotion.name,
        'emotions': entry.emotions.toJson(),
        'ai_comment': entry.aiComment,
        'color': entry.color,
        'created_at': entry.createdAt,
        'updated_at': entry.updatedAt,
        'analysis_count': entry.analysisCount,
      };

  DiaryEntry? _entryFromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final date = json['date'];
    final content = json['content'];
    if (id is! String || date is! String || content is! String) return null;
    final emotionsRaw = json['emotions'];
    final emotions = emotionsRaw is Map<String, dynamic>
        ? EmotionScores.fromJson(emotionsRaw)
        : EmotionScores.empty;
    final aiComment = (json['ai_comment'] as String?) ?? '';
    // Legacy backups don't carry analysis_count; infer from aiComment.
    final analysisCount = (json['analysis_count'] as num?)?.toInt() ??
        (aiComment.isNotEmpty ? 1 : 0);
    return DiaryEntry(
      id: id,
      date: date,
      content: content,
      primaryEmotion: emotionFromString(json['primary_emotion'] as String? ?? 'calm'),
      emotions: emotions,
      aiComment: aiComment,
      color: (json['color'] as String?) ?? '#9CA3AF',
      createdAt: (json['created_at'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      updatedAt: (json['updated_at'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      analysisCount: analysisCount,
    );
  }
}
