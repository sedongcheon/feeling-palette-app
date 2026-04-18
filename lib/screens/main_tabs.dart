import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../providers/diary_provider.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'timeline_screen.dart';

class MainTabs extends StatefulWidget {
  const MainTabs({super.key});

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  int _index = 0;

  final GlobalKey<CalendarScreenState> _calendarKey =
      GlobalKey<CalendarScreenState>();

  late final List<Widget> _tabs = [
    const HomeScreen(),
    CalendarScreen(key: _calendarKey),
    const StatsScreen(),
    const TimelineScreen(),
  ];

  static const _items = <_TabItem>[
    _TabItem(icon: Icons.edit_note_rounded, label: '오늘'),
    _TabItem(icon: Icons.calendar_month_rounded, label: '캘린더'),
    _TabItem(icon: Icons.bubble_chart_rounded, label: '통계'),
    _TabItem(icon: Icons.auto_stories_rounded, label: '타임라인'),
  ];

  void _handleTap(int i) {
    if (i == _index) return;
    setState(() => _index = i);
    final store = context.read<DiaryProvider>();
    switch (i) {
      case 0:
        store.loadTodayEntries();
        store.loadDailyBonus();
        break;
      case 1:
        _calendarKey.currentState?.refreshCurrentMonth();
        break;
      case 2:
        store.loadMonthEntries(formatYearMonth(DateTime.now()));
        break;
      case 3:
        store.loadTimelineEntries(limit: 20, offset: 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: _CutieBottomBar(
        index: _index,
        items: _items,
        palette: palette,
        onTap: _handleTap,
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _CutieBottomBar extends StatelessWidget {
  final int index;
  final List<_TabItem> items;
  final AppPalette palette;
  final ValueChanged<int> onTap;

  const _CutieBottomBar({
    required this.index,
    required this.items,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.tabBar,
        boxShadow: [
          BoxShadow(
            color: palette.tabBarActive.withAlpha(0x14),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _CutieTab(
                    item: items[i],
                    selected: i == index,
                    palette: palette,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CutieTab extends StatelessWidget {
  final _TabItem item;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _CutieTab({
    required this.item,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = palette.tabBarActive;
    final color = selected ? activeColor : palette.tabBarInactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? activeColor.withAlpha(0x1F) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              scale: selected ? 1.12 : 1.0,
              child: Icon(item.icon, size: 24, color: color),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}
