class MonthSummary {
  final String monthKey; // 'YYYY-MM'
  final String summaryText;
  final String? dominantEmotion;
  final int generatedAt;
  final int regenCount; // total generations for this month (first gen counts as 1)
  final int adCount;    // how many of those were unlocked via rewarded ad

  const MonthSummary({
    required this.monthKey,
    required this.summaryText,
    this.dominantEmotion,
    required this.generatedAt,
    this.regenCount = 0,
    this.adCount = 0,
  });

  Map<String, Object?> toRow() => {
        'month_key': monthKey,
        'summary_text': summaryText,
        'dominant_emotion': dominantEmotion,
        'generated_at': generatedAt,
        'regen_count': regenCount,
        'ad_count': adCount,
      };

  factory MonthSummary.fromRow(Map<String, Object?> row) {
    return MonthSummary(
      monthKey: row['month_key'] as String,
      summaryText: row['summary_text'] as String,
      dominantEmotion: row['dominant_emotion'] as String?,
      generatedAt: (row['generated_at'] as num).toInt(),
      regenCount: (row['regen_count'] as num?)?.toInt() ?? 0,
      adCount: (row['ad_count'] as num?)?.toInt() ?? 0,
    );
  }
}
