import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/diary.dart';
import '../models/weekly_insight.dart';
import '../providers/diary_provider.dart';

/// Home-screen card that shows the most recently generated weekly insight
/// and provides entry points to generate a new one (free quota or rewarded
/// ad), subject to a 7-day cooldown and per-month quota.
class WeeklyInsightBlock extends StatelessWidget {
  const WeeklyInsightBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final store = context.watch<DiaryProvider>();
    if (!store.hasInsightLoaded) {
      return const SizedBox.shrink();
    }

    final insight = store.latestInsight;
    if (insight == null) {
      final enough = store.monthEntries.length + store.todayEntries.length >=
          kWeeklyInsightMinEntries;
      return _EmptyInsightCard(palette: palette, hasEnoughData: enough);
    }
    return _InsightCard(palette: palette, insight: insight);
  }
}

class _EmptyInsightCard extends StatelessWidget {
  final AppPalette palette;
  final bool hasEnoughData;
  const _EmptyInsightCard({
    required this.palette,
    required this.hasEnoughData,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.tabBarActive.withAlpha(0x10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.tabBarActive.withAlpha(0x33)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: palette.tabBarActive),
              const SizedBox(width: 6),
              Text(
                loc.weeklyInsightTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: palette.tabBarActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasEnoughData
                ? loc.weeklyInsightEmptyReady
                : loc.weeklyInsightEmptyNeedMore,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: palette.text,
            ),
          ),
          if (hasEnoughData) ...[
            const SizedBox(height: 12),
            _GenerateButton(palette: palette, label: loc.weeklyInsightCreateFirst),
          ],
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AppPalette palette;
  final WeeklyInsight insight;
  const _InsightCard({required this.palette, required this.insight});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final store = context.watch<DiaryProvider>();
    final cooldownElapsed = store.insightCooldownElapsed;
    final daysLeft = store.insightDaysUntilRefresh;
    final accent = insight.careFlag
        ? const Color(0xFF9B59B6) // 부드러운 보라 — 케어 톤
        : palette.tabBarActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withAlpha(0x10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withAlpha(0x33)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                insight.careFlag
                    ? Icons.favorite_rounded
                    : Icons.lightbulb_outline_rounded,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 6),
              Text(
                insight.careFlag
                    ? loc.weeklyInsightCareTitle
                    : loc.weeklyInsightTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              const Spacer(),
              _TrendChip(trend: insight.trend, accent: accent),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            insight.insightText,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (insight.keyword != null && insight.keyword!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withAlpha(0x22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '#${insight.keyword}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              const Spacer(),
              Text(
                cooldownElapsed
                    ? loc.weeklyInsightRefreshable
                    : loc.weeklyInsightRefreshIn(daysLeft),
                style: TextStyle(
                  fontSize: 11,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _GenerateButton(
            palette: palette,
            label: cooldownElapsed
                ? loc.weeklyInsightRefresh
                : loc.weeklyInsightWaitingRefresh,
            disabledReasonLabel:
                cooldownElapsed ? null : loc.weeklyInsightDaysLeft(daysLeft),
          ),
        ],
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final InsightTrend trend;
  final Color accent;
  const _TrendChip({required this.trend, required this.accent});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    late final IconData icon;
    switch (trend) {
      case InsightTrend.up:
        icon = Icons.trending_up_rounded;
        break;
      case InsightTrend.down:
        icon = Icons.trending_down_rounded;
        break;
      case InsightTrend.stable:
        icon = Icons.horizontal_rule_rounded;
        break;
      case InsightTrend.mixed:
        icon = Icons.compare_arrows_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withAlpha(0x18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 3),
          Text(
            loc.weeklyInsightTrendLabel(trend.name),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  final AppPalette palette;
  final String label;
  final String? disabledReasonLabel;
  const _GenerateButton({
    required this.palette,
    required this.label,
    this.disabledReasonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final store = context.watch<DiaryProvider>();
    final monthKey = formatYearMonth(DateTime.now());
    final inFlight = store.isInsightInFlight;
    final cooldownElapsed = store.insightCooldownElapsed;
    final canFree = store.canGenerateInsightFree(monthKey);
    final canAd = store.canWatchAdForInsight(monthKey);
    final disabled = !cooldownElapsed || inFlight || (!canFree && !canAd);

    final effectiveLabel = inFlight
        ? loc.weeklyInsightGenerating
        : (!cooldownElapsed
            ? label
            : (canFree
                ? label
                : (canAd ? loc.weeklyInsightAdLabel(label) : loc.weeklyInsightMonthlyLimit)));

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed:
            disabled ? null : () => _handleTap(context, viaAdOnly: !canFree),
        icon: inFlight
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                canFree ? Icons.refresh_rounded : Icons.card_giftcard_rounded,
                size: 16,
                color: palette.tabBarActive,
              ),
        label: Text(
          disabledReasonLabel != null && !cooldownElapsed
              ? '$label · $disabledReasonLabel'
              : effectiveLabel,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: disabled ? palette.textSecondary : palette.tabBarActive,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: disabled
                ? palette.border
                : palette.tabBarActive.withAlpha(0x55),
          ),
          backgroundColor:
              disabled ? null : palette.tabBarActive.withAlpha(0x10),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context,
      {required bool viaAdOnly}) async {
    final loc = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final store = context.read<DiaryProvider>();
    try {
      if (viaAdOnly) {
        await store.generateInsightViaAd();
      } else {
        await store.generateInsightWithFreeSlot();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(loc.weeklyInsightCreatedToast),
          behavior: SnackBarBehavior.floating,
        ));
    } on WeeklyInsightCooldownException {
      _snack(messenger, loc.weeklyInsightCooldownError);
    } on WeeklyInsightQuotaException {
      _snack(messenger, loc.weeklyInsightQuotaError);
    } on WeeklyInsightAdException {
      _snack(messenger, loc.weeklyInsightAdError);
    } on WeeklyInsightNotEnoughDataException {
      _snack(messenger, loc.weeklyInsightNotEnoughData);
    } catch (e) {
      _snack(messenger, loc.weeklyInsightGenericError);
    }
  }

  void _snack(ScaffoldMessengerState messenger, String msg) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }
}
