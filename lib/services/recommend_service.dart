import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

import '../models/recommendation.dart';

const String _apiBaseUrl = 'https://feeling-api-aws.sedoli.co.kr';
// LLM 응답이 10~15s까지 걸릴 수 있다고 백엔드 doc에 명시 (§3 Recommend
// 매핑). EditScreen / 추천 진입 화면이 spinner를 띄워 사용자 가시 동작이
// 멈추지 않게 한다. `voice_journal_service`와 같은 값을 사용.
const Duration _httpTimeout = Duration(seconds: 20);

/// `POST /api/diary/recommend` 호출을 담당하는 service.
///
/// 책임:
///   - 일기 본문 + locale을 백엔드에 전달.
///   - 응답을 [RecommendResponse]로 매핑 (모델의 fromJson).
///   - boundary 실패(HTTP 4xx/5xx, timeout, network)를 [RecommendException]
///     으로 정상화하고 Crashlytics에 기록.
///
/// 분석/quota/광고와는 무관 — 호출자는 보상 광고 시청 후에만 이 service를
/// 호출하기로 했지만, service 자체는 그 결합을 모른다.
class RecommendService {
  RecommendService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Future<RecommendResponse> recommend({
    required String content,
    required String locale,
  }) async {
    final raw = await _callBackend(
      RecommendRequest(content: content, locale: locale),
    );
    return RecommendResponse.fromJson(raw);
  }

  Future<Map<String, dynamic>> _callBackend(RecommendRequest req) async {
    final uri = Uri.parse('$_apiBaseUrl/api/diary/recommend');
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(req.toJson()),
          )
          .timeout(_httpTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final ex = RecommendException(
          response.body,
          statusCode: response.statusCode,
        );
        unawaited(FirebaseCrashlytics.instance.recordError(
          ex,
          StackTrace.current,
          reason: 'recommend HTTP ${response.statusCode}',
        ));
        throw ex;
      }
      final decoded =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return decoded;
    } on TimeoutException catch (e, st) {
      unawaited(FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'recommend timeout',
      ));
      throw const RecommendException('timeout');
    } on http.ClientException catch (e, st) {
      unawaited(FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'recommend network failure',
      ));
      throw RecommendException(e.message);
    } on FormatException catch (e, st) {
      unawaited(FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'recommend malformed json',
      ));
      throw RecommendException('malformed response');
    }
  }
}
