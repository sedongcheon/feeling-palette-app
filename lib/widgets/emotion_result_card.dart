import 'package:flutter/material.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../models/diary.dart';

class EmotionResultCard extends StatelessWidget {
  final DiaryEntry entry;
  const EmotionResultCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = emotionInfoOf(entry.primaryEmotion);
    final entryColor = hexToColor(entry.color);

    final bars = entry.emotions.toMap().entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entry.aiComment.isEmpty && bars.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: entryColor.withAlpha(0x40), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: entryColor.withAlpha(0x20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(primary.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 6),
                Text(
                  primary.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: entryColor,
                  ),
                ),
              ],
            ),
          ),
          if (bars.isNotEmpty) ...[
            const SizedBox(height: 14),
            Column(
              children: [
                for (final entry in bars) ...[
                  _BarRow(type: entry.key, score: entry.value, palette: palette),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ],
          if (entry.aiComment.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.aiComment,
                style: TextStyle(
                  fontSize: 14,
                  height: 22 / 14,
                  color: palette.text,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  final EmotionType type;
  final int score;
  final AppPalette palette;

  const _BarRow({required this.type, required this.score, required this.palette});

  @override
  Widget build(BuildContext context) {
    final info = emotionInfoOf(type);
    return Row(
      children: [
        SizedBox(width: 22, child: Text(info.emoji, style: const TextStyle(fontSize: 14))),
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
