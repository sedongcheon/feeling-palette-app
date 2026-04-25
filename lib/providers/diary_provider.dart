import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../db/diary_dao.dart';
import '../db/month_summary_dao.dart';
import '../db/weekly_insight_dao.dart';
import '../models/diary.dart';
import '../models/month_summary.dart';
import '../models/weekly_insight.dart';
import '../services/ads_service.dart';
import '../services/month_summary_service.dart';
import '../services/weekly_insight_service.dart';

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
  DiaryProvider({
    DiaryDao? dao,
    MonthSummaryDao? monthSummaryDao,
    MonthSummaryService? monthSummaryService,
    WeeklyInsightDao? weeklyInsightDao,
    WeeklyInsightService? weeklyInsightService,
  })  : _dao = dao ?? DiaryDao(),
        _monthSummaryDao = monthSummaryDao ?? MonthSummaryDao(),
        _monthSummaryService = monthSummaryService ?? MonthSummaryService(),
        _weeklyInsightDao = weeklyInsightDao ?? WeeklyInsightDao(),
        _weeklyInsightService =
            weeklyInsightService ?? WeeklyInsightService();

  final DiaryDao _dao;
  final MonthSummaryDao _monthSummaryDao;
  final MonthSummaryService _monthSummaryService;
  final WeeklyInsightDao _weeklyInsightDao;
  final WeeklyInsightService _weeklyInsightService;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  List<DiaryEntry> _todayEntries = const [];
  List<DiaryEntry> _monthEntries = const [];
  List<DiaryEntry> _timelineEntries = const [];

  int _todayBonusAnalyses = 0;
  int _todayBonusAdsShown = 0;
  String _loadedBonusDate = '';

  // In-memory cache of month summaries, keyed by 'YYYY-MM'. The row itself
  // carries the regen/ad counters used by the monthly quota scheme.
  final Map<String, MonthSummary> _monthSummaries = {};
  final Set<String> _loadedSummaryKeys = {};
  bool _summaryInFlight = false;

  // Weekly insight state. We only cache the latest generated insight plus the
  // per-month usage counters needed for quota math.
  WeeklyInsight? _latestInsight;
  bool _insightLoaded = false;
  bool _insightInFlight = false;
  // Per-month insight counters, keyed by 'YYYY-MM'. Regen count = total
  // insights generated in that month; ad count = subset unlocked via reward.
  final Map<String, int> _insightRegenByMonth = {};
  final Map<String, int> _insightAdByMonth = {};
  final Set<String> _loadedInsightMonths = {};

  List<DiaryEntry> get todayEntries => _todayEntries;
  List<DiaryEntry> get monthEntries => _monthEntries;
  List<DiaryEntry> get timelineEntries => _timelineEntries;

  int get todayAnalyzedCount =>
      _todayEntries.where((e) => e.analysisCount > 0).length;

  int get todayBonusAnalyses => _todayBonusAnalyses;
  int get todayBonusAdsShown => _todayBonusAdsShown;
  int get todayBonusAdsRemaining =>
      (kRewardMaxAdsPerDay - _todayBonusAdsShown).clamp(0, kRewardMaxAdsPerDay);
  // iOS는 보상형 광고로 한도를 늘릴 수 없으므로(canWatchBonusAd 참고) 무료 한도
  // 자체를 8개로 상향. Android는 기본 3 + 광고 시청으로 추가 (최대 8).
  int get effectiveDailyLimit =>
      (Platform.isIOS ? 8 : kMaxDailyAnalyzedEntries) + _todayBonusAnalyses;
  // iOS는 App Store 리뷰 환경에서 보상형 광고가 안정적으로 재생되지 않아
  // 리뷰어가 보상을 받지 못한다고 판단해 거절. Android는 그대로 노출.
  // (iOS Apple Paid Apps Agreement 활성화/사업자등록 후 재평가 예정)
  bool get canWatchBonusAd =>
      !Platform.isIOS && _todayBonusAdsShown < kRewardMaxAdsPerDay;

  bool get dailyAnalysisLimitReached =>
      todayAnalyzedCount >= effectiveDailyLimit;

  // --- Monthly AI summary quota (per month key) ---

  bool get isSummaryInFlight => _summaryInFlight;

  MonthSummary? summaryFor(String monthKey) => _monthSummaries[monthKey];

  int regensUsedForMonth(String monthKey) =>
      _monthSummaries[monthKey]?.regenCount ?? 0;

  int adsUsedForMonth(String monthKey) =>
      _monthSummaries[monthKey]?.adCount ?? 0;

  int refillsEarnedForEntryCount(int entryCount) =>
      entryCount ~/ kMonthSummaryEntriesPerRefill;

  /// Total budget (base + entry-driven refills + ad unlocks) for [monthKey]
  /// given the current number of diary entries in that month.
  /// iOS는 광고 시청으로 한도를 늘릴 수 없으므로 base를 8로 상향.
  int budgetForMonth(String monthKey, int entryCount) =>
      (Platform.isIOS ? 8 : kMonthSummaryBaseRegens) +
      refillsEarnedForEntryCount(entryCount) +
      adsUsedForMonth(monthKey);

  /// How many regenerations are still available before the user must watch
  /// an ad (or add more entries to earn a refill).
  int availableRegensForMonth(String monthKey, int entryCount) {
    final remaining =
        budgetForMonth(monthKey, entryCount) - regensUsedForMonth(monthKey);
    return remaining < 0 ? 0 : remaining;
  }

  bool canRegenFreeForMonth(String monthKey, int entryCount) =>
      availableRegensForMonth(monthKey, entryCount) > 0;

  bool canWatchAdForMonth(String monthKey) =>
      !Platform.isIOS &&
      adsUsedForMonth(monthKey) < kMonthSummaryMaxAdsPerMonth;

  /// Number of additional entries needed before the next +1 refill lands.
  int entriesUntilNextRefill(int entryCount) {
    final remainder = entryCount % kMonthSummaryEntriesPerRefill;
    return remainder == 0
        ? kMonthSummaryEntriesPerRefill
        : kMonthSummaryEntriesPerRefill - remainder;
  }

  // --- Weekly proactive insight quota (per month key) ---

  bool get isInsightInFlight => _insightInFlight;
  WeeklyInsight? get latestInsight => _latestInsight;
  bool get hasInsightLoaded => _insightLoaded;

  int insightRegensUsedForMonth(String monthKey) =>
      _insightRegenByMonth[monthKey] ?? 0;

  int insightAdsUsedForMonth(String monthKey) =>
      _insightAdByMonth[monthKey] ?? 0;

  // iOS는 광고로 추가 못 받으므로 base 5로 상향. Android는 그대로.
  int insightBudgetForMonth(String monthKey) =>
      (Platform.isIOS ? 5 : kWeeklyInsightBaseRegens) +
      insightAdsUsedForMonth(monthKey);

  int availableInsightsForMonth(String monthKey) {
    final remaining =
        insightBudgetForMonth(monthKey) - insightRegensUsedForMonth(monthKey);
    return remaining < 0 ? 0 : remaining;
  }

  bool canGenerateInsightFree(String monthKey) =>
      availableInsightsForMonth(monthKey) > 0;

  bool canWatchAdForInsight(String monthKey) =>
      !Platform.isIOS &&
      insightAdsUsedForMonth(monthKey) < kWeeklyInsightMaxAdsPerMonth;

  /// Whether the cooldown since the last generated insight has elapsed.
  /// Returns true when no insight exists yet.
  bool get insightCooldownElapsed {
    final last = _latestInsight;
    if (last == null) return true;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final delta = Duration(milliseconds: nowMs - last.generatedAt);
    return delta.inDays >= kWeeklyInsightCooldownDays;
  }

  /// Days remaining until the next insight is eligible. 0 when elapsed.
  int get insightDaysUntilRefresh {
    final last = _latestInsight;
    if (last == null) return 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final elapsed = Duration(milliseconds: nowMs - last.generatedAt).inDays;
    final remain = kWeeklyInsightCooldownDays - elapsed;
    return remain < 0 ? 0 : remain;
  }

  Future<void> loadTodayEntries() async {
    _todayEntries = await _dao.findAllByDate(todayString());
    notifyListeners();
  }

  /// Loads today's bonus/ad-viewed counts from secure storage. Idempotent
  /// within the same calendar day; will refresh automatically after midnight.
  Future<void> loadDailyBonus() async {
    final today = todayString();
    if (_loadedBonusDate == today) return;
    _loadedBonusDate = today;
    final raw = await _storage.read(key: 'bonus_$today');
    if (raw == null) {
      _todayBonusAnalyses = 0;
      _todayBonusAdsShown = 0;
    } else {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _todayBonusAnalyses = (data['bonus'] as num?)?.toInt() ?? 0;
        _todayBonusAdsShown = (data['adsShown'] as num?)?.toInt() ?? 0;
      } catch (_) {
        _todayBonusAnalyses = 0;
        _todayBonusAdsShown = 0;
      }
    }
    notifyListeners();
  }

  /// Shows a rewarded ad and, if the user earns the reward, grants
  /// [kRewardBonusPerAd] extra analyses for today. Returns whether the
  /// bonus was granted.
  Future<bool> watchAdForBonus() async {
    await loadDailyBonus();
    if (!canWatchBonusAd) return false;
    final earned = await AdsService.instance.showRewarded();
    if (!earned) return false;
    _todayBonusAnalyses += kRewardBonusPerAd;
    _todayBonusAdsShown += 1;
    await _persistBonus();
    notifyListeners();
    return true;
  }

  Future<void> _persistBonus() async {
    final today = todayString();
    await _storage.write(
      key: 'bonus_$today',
      value: jsonEncode({
        'bonus': _todayBonusAnalyses,
        'adsShown': _todayBonusAdsShown,
      }),
    );
  }

  /// Loads a cached month summary from DB into memory. Safe to call many times.
  Future<MonthSummary?> loadMonthSummary(String monthKey) async {
    if (_loadedSummaryKeys.contains(monthKey)) {
      return _monthSummaries[monthKey];
    }
    final cached = await _monthSummaryDao.findByMonth(monthKey);
    _loadedSummaryKeys.add(monthKey);
    if (cached != null) {
      _monthSummaries[monthKey] = cached;
      notifyListeners();
    }
    return cached;
  }

  /// Consumes one free (non-ad) regeneration slot for [monthKey] and calls
  /// the server. Throws [MonthSummaryQuotaException] if no free budget left.
  Future<MonthSummary> generateSummaryWithFreeSlot({
    required String monthKey,
    required List<DiaryEntry> entries,
  }) async {
    if (!canRegenFreeForMonth(monthKey, entries.length)) {
      throw MonthSummaryQuotaException();
    }
    return _runSummary(
      monthKey: monthKey,
      entries: entries,
      viaAd: false,
    );
  }

  /// Shows a rewarded ad; on reward, calls the server and records an ad
  /// unlock for [monthKey]. Throws [MonthSummaryQuotaException] if the
  /// per-month ad cap is reached, or [MonthSummaryAdException] if the ad
  /// did not reward.
  Future<MonthSummary> generateSummaryViaAd({
    required String monthKey,
    required List<DiaryEntry> entries,
  }) async {
    if (!canWatchAdForMonth(monthKey)) {
      throw MonthSummaryQuotaException();
    }
    final earned = await AdsService.instance.showRewarded();
    if (!earned) {
      throw MonthSummaryAdException();
    }
    return _runSummary(
      monthKey: monthKey,
      entries: entries,
      viaAd: true,
    );
  }

  Future<MonthSummary> _runSummary({
    required String monthKey,
    required List<DiaryEntry> entries,
    required bool viaAd,
  }) async {
    if (_summaryInFlight) {
      throw StateError('이미 요약을 생성 중입니다.');
    }
    _summaryInFlight = true;
    notifyListeners();
    try {
      final resp = await _monthSummaryService.summarize(
        yearMonth: monthKey,
        entries: entries,
      );
      final prev = _monthSummaries[monthKey];
      final now = DateTime.now().millisecondsSinceEpoch;
      final next = MonthSummary(
        monthKey: monthKey,
        summaryText: resp.summary,
        dominantEmotion: resp.dominantEmotion,
        generatedAt: now,
        regenCount: (prev?.regenCount ?? 0) + 1,
        adCount: (prev?.adCount ?? 0) + (viaAd ? 1 : 0),
      );
      await _monthSummaryDao.upsert(next);
      _monthSummaries[monthKey] = next;
      _loadedSummaryKeys.add(monthKey);
      return next;
    } finally {
      _summaryInFlight = false;
      notifyListeners();
    }
  }

  /// Loads the most recently generated insight from DB (if any) and the
  /// regen/ad counts for the current month. Idempotent within a session.
  Future<void> loadLatestInsight() async {
    if (_insightLoaded) return;
    final latest = await _weeklyInsightDao.findLatest();
    _latestInsight = latest;
    if (latest != null) {
      await _loadInsightMonth(latest.monthKey);
    }
    await _loadInsightMonth(formatYearMonth(DateTime.now()));
    _insightLoaded = true;
    notifyListeners();
  }

  Future<void> _loadInsightMonth(String monthKey) async {
    if (_loadedInsightMonths.contains(monthKey)) return;
    final rows = await _weeklyInsightDao.findByMonth(monthKey);
    int regen = 0;
    int ads = 0;
    for (final row in rows) {
      regen += row.regenCount > 0 ? row.regenCount : 1;
      ads += row.adCount;
    }
    // Fallback: if stored regen_count is 0 (legacy), count rows instead.
    if (regen == 0 && rows.isNotEmpty) regen = rows.length;
    _insightRegenByMonth[monthKey] = regen;
    _insightAdByMonth[monthKey] = ads;
    _loadedInsightMonths.add(monthKey);
  }

  /// Collects recent entries for the insight input window (last N days ending
  /// today). May span 2 calendar months.
  Future<List<DiaryEntry>> _recentEntriesForInsight() async {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: kWeeklyInsightInputDays - 1));
    return _dao.findByDateRange(
      startYmd: _formatYmd(start),
      endYmd: _formatYmd(now),
    );
  }

  /// Generate an insight against the free quota for the current month.
  /// Throws [WeeklyInsightQuotaException] if no free slot,
  /// [WeeklyInsightCooldownException] if the 7-day cooldown is still active,
  /// or [WeeklyInsightNotEnoughDataException] if the user has too few entries.
  Future<WeeklyInsight> generateInsightWithFreeSlot() async {
    final monthKey = formatYearMonth(DateTime.now());
    await _loadInsightMonth(monthKey);
    if (!insightCooldownElapsed) throw WeeklyInsightCooldownException();
    if (!canGenerateInsightFree(monthKey)) {
      throw WeeklyInsightQuotaException();
    }
    return _runInsight(viaAd: false);
  }

  /// Generate an insight by spending a rewarded ad unlock for the current
  /// month. Throws [WeeklyInsightQuotaException] if the per-month ad cap is
  /// reached, [WeeklyInsightAdException] if the ad did not reward,
  /// [WeeklyInsightCooldownException] if the cooldown is still active, or
  /// [WeeklyInsightNotEnoughDataException] if the user has too few entries.
  Future<WeeklyInsight> generateInsightViaAd() async {
    final monthKey = formatYearMonth(DateTime.now());
    await _loadInsightMonth(monthKey);
    if (!insightCooldownElapsed) throw WeeklyInsightCooldownException();
    if (!canWatchAdForInsight(monthKey)) {
      throw WeeklyInsightQuotaException();
    }
    final earned = await AdsService.instance.showRewarded();
    if (!earned) throw WeeklyInsightAdException();
    return _runInsight(viaAd: true);
  }

  Future<WeeklyInsight> _runInsight({required bool viaAd}) async {
    if (_insightInFlight) {
      throw StateError('이미 인사이트를 생성 중입니다.');
    }
    final entries = await _recentEntriesForInsight();
    if (entries.length < kWeeklyInsightMinEntries) {
      throw WeeklyInsightNotEnoughDataException();
    }
    _insightInFlight = true;
    notifyListeners();
    try {
      final today = todayString();
      final monthKey = today.substring(0, 7);
      final resp = await _weeklyInsightService.generate(
        anchorDate: today,
        entries: entries,
      );
      final prevRegen = _insightRegenByMonth[monthKey] ?? 0;
      final prevAd = _insightAdByMonth[monthKey] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final next = WeeklyInsight(
        anchorDate: today,
        insightText: resp.insightText,
        trend: trendFromString(resp.trend),
        keyword: resp.keyword,
        confidence: confidenceFromString(resp.confidence),
        careFlag: resp.careFlag,
        generatedAt: now,
        monthKey: monthKey,
        regenCount: prevRegen + 1,
        adCount: prevAd + (viaAd ? 1 : 0),
      );
      await _weeklyInsightDao.upsert(next);
      _latestInsight = next;
      _insightRegenByMonth[monthKey] = prevRegen + 1;
      _insightAdByMonth[monthKey] = prevAd + (viaAd ? 1 : 0);
      _loadedInsightMonths.add(monthKey);
      return next;
    } finally {
      _insightInFlight = false;
      notifyListeners();
    }
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
    _todayBonusAnalyses = 0;
    _todayBonusAdsShown = 0;
    _loadedBonusDate = '';
    _monthSummaries.clear();
    _loadedSummaryKeys.clear();
    _summaryInFlight = false;
    _latestInsight = null;
    _insightLoaded = false;
    _insightInFlight = false;
    _insightRegenByMonth.clear();
    _insightAdByMonth.clear();
    _loadedInsightMonths.clear();
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

class MonthSummaryQuotaException implements Exception {
  @override
  String toString() => 'MonthSummaryQuotaException';
}

class MonthSummaryAdException implements Exception {
  @override
  String toString() => 'MonthSummaryAdException';
}

class WeeklyInsightQuotaException implements Exception {
  @override
  String toString() => 'WeeklyInsightQuotaException';
}

class WeeklyInsightAdException implements Exception {
  @override
  String toString() => 'WeeklyInsightAdException';
}

class WeeklyInsightCooldownException implements Exception {
  @override
  String toString() => 'WeeklyInsightCooldownException';
}

class WeeklyInsightNotEnoughDataException implements Exception {
  @override
  String toString() => 'WeeklyInsightNotEnoughDataException';
}
