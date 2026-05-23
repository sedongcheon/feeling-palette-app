import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../models/month_summary.dart';
import '../providers/diary_provider.dart';
import '../services/api_locale.dart';
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
    final loc = AppLocalizations.of(context);
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
            label: emotionLabel(context, t),
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
    final monthLabel =
        DateFormat.yMMMM(loc.localeName).format(_currentMonth);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(loc.statsTitle,
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
                      loc.statsEmpty,
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
                title: loc.statsDistributionTitle,
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
                                loc.statsDistributionRow(
                                    d.value, (d.value / totalDays * 100).round()),
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
                title: loc.statsTop3Title,
                child: Column(
                  children: [
                    for (var i = 0; i < topThree.length; i++)
                      _topRow(context, palette, i + 1, topThree[i].key, topThree[i].value,
                          totalDays),
                  ],
                ),
              ),
              _section(
                palette,
                title: loc.statsTrendTitle,
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
                  title: loc.statsMonthSummaryTitle,
                  child: Text(
                    loc.statsMonthSummaryText(
                      totalDays,
                      totalEntries,
                      emotionLabel(context, topThree.first.key),
                      topThree.first.value,
                      (topThree.first.value / totalDays * 100).round(),
                    ),
                    style: TextStyle(
                        fontSize: 15, height: 24 / 15, color: palette.text),
                  ),
                ),
              _section(
                palette,
                title: loc.statsMonthAiSummaryTitle,
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

  Widget _topRow(BuildContext context, AppPalette palette, int rank, EmotionType type, int count, int total) {
    final loc = AppLocalizations.of(context);
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
                Text(emotionLabel(context, type),
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
            child: Text(loc.statsTopRowCount(count),
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
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.statsSummaryErrorTitle),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(loc.commonOk),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generate(
    BuildContext context, {
    required bool viaAd,
  }) async {
    final loc = AppLocalizations.of(context);
    final store = context.read<DiaryProvider>();
    String? errorMessage;
    try {
      final locale = apiLocaleOf(context);
      if (viaAd) {
        await store.generateSummaryViaAd(
          monthKey: monthKey,
          entries: entries,
          locale: locale,
        );
      } else {
        await store.generateSummaryWithFreeSlot(
          monthKey: monthKey,
          entries: entries,
          locale: locale,
        );
      }
    } on RewardedAdNotReadyException {
      // 광고가 안 떴음 — "광고 시청 안 함"과는 구분된 retry 가능 상태.
      errorMessage = loc.adsNotReadyMessage;
    } on MonthSummaryAdException {
      errorMessage = loc.statsSummaryAdIncomplete;
    } on MonthSummaryQuotaException {
      errorMessage = loc.statsSummaryQuotaHit;
    } catch (_) {
      errorMessage = loc.commonTryAgainLater;
    }
    if (errorMessage != null && context.mounted) {
      _showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
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
        loc.statsSummaryNotEnoughData,
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
          loc,
          available: available,
          budget: budget,
          entriesToNext: entriesToNext,
        ),
        const SizedBox(height: 10),
        _actionButton(
          context: context,
          palette: palette,
          loc: loc,
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
    AppPalette palette,
    AppLocalizations loc, {
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
            loc.statsSummaryQuotaBadge(available, budget, entriesToNext),
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
    required AppLocalizations loc,
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
      final label = summary == null
          ? loc.statsSummaryFreeCreate
          : loc.statsSummaryFreeRegen;
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
          ? loc.statsSummaryAdCreate
          : loc.statsSummaryAdRegen;
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
          loc.statsSummaryAllUsed,
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
