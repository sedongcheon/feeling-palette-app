import 'package:flutter/material.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../models/diary.dart';

class DayAverageCard extends StatelessWidget {
  final DayAggregate aggregate;

  const DayAverageCard({super.key, required this.aggregate});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = emotionInfoOf(aggregate.primaryEmotion);
    final color = hexToColor(aggregate.color);

    final bars = aggregate.emotions.toMap().entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (bars.isEmpty) return const SizedBox.shrink();

    final parts = aggregate.date.split('-');
    final dateLabel =
        '${int.parse(parts[1])}월 ${int.parse(parts[2])}일 평균';

    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(0x40), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withAlpha(0x18),
              border: Border(
                bottom: BorderSide(
                  color: color.withAlpha(0x30),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, size: 16, color: color),
                const SizedBox(width: 6),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(0x28),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${aggregate.analyzedCount}개 기록',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(0x20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(primary.emoji,
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        primary.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Column(
                  children: [
                    for (final bar in bars) ...[
                      _BarRow(
                          type: bar.key, score: bar.value, palette: palette),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final EmotionType type;
  final int score;
  final AppPalette palette;

  const _BarRow({
    required this.type,
    required this.score,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    final info = emotionInfoOf(type);
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(info.emoji, style: const TextStyle(fontSize: 14)),
        ),
        SizedBox(
          width: 30,
          child: Text(
            info.label,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: palette.border),
                FractionallySizedBox(
                  widthFactor: (score / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: info.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            '$score',
            textAlign: TextAlign.right,
            style: TextStyle(fontSize: 12, color: palette.textSecondary),
          ),
        ),
      ],
    );
  }
}
