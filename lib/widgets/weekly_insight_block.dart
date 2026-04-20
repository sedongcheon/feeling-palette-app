import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/theme.dart';
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
                '이번 주 인사이트',
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
                ? '최근 기록에서 패턴을 찾아드릴 수 있어요.\n첫 인사이트를 만들어볼까요?'
                : '일기가 쌓이면 요즘의 감정 흐름을 먼저 말씀드릴게요.\n일기를 조금 더 써볼까요?',
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: palette.text,
            ),
          ),
          if (hasEnoughData) ...[
            const SizedBox(height: 12),
            _GenerateButton(palette: palette, label: '첫 인사이트 만들기'),
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
                insight.careFlag ? '이번 주, 조금 더 챙겨요' : '이번 주 인사이트',
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
                    ? '새로고침 가능'
                    : '$daysLeft일 후 갱신',
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
            label: cooldownElapsed ? '새로고침' : '주간 새로고침 대기 중',
            disabledReasonLabel: cooldownElapsed ? null : '$daysLeft일 남음',
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
    late final IconData icon;
    late final String label;
    switch (trend) {
      case InsightTrend.up:
        icon = Icons.trending_up_rounded;
        label = '상승';
        break;
      case InsightTrend.down:
        icon = Icons.trending_down_rounded;
        label = '하강';
        break;
      case InsightTrend.stable:
        icon = Icons.horizontal_rule_rounded;
        label = '안정';
        break;
      case InsightTrend.mixed:
        icon = Icons.compare_arrows_rounded;
        label = '혼재';
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
            label,
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
    final store = context.watch<DiaryProvider>();
    final monthKey = formatYearMonth(DateTime.now());
    final inFlight = store.isInsightInFlight;
    final cooldownElapsed = store.insightCooldownElapsed;
    final canFree = store.canGenerateInsightFree(monthKey);
    final canAd = store.canWatchAdForInsight(monthKey);
    final disabled = !cooldownElapsed || inFlight || (!canFree && !canAd);

    final effectiveLabel = inFlight
        ? '생성 중…'
        : (!cooldownElapsed
            ? label
            : (canFree
                ? label
                : (canAd ? '광고 보고 $label' : '이번 달 한도 소진')));

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
        ..showSnackBar(const SnackBar(
          content: Text('이번 주 인사이트를 만들었어요.'),
          behavior: SnackBarBehavior.floating,
        ));
    } on WeeklyInsightCooldownException {
      _snack(messenger, '아직 새로고침할 시기가 아니에요.');
    } on WeeklyInsightQuotaException {
      _snack(messenger, '이번 달 한도를 모두 사용했어요.');
    } on WeeklyInsightAdException {
      _snack(messenger, '광고를 끝까지 시청해야 생성할 수 있어요.');
    } on WeeklyInsightNotEnoughDataException {
      _snack(messenger, '패턴을 찾기엔 기록이 조금 부족해요.');
    } catch (e) {
      _snack(messenger, '생성 중 문제가 발생했어요.');
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
