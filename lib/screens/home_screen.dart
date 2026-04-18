import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
import '../services/emotion_analyzer.dart';
import '../widgets/today_entry_card.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _maxLength = 1000;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _isSaving = false;

  final EmotionAnalyzer _analyzer = EmotionAnalyzer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadTodayEntries();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _handleSave() async {
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      _showSnack('일기 내용을 입력해주세요.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<DiaryProvider>().createDiary(trimmed);
      if (!mounted) return;
      _controller.clear();
      _focus.unfocus();
      _showSnack('오늘의 일기가 저장되었어요.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final store = context.watch<DiaryProvider>();

    final today = DateTime.now();
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dateStr = '${today.year}년 ${today.month}월 ${today.day}일';
    final dayStr = dayNames[today.weekday - 1];

    final entries = store.todayEntries;
    final reversed = entries.reversed.toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Feeling Palette',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: palette.tabBarActive,
          ),
        ),
        actions: [
          IconButton(
            tooltip: '백업 / 복원',
            icon: Icon(Icons.cloud_sync_rounded, color: palette.tabBarActive),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const BackupScreen(),
              ));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dateStr $dayStr요일',
                style: TextStyle(fontSize: 14, color: palette.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                '오늘 하루는 어땠나요?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              _buildComposer(palette),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      '오늘의 기록',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: palette.tabBarActive.withAlpha(0x22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${entries.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: palette.tabBarActive,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _DailyQuotaBadge(
                      used: store.todayAnalyzedCount,
                      max: kMaxDailyAnalyzedEntries,
                      palette: palette,
                    ),
                  ],
                ),
                for (final entry in reversed)
                  TodayEntryCard(
                    key: ValueKey(entry.id),
                    entry: entry,
                    analyzer: _analyzer,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focus,
            maxLength: _maxLength,
            maxLines: null,
            minLines: 5,
            style:
                TextStyle(fontSize: 16, height: 26 / 16, color: palette.text),
            decoration: InputDecoration(
              hintText: '오늘 있었던 일, 느낀 감정을 자유롭게 적어보세요...',
              hintStyle: TextStyle(color: palette.textSecondary),
              border: InputBorder.none,
              counterText: '',
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: palette.border, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_controller.text.length}/$_maxLength',
                  style:
                      TextStyle(fontSize: 12, color: palette.textSecondary),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isSaving || _controller.text.trim().isEmpty ? null : _handleSave,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('기록 추가',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.tabBarActive,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    minimumSize: const Size(60, 40),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyQuotaBadge extends StatelessWidget {
  final int used;
  final int max;
  final AppPalette palette;

  const _DailyQuotaBadge({
    required this.used,
    required this.max,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final reached = used >= max;
    final color = reached ? const Color(0xFFE74C3C) : palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: reached
            ? const Color(0xFFE74C3C).withAlpha(0x18)
            : palette.border.withAlpha(0x66),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            'AI 분석 $used/$max',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
