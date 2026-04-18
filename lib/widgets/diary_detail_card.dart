import 'package:flutter/material.dart';

import '../constants/emotions.dart';
import '../constants/theme.dart';
import '../models/diary.dart';
import 'emotion_result_card.dart';

class DiaryDetailCard extends StatelessWidget {
  final DiaryEntry entry;
  const DiaryDetailCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = emotionInfoOf(entry.primaryEmotion);
    final hasAnalysis = entry.aiComment.isNotEmpty;
    final entryColor = hexToColor(entry.color);

    final parts = entry.date.split('-');
    final dateObj =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[dateObj.weekday - 1];
    final t = DateTime.fromMillisecondsSinceEpoch(entry.createdAt);
    final hour12 = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final period = t.hour < 12 ? '오전' : '오후';
    final mm = t.minute.toString().padLeft(2, '0');
    final dateLabel =
        '${int.parse(parts[1])}월 ${int.parse(parts[2])}일 $dayName요일 · $period $hour12:$mm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: palette.text,
                ),
              ),
              if (hasAnalysis)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: entryColor.withAlpha(0x20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(primary.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        primary.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: entryColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: Text(
            entry.content,
            style: TextStyle(fontSize: 15, height: 24 / 15, color: palette.text),
          ),
        ),
        if (hasAnalysis) EmotionResultCard(entry: entry),
      ],
    );
  }
}
