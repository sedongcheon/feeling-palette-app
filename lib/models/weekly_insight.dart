enum InsightTrend { up, down, stable, mixed }

InsightTrend trendFromString(String? value) {
  switch (value) {
    case 'up':
      return InsightTrend.up;
    case 'down':
      return InsightTrend.down;
    case 'mixed':
      return InsightTrend.mixed;
    case 'stable':
    default:
      return InsightTrend.stable;
  }
}

enum InsightConfidence { low, medium, high }

InsightConfidence confidenceFromString(String? value) {
  switch (value) {
    case 'high':
      return InsightConfidence.high;
    case 'low':
      return InsightConfidence.low;
    case 'medium':
    default:
      return InsightConfidence.medium;
  }
}

class WeeklyInsight {
  final String anchorDate;   // YYYY-MM-DD — generation day
  final String insightText;
  final InsightTrend trend;
  final String? keyword;
  final InsightConfidence confidence;
  final bool careFlag;
  final int generatedAt;     // ms since epoch
  final String monthKey;     // YYYY-MM derived from anchorDate, for quota scoping
  final int regenCount;
  final int adCount;

  const WeeklyInsight({
    required this.anchorDate,
    required this.insightText,
    required this.trend,
    this.keyword,
    required this.confidence,
    this.careFlag = false,
    required this.generatedAt,
    required this.monthKey,
    this.regenCount = 0,
    this.adCount = 0,
  });

  Map<String, Object?> toRow() => {
        'anchor_date': anchorDate,
        'insight_text': insightText,
        'trend': trend.name,
        'keyword': keyword,
        'confidence': confidence.name,
        'care_flag': careFlag ? 1 : 0,
        'generated_at': generatedAt,
        'month_key': monthKey,
        'regen_count': regenCount,
        'ad_count': adCount,
      };

  factory WeeklyInsight.fromRow(Map<String, Object?> row) {
    return WeeklyInsight(
      anchorDate: row['anchor_date'] as String,
      insightText: row['insight_text'] as String,
      trend: trendFromString(row['trend'] as String?),
      keyword: row['keyword'] as String?,
      confidence: confidenceFromString(row['confidence'] as String?),
      careFlag: ((row['care_flag'] as num?)?.toInt() ?? 0) == 1,
      generatedAt: (row['generated_at'] as num).toInt(),
      monthKey: row['month_key'] as String,
      regenCount: (row['regen_count'] as num?)?.toInt() ?? 0,
      adCount: (row['ad_count'] as num?)?.toInt() ?? 0,
    );
  }
}
