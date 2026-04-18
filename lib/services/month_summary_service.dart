import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/diary.dart';

const String _apiBaseUrl = 'https://feeling-api-aws.sedoli.co.kr';

class MonthSummaryResponse {
  final String summary;
  final String? dominantEmotion;

  const MonthSummaryResponse({
    required this.summary,
    this.dominantEmotion,
  });
}

class MonthSummaryService {
  /// POST /api/month/summarize
  ///
  /// Request body:
  ///   { "year_month": "YYYY-MM",
  ///     "entries": [ {"date":"YYYY-MM-DD", "content":"...", "primary_emotion":"joy|..."} ] }
  ///
  /// Response body (200):
  ///   { "summary": "...", "dominant_emotion": "joy" }  // dominant_emotion optional
  Future<MonthSummaryResponse> summarize({
    required String yearMonth,
    required List<DiaryEntry> entries,
  }) async {
    final uri = Uri.parse('$_apiBaseUrl/api/month/summarize');
    final payload = {
      'year_month': yearMonth,
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
    final summary = parsed['summary'];
    if (summary is! String || summary.isEmpty) {
      throw const FormatException('응답에 summary 필드가 없습니다.');
    }
    final dominantRaw = parsed['dominant_emotion'];
    return MonthSummaryResponse(
      summary: summary,
      dominantEmotion: dominantRaw is String ? dominantRaw : null,
    );
  }
}
