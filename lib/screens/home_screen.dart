import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
import '../services/ads_service.dart';
import '../services/emotion_analyzer.dart';
import '../widgets/today_entry_card.dart';
import '../widgets/weekly_insight_block.dart';
import 'backup_screen.dart';
import 'settings_screen.dart';

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
      final store = context.read<DiaryProvider>();
      store.loadTodayEntries();
      store.loadDailyBonus();
      store.loadLatestInsight();
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

  Future<void> _handleBonusUnlock(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await context.read<DiaryProvider>().watchAdForBonus();
    if (!mounted) return;
    final message = switch (outcome) {
      RewardedOutcome.earned => loc.todayEntryBonusUnlocked(kRewardBonusPerAd),
      RewardedOutcome.dismissedEarly => loc.todayEntryBonusAdIncomplete,
      RewardedOutcome.notReady ||
      RewardedOutcome.failed =>
        loc.adsNotReadyMessage,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
  }

  Future<void> _handleSave() async {
    final loc = AppLocalizations.of(context);
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      _showSnack(loc.todayEntryEmptyContent);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await context.read<DiaryProvider>().createDiary(trimmed);
      if (!mounted) return;
      _controller.clear();
      _focus.unfocus();
      _showSnack(loc.homeEntrySavedToast);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final store = context.watch<DiaryProvider>();

    final today = DateTime.now();
    final localeName = loc.localeName;
    // ko: '5월 12일 월요일' 패턴을 호환하려면 ICU에 dateLabel/dayLabel을 따로
    // 넘긴다. en 로케일에선 dayLabel은 비워두고 dateLabel만 사용.
    final isKo = localeName.startsWith('ko');
    final dateLabel = isKo
        ? DateFormat.yMMMd('ko').format(today)
        : DateFormat.yMMMMd(localeName).format(today);
    final dayLabel = isKo
        ? DateFormat.E('ko').format(today).replaceAll('요일', '')
        : DateFormat.EEEE(localeName).format(today);

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
            tooltip: loc.backupTitle,
            icon: Icon(Icons.cloud_sync_rounded, color: palette.tabBarActive),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const BackupScreen(),
              ));
            },
          ),
          IconButton(
            tooltip: loc.settingsTitle,
            icon: Icon(Icons.settings_rounded, color: palette.tabBarActive),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const SettingsScreen(),
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
                loc.homeDateHeading(dateLabel, dayLabel),
                style: TextStyle(fontSize: 14, color: palette.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                loc.homeTodayHeading,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              const WeeklyInsightBlock(),
              const SizedBox(height: 16),
              _buildComposer(palette, loc),
              if (entries.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      loc.homeTodayEntries,
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
                      max: store.effectiveDailyLimit,
                      palette: palette,
                    ),
                  ],
                ),
                if (store.dailyAnalysisLimitReached && store.canWatchBonusAd) ...[
                  const SizedBox(height: 10),
                  _BonusUnlockButton(
                    palette: palette,
                    adsRemaining: store.todayBonusAdsRemaining,
                    onTap: () => _handleBonusUnlock(context),
                  ),
                ],
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

  Widget _buildComposer(AppPalette palette, AppLocalizations loc) {
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
              hintText: loc.homeComposerHint,
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
                      : Text(loc.homeAddEntryButton,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
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
    final loc = AppLocalizations.of(context);
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
            loc.homeDailyQuotaBadge(used, max),
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

class _BonusUnlockButton extends StatelessWidget {
  final AppPalette palette;
  final int adsRemaining;
  final VoidCallback onTap;

  const _BonusUnlockButton({
    required this.palette,
    required this.adsRemaining,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.card_giftcard_rounded,
            size: 18, color: palette.tabBarActive),
        label: Text(
          loc.todayEntryBonusAdButton(kRewardBonusPerAd, adsRemaining),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: palette.tabBarActive,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.tabBarActive.withAlpha(0x55)),
          backgroundColor: palette.tabBarActive.withAlpha(0x10),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
