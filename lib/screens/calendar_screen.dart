import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
import '../widgets/banner_ad_slot.dart';
import '../widgets/day_average_card.dart';
import '../widgets/diary_detail_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _currentMonth = '';

  @override
  void initState() {
    super.initState();
    _currentMonth = formatYearMonth(_focusedDay);
    // 첫 진입 시 현재 달이 자동으로 보이고 오늘 날짜가 디폴트 선택되어
    // 사용자가 바로 오늘 기록을 볼 수 있게 한다.
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadMonthEntries(_currentMonth);
    });
  }

  /// Reloads entries for the month currently focused in the calendar.
  /// Called by `MainTabs` when the user returns to this tab so the
  /// provider's cache can't be left pointing at a different month.
  void refreshCurrentMonth() {
    if (_currentMonth.isEmpty) return;
    // 사용자가 다른 탭 갔다 돌아왔을 때, 현재 보는 달이 오늘이 속한
    // 달이고 아무 날도 선택 안 됐으면 오늘을 디폴트로 다시 잡아준다.
    // 다른 달을 보고 있거나 이미 다른 날을 선택해뒀으면 그대로 둠.
    final todayMonth = formatYearMonth(DateTime.now());
    if (_selectedDay == null && _currentMonth == todayMonth) {
      setState(() => _selectedDay = DateTime.now());
    }
    context.read<DiaryProvider>().loadMonthEntries(_currentMonth);
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final isDark = context.isDark;
    final store = context.watch<DiaryProvider>();

    final entriesByDate = groupEntriesByDate(store.monthEntries);
    final aggregatesByDate = <String, DayAggregate>{
      for (final entry in entriesByDate.entries)
        entry.key: DayAggregate.fromEntries(entry.key, entry.value),
    };

    final selectedEntries = _selectedDay == null
        ? const <DiaryEntry>[]
        : (entriesByDate[_ymd(_selectedDay!)] ?? const []);
    final selectedAggregate = _selectedDay == null
        ? null
        : aggregatesByDate[_ymd(_selectedDay!)];

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(loc.calendarTitle,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17, color: palette.text)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
            Container(
              margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              padding: const EdgeInsets.only(bottom: 8),
              child: TableCalendar<DiaryEntry>(
                locale: loc.localeName,
                firstDay: DateTime.utc(2000, 1, 1),
                lastDay: DateTime.utc(2100, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                    _selectedDay != null && isSameDay(_selectedDay, d),
                eventLoader: (day) =>
                    entriesByDate[_ymd(day)] ?? const <DiaryEntry>[],
                startingDayOfWeek: StartingDayOfWeek.sunday,
                onPageChanged: (focused) {
                  setState(() {
                    _focusedDay = focused;
                    _currentMonth = formatYearMonth(focused);
                    _selectedDay = null;
                  });
                  context.read<DiaryProvider>().loadMonthEntries(_currentMonth);
                },
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: TextStyle(color: palette.text),
                  weekendTextStyle: TextStyle(color: palette.text),
                  todayDecoration: BoxDecoration(
                    color: palette.tabBarActive.withAlpha(0x33),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: palette.tabBarActive, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  selectedTextStyle: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: palette.text,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: palette.tabBarActive),
                  rightChevronIcon: Icon(Icons.chevron_right, color: palette.tabBarActive),
                ),
                daysOfWeekStyle: DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: palette.textSecondary),
                  weekendStyle: TextStyle(color: palette.textSecondary),
                ),
                calendarBuilders: CalendarBuilders<DiaryEntry>(
                  markerBuilder: (context, day, events) => null,
                  defaultBuilder: (context, day, focused) {
                    final agg = aggregatesByDate[_ymd(day)];
                    if (agg == null) return null;
                    final bg = agg.hasAnalysis
                        ? hexToColor(agg.color)
                        : palette.border;
                    final fg = agg.hasAnalysis ? Colors.white : palette.text;
                    return _DayCell(
                      day: day.day,
                      bg: bg,
                      fg: fg,
                      count: agg.entryCount,
                    );
                  },
                  selectedBuilder: (context, day, focused) {
                    final agg = aggregatesByDate[_ymd(day)];
                    final hasEntry = agg != null && agg.hasAnalysis;
                    final bg = hasEntry
                        ? hexToColor(agg.color)
                        : Colors.transparent;
                    final textColor = hasEntry ? Colors.white : palette.text;
                    final borderColor =
                        isDark ? Colors.white : const Color(0xFF1A1A2E);
                    return _DayCell(
                      day: day.day,
                      bg: bg,
                      fg: textColor,
                      count: agg?.entryCount ?? 0,
                      borderColor: borderColor,
                    );
                  },
                ),
              ),
            ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child:
                      _buildDetail(palette, selectedEntries, selectedAggregate),
                ),
              ],
            ),
          ),
        ),
        const BannerAdSlot(),
      ]),
    );
  }

  Widget _buildDetail(
    AppPalette palette,
    List<DiaryEntry> entries,
    DayAggregate? aggregate,
  ) {
    if (_selectedDay != null && entries.isNotEmpty) {
      final ordered = entries.reversed.toList();
      final showAverage = aggregate != null && aggregate.hasAnalysis;
      return Column(
        children: [
          if (showAverage) ...[
            DayAverageCard(aggregate: aggregate),
            const SizedBox(height: 16),
          ],
          for (var i = 0; i < ordered.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
              child: DiaryDetailCard(entry: ordered[i]),
            ),
        ],
      );
    }
    final loc = AppLocalizations.of(context);
    final emoji = _selectedDay == null ? '👆' : '📝';
    final text = _selectedDay == null
        ? loc.calendarTapHint
        : loc.calendarNoEntryForDate;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final Color bg;
  final Color fg;
  final int count;
  final Color? borderColor;

  const _DayCell({
    required this.day,
    required this.bg,
    required this.fg,
    required this.count,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 2.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(color: fg, fontWeight: FontWeight.w700),
          ),
        ),
        if (count > 1)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1A1A2E).withAlpha(0x33),
                  width: 0.5,
                ),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
