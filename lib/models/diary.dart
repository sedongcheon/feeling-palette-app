import 'dart:convert';

enum EmotionType { joy, sadness, anger, anxiety, calm, excitement }

EmotionType emotionFromString(String value) {
  return EmotionType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => EmotionType.calm,
  );
}

class EmotionScores {
  final int joy;
  final int sadness;
  final int anger;
  final int anxiety;
  final int calm;
  final int excitement;

  const EmotionScores({
    this.joy = 0,
    this.sadness = 0,
    this.anger = 0,
    this.anxiety = 0,
    this.calm = 0,
    this.excitement = 0,
  });

  static const empty = EmotionScores();

  int scoreOf(EmotionType type) {
    switch (type) {
      case EmotionType.joy:
        return joy;
      case EmotionType.sadness:
        return sadness;
      case EmotionType.anger:
        return anger;
      case EmotionType.anxiety:
        return anxiety;
      case EmotionType.calm:
        return calm;
      case EmotionType.excitement:
        return excitement;
    }
  }

  Map<EmotionType, int> toMap() => {
        EmotionType.joy: joy,
        EmotionType.sadness: sadness,
        EmotionType.anger: anger,
        EmotionType.anxiety: anxiety,
        EmotionType.calm: calm,
        EmotionType.excitement: excitement,
      };

  Map<String, dynamic> toJson() => {
        'joy': joy,
        'sadness': sadness,
        'anger': anger,
        'anxiety': anxiety,
        'calm': calm,
        'excitement': excitement,
      };

  factory EmotionScores.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v) {
      if (v is num) return v.round().clamp(0, 100);
      return 0;
    }

    return EmotionScores(
      joy: parse(json['joy']),
      sadness: parse(json['sadness']),
      anger: parse(json['anger']),
      anxiety: parse(json['anxiety']),
      calm: parse(json['calm']),
      excitement: parse(json['excitement']),
    );
  }

  factory EmotionScores.fromJsonString(String raw) {
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return EmotionScores.fromJson(decoded);
    } catch (_) {
      return EmotionScores.empty;
    }
  }

  String toJsonString() => jsonEncode(toJson());
}

const int kMaxAnalysisCount = 3;

class DiaryEntry {
  final String id;
  final String date; // YYYY-MM-DD
  final String content;
  final EmotionType primaryEmotion;
  final EmotionScores emotions;
  final String aiComment;
  final String color; // HEX
  final int createdAt;
  final int updatedAt;
  final int analysisCount;

  const DiaryEntry({
    required this.id,
    required this.date,
    required this.content,
    required this.primaryEmotion,
    required this.emotions,
    required this.aiComment,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.analysisCount = 0,
  });

  bool get canAnalyze => analysisCount < kMaxAnalysisCount;
  int get remainingAnalyses =>
      (kMaxAnalysisCount - analysisCount).clamp(0, kMaxAnalysisCount);

  DiaryEntry copyWith({
    String? content,
    EmotionType? primaryEmotion,
    EmotionScores? emotions,
    String? aiComment,
    String? color,
    int? updatedAt,
    int? analysisCount,
  }) {
    return DiaryEntry(
      id: id,
      date: date,
      content: content ?? this.content,
      primaryEmotion: primaryEmotion ?? this.primaryEmotion,
      emotions: emotions ?? this.emotions,
      aiComment: aiComment ?? this.aiComment,
      color: color ?? this.color,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      analysisCount: analysisCount ?? this.analysisCount,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'date': date,
        'content': content,
        'primary_emotion': primaryEmotion.name,
        'emotions_json': emotions.toJsonString(),
        'ai_comment': aiComment,
        'color': color,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'analysis_count': analysisCount,
      };

  factory DiaryEntry.fromRow(Map<String, Object?> row) {
    return DiaryEntry(
      id: row['id'] as String,
      date: row['date'] as String,
      content: row['content'] as String,
      primaryEmotion: emotionFromString(row['primary_emotion'] as String),
      emotions: EmotionScores.fromJsonString(row['emotions_json'] as String),
      aiComment: (row['ai_comment'] as String?) ?? '',
      color: (row['color'] as String?) ?? '#9CA3AF',
      createdAt: (row['created_at'] as num).toInt(),
      updatedAt: (row['updated_at'] as num).toInt(),
      analysisCount: (row['analysis_count'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Groups entries by date string (YYYY-MM-DD).
Map<String, List<DiaryEntry>> groupEntriesByDate(List<DiaryEntry> entries) {
  final map = <String, List<DiaryEntry>>{};
  for (final e in entries) {
    (map[e.date] ??= []).add(e);
  }
  for (final list in map.values) {
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
  return map;
}
