import 'package:flutter/material.dart';

import '../models/diary.dart';

class EmotionInfo {
  final EmotionType key;
  final String label;
  final String emoji;
  final Color color;
  final String hex;

  const EmotionInfo({
    required this.key,
    required this.label,
    required this.emoji,
    required this.color,
    required this.hex,
  });
}

const Map<EmotionType, EmotionInfo> kEmotions = {
  EmotionType.joy: EmotionInfo(
    key: EmotionType.joy,
    label: '기쁨',
    emoji: '😊',
    color: Color(0xFFFFD700),
    hex: '#FFD700',
  ),
  EmotionType.sadness: EmotionInfo(
    key: EmotionType.sadness,
    label: '슬픔',
    emoji: '😢',
    color: Color(0xFF4A90D9),
    hex: '#4A90D9',
  ),
  EmotionType.anger: EmotionInfo(
    key: EmotionType.anger,
    label: '분노',
    emoji: '😠',
    color: Color(0xFFE74C3C),
    hex: '#E74C3C',
  ),
  EmotionType.anxiety: EmotionInfo(
    key: EmotionType.anxiety,
    label: '불안',
    emoji: '😰',
    color: Color(0xFF9B59B6),
    hex: '#9B59B6',
  ),
  EmotionType.calm: EmotionInfo(
    key: EmotionType.calm,
    label: '평온',
    emoji: '😌',
    color: Color(0xFF2ECC71),
    hex: '#2ECC71',
  ),
  EmotionType.excitement: EmotionInfo(
    key: EmotionType.excitement,
    label: '설렘',
    emoji: '🥰',
    color: Color(0xFFFF69B4),
    hex: '#FF69B4',
  ),
};

EmotionInfo emotionInfoOf(EmotionType type) => kEmotions[type]!;

Color hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  final value = int.tryParse(cleaned, radix: 16) ?? 0x9CA3AF;
  return Color(0xFF000000 | value);
}

/// Summary of a single day composed of one or more diary entries.
/// Emotion scores are averaged across analyzed entries; [primaryEmotion]
/// is the argmax of the averaged scores.
class DayAggregate {
  final String date;
  final int entryCount;
  final int analyzedCount;
  final EmotionType primaryEmotion;
  final EmotionScores emotions;
  final String color;

  const DayAggregate({
    required this.date,
    required this.entryCount,
    required this.analyzedCount,
    required this.primaryEmotion,
    required this.emotions,
    required this.color,
  });

  bool get hasAnalysis => analyzedCount > 0;

  static DayAggregate fromEntries(String date, List<DiaryEntry> entries) {
    final analyzed = entries.where((e) => e.aiComment.isNotEmpty).toList();
    if (analyzed.isEmpty) {
      return DayAggregate(
        date: date,
        entryCount: entries.length,
        analyzedCount: 0,
        primaryEmotion: EmotionType.calm,
        emotions: EmotionScores.empty,
        color: '#9CA3AF',
      );
    }
    final n = analyzed.length;
    int avg(EmotionType t) {
      final sum = analyzed.fold<int>(0, (acc, e) => acc + e.emotions.scoreOf(t));
      return (sum / n).round();
    }

    final averaged = EmotionScores(
      joy: avg(EmotionType.joy),
      sadness: avg(EmotionType.sadness),
      anger: avg(EmotionType.anger),
      anxiety: avg(EmotionType.anxiety),
      calm: avg(EmotionType.calm),
      excitement: avg(EmotionType.excitement),
    );

    EmotionType primary = EmotionType.calm;
    int best = -1;
    for (final entry in averaged.toMap().entries) {
      if (entry.value > best) {
        best = entry.value;
        primary = entry.key;
      }
    }

    return DayAggregate(
      date: date,
      entryCount: entries.length,
      analyzedCount: n,
      primaryEmotion: primary,
      emotions: averaged,
      color: emotionInfoOf(primary).hex,
    );
  }
}
