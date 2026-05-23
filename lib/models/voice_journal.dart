import 'diary.dart';

/// 음성 일기 분석 요청 — 백엔드에 보낼 익명화된 텍스트와 user_id_hash.
class VoiceAnalyzeRequest {
  final String anonymizedText;
  final String userIdHash;
  final String locale;

  const VoiceAnalyzeRequest({
    required this.anonymizedText,
    required this.userIdHash,
    required this.locale,
  });
}

/// 한 감정의 신호 강도 (0.0–1.0).
class Emotion {
  final String label;
  final double intensity;

  const Emotion({required this.label, required this.intensity});
}

/// 음성 일기 분석 응답 — 결과 화면이 직접 소비한다.
///
/// 백엔드 신규 v1 엔드포인트(`/api/v1/journal/analyze`)가 배포되기 전까지는
/// 기존 `/api/diary/analyze` 응답을 [VoiceJournalService]가 이 모델로
/// 매핑한다.
class VoiceAnalyzeResponse {
  final EmotionType dominantEmotion;
  final double intensityScore; // 0.0–1.0
  final String empathyResponse;
  final String suggestedColorHex;
  final List<String> themes;
  final List<Emotion> emotions;

  const VoiceAnalyzeResponse({
    required this.dominantEmotion,
    required this.intensityScore,
    required this.empathyResponse,
    required this.suggestedColorHex,
    required this.themes,
    required this.emotions,
  });
}

/// 음성 일기 백엔드 호출 실패 시 caller가 분기할 수 있도록 expose하는
/// exception. 서비스 내부 `http` 예외를 감싸 사용자 친화 메시지를 만들 수
/// 있게 한다.
class VoiceAnalyzeException implements Exception {
  final String message;
  final int? statusCode;
  const VoiceAnalyzeException(this.message, {this.statusCode});

  @override
  String toString() =>
      'VoiceAnalyzeException($statusCode): $message';
}
