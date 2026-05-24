import 'diary.dart';

/// 음악·책 추천 요청. 일기 본문과 사용자 locale을 백엔드에 보낸다.
class RecommendRequest {
  final String content;
  final String locale;

  const RecommendRequest({
    required this.content,
    required this.locale,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'locale': locale,
      };
}

/// 백엔드가 추천한 곡 한 개. title/artist는 비어 있을 수 있다 (LLM 응답
/// 누락 안전 처리). reason은 위로 메시지의 근거 — 화면에 그대로 노출한다.
class MusicRecommendation {
  final String title;
  final String artist;
  final String reason;

  const MusicRecommendation({
    required this.title,
    required this.artist,
    required this.reason,
  });

  factory MusicRecommendation.fromJson(Map<String, dynamic> json) {
    return MusicRecommendation(
      title: _stringOrEmpty(json['title']),
      artist: _stringOrEmpty(json['artist']),
      reason: _stringOrEmpty(json['reason']),
    );
  }
}

/// 백엔드가 추천한 책 한 권. 구조는 [MusicRecommendation]과 동일.
class BookRecommendation {
  final String title;
  final String author;
  final String reason;

  const BookRecommendation({
    required this.title,
    required this.author,
    required this.reason,
  });

  factory BookRecommendation.fromJson(Map<String, dynamic> json) {
    return BookRecommendation(
      title: _stringOrEmpty(json['title']),
      author: _stringOrEmpty(json['author']),
      reason: _stringOrEmpty(json['reason']),
    );
  }
}

/// `POST /api/diary/recommend` 응답.
///
/// 백엔드 보장: `music`/`books`는 각각 1~3개. 다만 boundary 안전을 위해
/// null/형 불일치 시 빈 리스트로 fallback한다. `disclaimer`는 빈 문자열일
/// 수 있어 호출자가 ARB fallback 키로 보완해야 한다.
class RecommendResponse {
  final EmotionType primaryEmotion;
  final String comfortMessage;
  final List<MusicRecommendation> music;
  final List<BookRecommendation> books;
  final String disclaimer;

  const RecommendResponse({
    required this.primaryEmotion,
    required this.comfortMessage,
    required this.music,
    required this.books,
    required this.disclaimer,
  });

  factory RecommendResponse.fromJson(Map<String, dynamic> json) {
    return RecommendResponse(
      primaryEmotion: emotionFromString(_stringOrEmpty(json['primary_emotion'])),
      comfortMessage: _stringOrEmpty(json['comfort_message']),
      music: _parseList(json['music'], MusicRecommendation.fromJson),
      books: _parseList(json['books'], BookRecommendation.fromJson),
      disclaimer: _stringOrEmpty(json['disclaimer']),
    );
  }
}

/// 추천 호출 실패 시 caller가 분기할 수 있도록 expose하는 exception.
/// [VoiceAnalyzeException]과 같은 패턴.
class RecommendException implements Exception {
  final String message;
  final int? statusCode;
  const RecommendException(this.message, {this.statusCode});

  @override
  String toString() => 'RecommendException($statusCode): $message';
}

// ---------- internal helpers ----------

String _stringOrEmpty(Object? v) => v is String ? v : '';

List<T> _parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((m) => fromJson(Map<String, dynamic>.from(m)))
      .toList();
}
