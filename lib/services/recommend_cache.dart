import '../models/recommendation.dart';

/// 같은 일기 + 같은 locale에 대한 [RecommendResponse]를 세션 동안 캐시한다.
///
/// 광고 시청 후 받은 추천을 사용자가 닫고 다시 열 때 같은 결과를 광고 없이
/// 재노출하기 위함. 앱 재시작 시 사라진다 (영구 캐시는 일기 entry 단위
/// schema 변경이 필요해 별도 plan).
///
/// 키는 `${locale}:${content.trim()}`. content가 한 글자라도 다르면 다른
/// 일기로 친다 (사용자가 일기 수정 후 다시 분석/추천을 받는 시나리오에서
/// 새 추천이 나오는 게 자연스러움).
class RecommendCache {
  RecommendCache._();
  static final RecommendCache instance = RecommendCache._();

  final Map<String, RecommendResponse> _entries = {};

  RecommendResponse? get({required String content, required String locale}) {
    return _entries[_key(content, locale)];
  }

  void put({
    required String content,
    required String locale,
    required RecommendResponse response,
  }) {
    _entries[_key(content, locale)] = response;
  }

  void clear() => _entries.clear();

  String _key(String content, String locale) => '$locale:${content.trim()}';
}
