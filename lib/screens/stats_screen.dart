import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../models/diary.dart';
import '../models/month_summary.dart';
import '../providers/diary_provider.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/donut_chart.dart';
import '../widgets/weekly_line_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<DiaryProvider>();
      final key = formatYearMonth(_currentMonth);
      store.loadMonthEntries(key);
      store.loadMonthSummary(key);
    });
  }

  void _shift(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    final store = context.read<DiaryProvider>();
    final key = formatYearMonth(_currentMonth);
    store.loadMonthEntries(key);
    store.loadMonthSummary(key);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final store = context.watch<DiaryProvider>();

    final byDate = groupEntriesByDate(store.monthEntries);
    final aggregates = byDate.entries
        .map((e) => DayAggregate.fromEntries(e.key, e.value))
        .where((a) => a.hasAnalysis)
        .toList();

    final counts = <EmotionType, int>{
      for (final t in EmotionType.values) t: 0,
    };
    for (final agg in aggregates) {
      counts[agg.primaryEmotion] = (counts[agg.primaryEmotion] ?? 0) + 1;
    }

    final donutData = EmotionType.values
        .map((t) {
          final info = emotionInfoOf(t);
          return DonutSlice(
            label: info.label,
            emoji: info.emoji,
            value: counts[t] ?? 0,
            color: info.color,
          );
        })
        .where((d) => d.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top3 = counts.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topThree = top3.take(3).toList();

    final totalDays = aggregates.length;
    final totalEntries = store.monthEntries.length;
    final hasData = totalDays > 0;
    final monthLabel = '${_currentMonth.year}년 ${_currentMonth.month}월';

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('감정 통계',
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17, color: palette.text)),
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: Column(
              children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _shift(-1),
                    icon: Text('◀',
                        style: TextStyle(color: palette.tabBarActive, fontSize: 14)),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: Text(
                      monthLabel,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: palette.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _shift(1),
                    icon: Text('▶',
                        style: TextStyle(color: palette.tabBarActive, fontSize: 14)),
                  ),
                ],
              ),
            ),
            if (!hasData)
              Container(
                margin: const EdgeInsets.only(top: 20),
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.border),
                ),
                child: Column(
                  children: [
                    const Text('📊', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 12),
                    Text(
                      '이 달에는 아직 분석된 일기가 없어요\n일기를 작성하면 감정 통계를 볼 수 있어요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, height: 22 / 14, color: palette.textSecondary),
                    ),
                  ],
                ),
              )
            else ...[
              _section(
                palette,
                title: '감정 분포 (하루 평균 기준)',
                child: Column(
                  children: [
                    Center(child: DonutChart(data: donutData, size: 150)),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        for (final d in donutData) ...[
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: d.color,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${d.emoji} ${d.label}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: palette.text,
                                  ),
                                ),
                              ),
                              Text(
                                '${d.value}일 (${(d.value / totalDays * 100).round()}%)',
                                style: TextStyle(
                                    fontSize: 12, color: palette.textSecondary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _section(
                palette,
                title: '이 달의 감정 Top 3',
                child: Column(
                  children: [
                    for (var i = 0; i < topThree.length; i++)
                      _topRow(palette, i + 1, topThree[i].key, topThree[i].value,
                          totalDays),
                  ],
                ),
              ),
              _section(
                palette,
                title: '감정 변화',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return WeeklyLineChart(
                      days: aggregates,
                      width: constraints.maxWidth,
                      height: 180,
                      textColor: palette.textSecondary,
                      gridColor: palette.border,
                      surfaceColor: palette.surface,
                    );
                  },
                ),
              ),
              if (topThree.isNotEmpty)
                _section(
                  palette,
                  title: '월간 요약',
                  child: Text(
                    "이번 달은 $totalDays일(총 $totalEntries개 기록) 중 '${emotionInfoOf(topThree.first.key).label}'을 가장 많이 느꼈어요. "
                    "(${topThree.first.value}일, ${(topThree.first.value / totalDays * 100).round()}%)",
                    style: TextStyle(
                        fontSize: 15, height: 24 / 15, color: palette.text),
                  ),
                ),
              _section(
                palette,
                title: '월간 AI 요약',
                child: _MonthAiSummaryBlock(
                  monthKey: formatYearMonth(_currentMonth),
                  entries: store.monthEntries,
                ),
              ),
            ],
              ],
            ),
          ),
        ),
        const BannerAdSlot(),
      ]),
    );
  }

  Widget _section(AppPalette palette,
      {required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: palette.text)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _topRow(AppPalette palette, int rank, EmotionType type, int count, int total) {
    final info = emotionInfoOf(type);
    final percentage = (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: Text('$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary)),
          ),
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: info.color.withAlpha(0x18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(info.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.text)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Stack(
                    children: [
                      Container(height: 6, color: palette.border),
                      FractionallySizedBox(
                        widthFactor: (percentage / 100).clamp(0.0, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: info.color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text('$count일',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: info.color)),
          ),
        ],
      ),
    );
  }
}

class _MonthAiSummaryBlock extends StatelessWidget {
  final String monthKey;
  final List<DiaryEntry> entries;

  const _MonthAiSummaryBlock({
    required this.monthKey,
    required this.entries,
  });

  bool get _hasEnoughData => entries.any((e) => e.aiComment.isNotEmpty);

  void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('요약 생성 실패'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _generate(
    BuildContext context, {
    required bool viaAd,
  }) async {
    final store = context.read<DiaryProvider>();
    String? errorMessage;
    try {
      if (viaAd) {
        await store.generateSummaryViaAd(
          monthKey: monthKey,
          entries: entries,
        );
      } else {
        await store.generateSummaryWithFreeSlot(
          monthKey: monthKey,
          entries: entries,
        );
      }
    } on MonthSummaryAdException {
      errorMessage = '광고 시청이 완료되지 않아 요약을 만들지 못했어요.';
    } on MonthSummaryQuotaException {
      errorMessage = '오늘 요약 한도를 모두 사용했어요. 내일 다시 이용해주세요.';
    } catch (_) {
      errorMessage = '잠시 후 다시 시도해주세요.';
    }
    if (errorMessage != null && context.mounted) {
      _showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final store = context.watch<DiaryProvider>();
    final summary = store.summaryFor(monthKey);
    final inFlight = store.isSummaryInFlight;
    final entryCount = entries.length;
    final available = store.availableRegensForMonth(monthKey, entryCount);
    final budget = store.budgetForMonth(monthKey, entryCount);
    final canAd = store.canWatchAdForMonth(monthKey);
    final entriesToNext = store.entriesUntilNextRefill(entryCount);

    if (!_hasEnoughData && summary == null) {
      return Text(
        '이번 달 분석된 일기가 없어 요약할 내용이 부족해요.',
        style: TextStyle(fontSize: 14, color: palette.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary != null) _summaryText(palette, summary),
        if (summary != null) const SizedBox(height: 12),
        _quotaBadge(
          palette,
          available: available,
          budget: budget,
          entriesToNext: entriesToNext,
        ),
        const SizedBox(height: 10),
        _actionButton(
          context: context,
          palette: palette,
          summary: summary,
          inFlight: inFlight,
          available: available,
          canAd: canAd,
        ),
      ],
    );
  }

  Widget _summaryText(AppPalette palette, MonthSummary summary) {
    return Text(
      summary.summaryText,
      style: TextStyle(fontSize: 15, height: 24 / 15, color: palette.text),
    );
  }

  Widget _quotaBadge(
    AppPalette palette, {
    required int available,
    required int budget,
    required int entriesToNext,
  }) {
    return Row(
      children: [
        Icon(Icons.auto_awesome_rounded,
            size: 12, color: palette.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '이 달 요약 $available/$budget 남음 · 일기 $entriesToNext개 더 쓰면 +1회 충전',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required AppPalette palette,
    required MonthSummary? summary,
    required bool inFlight,
    required int available,
    required bool canAd,
  }) {
    if (inFlight) {
      return SizedBox(
        height: 44,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.tabBarActive,
            ),
          ),
        ),
      );
    }

    if (available > 0) {
      final label = summary == null ? '무료로 AI 요약 만들기' : '무료로 다시 요약하기';
      return SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: _hasEnoughData ? () => _generate(context, viaAd: false) : null,
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.tabBarActive,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      );
    }

    if (canAd) {
      final label = summary == null
          ? '광고 보고 AI 요약 만들기'
          : '광고 보고 다시 요약하기';
      return SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: _hasEnoughData ? () => _generate(context, viaAd: true) : null,
          icon: const Icon(Icons.ondemand_video_rounded, size: 18),
          label: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.tabBarActive.withAlpha(0xCC),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      );
    }

    return SizedBox(
      height: 44,
      child: Center(
        child: Text(
          '이 달 요약 한도를 모두 사용했어요',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.textSecondary,
          ),
        ),
      ),
    );
  }
}
