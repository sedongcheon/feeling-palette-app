import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/emotions.dart';
import '../models/diary.dart';

const String _apiBaseUrl = 'https://feeling-api-aws.sedoli.co.kr';

class AnalysisResult {
  final EmotionType primaryEmotion;
  final EmotionScores emotions;
  final String comment;
  final String color;

  const AnalysisResult({
    required this.primaryEmotion,
    required this.emotions,
    required this.comment,
    required this.color,
  });
}

class EmotionAnalyzer {
  Future<AnalysisResult> analyze(String content) async {
    final uri = Uri.parse('$_apiBaseUrl/api/diary/analyze');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('서버 오류 ${response.statusCode}: ${response.body}');
    }

    final parsed = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

    final primaryRaw = parsed['primary_emotion'];
    final primary = (primaryRaw is String)
        ? EmotionType.values.firstWhere(
            (e) => e.name == primaryRaw,
            orElse: () => EmotionType.calm,
          )
        : EmotionType.calm;

    final emotionsRaw = parsed['emotions'];
    final emotions = emotionsRaw is Map<String, dynamic>
        ? EmotionScores.fromJson(emotionsRaw)
        : EmotionScores.empty;

    final comment = parsed['comment'] is String ? parsed['comment'] as String : '';
    final color = emotionInfoOf(primary).hex;

    return AnalysisResult(
      primaryEmotion: primary,
      emotions: emotions,
      comment: comment,
      color: color,
    );
  }
}
