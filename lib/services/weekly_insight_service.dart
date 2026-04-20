import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/diary.dart';

const String _apiBaseUrl = 'https://feeling-api-aws.sedoli.co.kr';

class WeeklyInsightApiResponse {
  final String insightText;
  final String trend;        // up|down|stable|mixed
  final String? keyword;
  final String confidence;   // low|medium|high
  final bool careFlag;

  const WeeklyInsightApiResponse({
    required this.insightText,
    required this.trend,
    this.keyword,
    required this.confidence,
    required this.careFlag,
  });
}

class WeeklyInsightService {
  /// POST /api/insights/weekly
  ///
  /// Request body:
  ///   { "anchor_date": "YYYY-MM-DD",
  ///     "entries": [ {"date":"YYYY-MM-DD", "content":"...", "primary_emotion":"joy|..."} ] }
  ///
  /// Response body (200):
  ///   { "insight_text": "...", "trend": "up|down|stable|mixed",
  ///     "keyword": "..." | null, "confidence": "low|medium|high",
  ///     "care_flag": true|false }
  Future<WeeklyInsightApiResponse> generate({
    required String anchorDate,
    required List<DiaryEntry> entries,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/api/insights/weekly');
    final payload = {
      'anchor_date': anchorDate,
      'entries': entries
          .map((e) => {
                'date': e.date,
                'content': e.content,
                'primary_emotion': e.primaryEmotion.name,
              })
          .toList(),
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류 ${response.statusCode}: ${response.body}');
    }

    final parsed =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final insightText = parsed['insight_text'];
    if (insightText is! String || insightText.isEmpty) {
      throw const FormatException('응답에 insight_text 필드가 없습니다.');
    }
    final trend = parsed['trend'] is String ? parsed['trend'] as String : 'stable';
    final confidence =
        parsed['confidence'] is String ? parsed['confidence'] as String : 'medium';
    final keywordRaw = parsed['keyword'];
    final careFlag = parsed['care_flag'] == true;

    return WeeklyInsightApiResponse(
      insightText: insightText,
      trend: trend,
      keyword: keywordRaw is String && keywordRaw.isNotEmpty ? keywordRaw : null,
      confidence: confidence,
      careFlag: careFlag,
    );
  }
}
