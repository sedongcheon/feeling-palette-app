import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../providers/diary_provider.dart';
import '../screens/recommend_screen.dart';
import '../services/ads_service.dart';
import '../services/api_locale.dart';
import '../services/emotion_analyzer.dart';
import '../services/recommend_cache.dart';
import 'emotion_result_card.dart';

class TodayEntryCard extends StatefulWidget {
  final DiaryEntry entry;
  final EmotionAnalyzer analyzer;

  const TodayEntryCard({
    super.key,
    required this.entry,
    required this.analyzer,
  });

  @override
  State<TodayEntryCard> createState() => _TodayEntryCardState();
}

class _TodayEntryCardState extends State<TodayEntryCard> {
  static const int _maxLength = 1000;

  late final TextEditingController _controller =
      TextEditingController(text: widget.entry.content);
  bool _isEditing = false;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isOpeningRecommend = false;

  @override
  void didUpdateWidget(covariant TodayEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.entry.content != widget.entry.content) {
      _controller.text = widget.entry.content;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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

  Future<void> _runAnalysis() async {
    final loc = AppLocalizations.of(context);
    if (!widget.entry.canAnalyze) {
      _showSnack(loc.todayEntryMaxAnalysisHit(kMaxAnalysisCount));
      return;
    }
    final store = context.read<DiaryProvider>();
    if (widget.entry.analysisCount == 0 && store.dailyAnalysisLimitReached) {
      _showSnack(loc.todayEntryDailyLimitHit(store.effectiveDailyLimit));
      return;
    }
    setState(() => _isAnalyzing = true);
    try {
      final result = await widget.analyzer.analyze(
        widget.entry.content,
        locale: apiLocaleOf(context),
      );
      final updated = await store.applyAnalysis(
        id: widget.entry.id,
        primaryEmotion: result.primaryEmotion,
        emotions: result.emotions,
        aiComment: result.comment,
        color: result.color,
      );
      if (!mounted || updated == null) return;
      final used = updated.analysisCount;
      final remaining = updated.remainingAnalyses;
      final dailyUsed = store.todayAnalyzedCount;
      final dailyLimit = store.effectiveDailyLimit;
      _showSnack(
        remaining == 0
            ? loc.todayEntryAnalysisCompleteMaxed(
                kMaxAnalysisCount, dailyUsed, dailyLimit)
            : loc.todayEntryAnalysisComplete(
                used, kMaxAnalysisCount, remaining, dailyUsed, dailyLimit),
      );
      AdsService.instance.onAnalysisCompleted();
    } on DailyAnalysisLimitException {
      if (!mounted) return;
      _showSnack(loc.todayEntryDailyLimitHit(store.effectiveDailyLimit));
    } catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          final dialogLoc = AppLocalizations.of(ctx);
          return AlertDialog(
            title: Text(dialogLoc.todayEntryAnalysisErrorTitle),
            content: Text(dialogLoc.todayEntryAnalysisErrorMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(dialogLoc.commonOk),
              ),
            ],
          );
        },
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _save() async {
    final loc = AppLocalizations.of(context);
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) {
      _showSnack(loc.todayEntryEmptyContent);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final outcome = await context
          .read<DiaryProvider>()
          .updateDiary(id: widget.entry.id, content: trimmed);
      if (!mounted) return;
      setState(() => _isEditing = false);
      if (outcome != null && outcome.analysisLocked) {
        _showSnack(loc.todayEntryAnalysisLocked(kMaxAnalysisCount));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEdit() {
    setState(() {
      _controller.text = widget.entry.content;
      _isEditing = false;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(loc.todayEntryDeleteDialogTitle),
          content: Text(loc.todayEntryDeleteDialogMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.commonDelete,
                  style: const TextStyle(color: Color(0xFFE74C3C))),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await context.read<DiaryProvider>().removeDiary(widget.entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final loc = AppLocalizations.of(context);
    final entry = widget.entry;
    final hasAnalysis = entry.aiComment.isNotEmpty;
    final store = context.watch<DiaryProvider>();
    final dailyBlocked =
        entry.analysisCount == 0 && store.dailyAnalysisLimitReached;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
            child: Row(
              children: [
                Text(
                  _formatTime(context, entry.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (!_isEditing)
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: palette.textSecondary),
                    tooltip: loc.todayEntryEditTooltip,
                    onPressed: () => setState(() => _isEditing = true),
                  ),
                if (!_isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFE74C3C)),
                    tooltip: loc.todayEntryDeleteTooltip,
                    onPressed: _delete,
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _isEditing
                ? _buildEditor(palette, loc)
                : _buildViewer(palette, entry.content),
          ),
          if (_isAnalyzing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF69B4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    loc.todayEntryAnalyzing,
                    style: TextStyle(
                        fontSize: 13, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
          if (hasAnalysis && !_isAnalyzing && !_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: EmotionResultCard(entry: entry),
            ),
          if (hasAnalysis && !_isAnalyzing && !_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildRecommendButton(palette, loc),
            ),
          if (!hasAnalysis && !_isAnalyzing && !_isEditing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildAnalyzeButton(palette, loc, store, dailyBlocked),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeButton(
    AppPalette palette,
    AppLocalizations loc,
    DiaryProvider store,
    bool dailyBlocked,
  ) {
    final entry = widget.entry;
    // Per-entry cap is hit: nothing to offer, show disabled state.
    if (!entry.canAnalyze) {
      return _analyzeButton(
        palette: palette,
        label: loc.todayEntryAnalyzeCapHit,
        onPressed: null,
      );
    }
    // Daily limit hit but user still has bonus ad views available:
    // offer the rewarded-ad unlock right from the card.
    if (dailyBlocked && store.canWatchBonusAd) {
      return _analyzeButton(
        palette: palette,
        label: loc.todayEntryBonusAdButton(
            kRewardBonusPerAd, store.todayBonusAdsRemaining),
        icon: Icons.card_giftcard_rounded,
        onPressed: _handleBonusUnlock,
      );
    }
    // Daily limit hit and no more ads left today.
    if (dailyBlocked) {
      return _analyzeButton(
        palette: palette,
        label: loc.todayEntryDailyLimitButton,
        onPressed: null,
      );
    }
    // Normal state.
    return _analyzeButton(
      palette: palette,
      label: loc.todayEntryAnalyzeButton(
          entry.remainingAnalyses, kMaxAnalysisCount),
      onPressed: _runAnalysis,
    );
  }

  Widget _analyzeButton({
    required AppPalette palette,
    required String label,
    required VoidCallback? onPressed,
    IconData icon = Icons.auto_awesome_rounded,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.tabBarActive,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildRecommendButton(AppPalette palette, AppLocalizations loc) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _isOpeningRecommend ? null : _openRecommend,
        icon: _isOpeningRecommend
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.tabBarActive,
                ),
              )
            : Icon(Icons.card_giftcard_rounded,
                size: 18, color: palette.tabBarActive),
        label: Text(
          loc.recommendCtaLabel,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: palette.tabBarActive,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: BorderSide(color: palette.tabBarActive.withAlpha(0x66)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _openRecommend() async {
    final loc = AppLocalizations.of(context);
    final locale = apiLocaleOf(context);
    final content = widget.entry.content;
    // 세션 캐시 hit이면 광고 skip — 같은 일기에 대한 재진입은 이미 본 광고
    // 한 번의 보상으로 자유롭게 다시 볼 수 있게 한다.
    final cached =
        RecommendCache.instance.get(content: content, locale: locale);
    if (cached != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              RecommendScreen(content: content, locale: locale),
        ),
      );
      return;
    }
    setState(() => _isOpeningRecommend = true);
    try {
      final outcome = await AdsService.instance.showRewarded();
      if (!mounted) return;
      switch (outcome) {
        case RewardedOutcome.earned:
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecommendScreen(
                content: content,
                locale: locale,
              ),
            ),
          );
        case RewardedOutcome.dismissedEarly:
          _showSnack(loc.recommendAdDismissed);
        case RewardedOutcome.notReady:
        case RewardedOutcome.failed:
          _showSnack(loc.recommendAdNotReady);
      }
    } finally {
      if (mounted) setState(() => _isOpeningRecommend = false);
    }
  }

  Future<void> _handleBonusUnlock() async {
    final loc = AppLocalizations.of(context);
    final outcome = await context.read<DiaryProvider>().watchAdForBonus();
    if (!mounted) return;
    final message = switch (outcome) {
      RewardedOutcome.earned => loc.todayEntryBonusUnlocked(kRewardBonusPerAd),
      RewardedOutcome.dismissedEarly => loc.todayEntryBonusAdIncomplete,
      RewardedOutcome.notReady ||
      RewardedOutcome.failed =>
        loc.adsNotReadyMessage,
    };
    _showSnack(message);
  }

  String _formatTime(BuildContext context, int ts) {
    final d = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateFormat.jm(AppLocalizations.of(context).localeName).format(d);
  }

  Widget _buildViewer(AppPalette palette, String content) {
    return Text(
      content,
      style: TextStyle(fontSize: 15, height: 24 / 15, color: palette.text),
    );
  }

  Widget _buildEditor(AppPalette palette, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          maxLength: _maxLength,
          maxLines: null,
          minLines: 4,
          autofocus: true,
          style: TextStyle(fontSize: 15, height: 24 / 15, color: palette.text),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_controller.text.length}/$_maxLength',
              style: TextStyle(fontSize: 12, color: palette.textSecondary),
            ),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _cancelEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: palette.border),
                    foregroundColor: palette.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(loc.commonCancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF69B4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: const Size(60, 36),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          loc.commonSave,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
