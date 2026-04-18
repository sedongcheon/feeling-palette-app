import 'dart:math';

import 'package:flutter/foundation.dart';

import '../db/diary_dao.dart';
import '../models/diary.dart';

String todayString() {
  final d = DateTime.now();
  return _formatYmd(d);
}

String formatYearMonth(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

String _formatYmd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _generateId() {
  final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  final rand = Random().nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
  return '$ts${rand.substring(rand.length - 7)}';
}

class DiaryProvider extends ChangeNotifier {
  DiaryProvider({DiaryDao? dao}) : _dao = dao ?? DiaryDao();

  final DiaryDao _dao;

  List<DiaryEntry> _todayEntries = const [];
  List<DiaryEntry> _monthEntries = const [];
  List<DiaryEntry> _timelineEntries = const [];

  List<DiaryEntry> get todayEntries => _todayEntries;
  List<DiaryEntry> get monthEntries => _monthEntries;
  List<DiaryEntry> get timelineEntries => _timelineEntries;

  int get todayAnalyzedCount =>
      _todayEntries.where((e) => e.analysisCount > 0).length;

  bool get dailyAnalysisLimitReached =>
      todayAnalyzedCount >= kMaxDailyAnalyzedEntries;

  Future<void> loadTodayEntries() async {
    _todayEntries = await _dao.findAllByDate(todayString());
    notifyListeners();
  }

  Future<void> loadMonthEntries(String yearMonth) async {
    _monthEntries = await _dao.findByMonth(yearMonth);
    notifyListeners();
  }

  Future<int> loadTimelineEntries({int limit = 50, int offset = 0}) async {
    final entries = await _dao.findAll(limit: limit, offset: offset);
    if (offset == 0) {
      _timelineEntries = entries;
    } else {
      _timelineEntries = [..._timelineEntries, ...entries];
    }
    notifyListeners();
    return entries.length;
  }

  /// Creates a new diary entry. Multiple entries per day are allowed.
  Future<DiaryEntry> createDiary(String content, {String? date}) async {
    final targetDate = date ?? todayString();
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = DiaryEntry(
      id: _generateId(),
      date: targetDate,
      content: content,
      primaryEmotion: EmotionType.calm,
      emotions: EmotionScores.empty,
      aiComment: '',
      color: '#9CA3AF',
      createdAt: now,
      updatedAt: now,
    );
    await _dao.insert(entry);
    if (targetDate == todayString()) {
      _todayEntries = [..._todayEntries, entry];
    }
    _timelineEntries = [entry, ..._timelineEntries];
    if (entry.date.startsWith(targetDate.substring(0, 7))) {
      _monthEntries = [..._monthEntries, entry];
    }
    notifyListeners();
    return entry;
  }

  /// Updates an existing entry's content. If the content changed and the
  /// entry still has analyses remaining, the previous analysis is cleared so
  /// the user can re-analyze.
  Future<UpdateOutcome?> updateDiary({
    required String id,
    required String content,
  }) async {
    final existing = await _dao.findById(id);
    if (existing == null) return null;
    final contentChanged = existing.content != content;
    final shouldClearAnalysis = contentChanged && existing.canAnalyze;
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = shouldClearAnalysis
        ? existing.copyWith(
            content: content,
            primaryEmotion: EmotionType.calm,
            emotions: EmotionScores.empty,
            aiComment: '',
            color: '#9CA3AF',
            updatedAt: now,
          )
        : existing.copyWith(content: content, updatedAt: now);
    await _dao.update(updated);
    _replaceEntry(updated);
    notifyListeners();
    return UpdateOutcome(
      entry: updated,
      contentChanged: contentChanged,
      analysisLocked: contentChanged && !existing.canAnalyze,
    );
  }

  Future<DiaryEntry?> applyAnalysis({
    required String id,
    required EmotionType primaryEmotion,
    required EmotionScores emotions,
    required String aiComment,
    required String color,
  }) async {
    final existing = await _dao.findById(id);
    if (existing == null) return null;
    // Defensive: a brand-new analysis on today's entry must respect the
    // daily quota. Re-analyses of already-analyzed entries are unaffected.
    final isFirstAnalysis = existing.analysisCount == 0;
    if (isFirstAnalysis &&
        existing.date == todayString() &&
        dailyAnalysisLimitReached) {
      throw DailyAnalysisLimitException();
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = existing.copyWith(
      primaryEmotion: primaryEmotion,
      emotions: emotions,
      aiComment: aiComment,
      color: color,
      updatedAt: now,
      analysisCount: existing.analysisCount + 1,
    );
    await _dao.update(updated);
    _replaceEntry(updated);
    notifyListeners();
    return updated;
  }

  Future<void> removeDiary(String id) async {
    await _dao.delete(id);
    _todayEntries = _todayEntries.where((e) => e.id != id).toList();
    _timelineEntries = _timelineEntries.where((e) => e.id != id).toList();
    _monthEntries = _monthEntries.where((e) => e.id != id).toList();
    notifyListeners();
  }

  void _replaceEntry(DiaryEntry updated) {
    _todayEntries = _todayEntries
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    _monthEntries = _monthEntries
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
    _timelineEntries = _timelineEntries
        .map((e) => e.id == updated.id ? updated : e)
        .toList();
  }

  void clearCache() {
    _todayEntries = const [];
    _monthEntries = const [];
    _timelineEntries = const [];
    notifyListeners();
  }
}

class UpdateOutcome {
  final DiaryEntry entry;
  final bool contentChanged;
  final bool analysisLocked;
  const UpdateOutcome({
    required this.entry,
    required this.contentChanged,
    required this.analysisLocked,
  });
}

class DailyAnalysisLimitException implements Exception {
  @override
  String toString() => 'DailyAnalysisLimitException';
}
