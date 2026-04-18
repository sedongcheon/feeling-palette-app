import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
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
      context.read<DiaryProvider>().loadMonthEntries(formatYearMonth(_currentMonth));
    });
  }

  void _shift(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
    context.read<DiaryProvider>().loadMonthEntries(formatYearMonth(_currentMonth));
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
      body: SingleChildScrollView(
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
            ],
          ],
        ),
      ),
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
