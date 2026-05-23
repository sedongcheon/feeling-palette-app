import 'dart:async';
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:http/http.dart' as http;

import '../constants/emotions.dart';
import '../models/diary.dart';
import '../models/voice_journal.dart';
import 'user_hash_service.dart';

const String _apiBaseUrl = 'https://feeling-api-aws.sedoli.co.kr';
const Duration _httpTimeout = Duration(seconds: 10);

/// 음성 일기 분석 흐름의 service 계층.
///
/// 책임:
///   1. PII 정규식 익명화 (전화/이메일/주민번호).
///   2. user_id_hash 발급 ([UserHashService]).
///   3. 백엔드 호출 — 현재는 기존 `/api/diary/analyze` 재사용.
///   4. 응답을 [VoiceAnalyzeResponse]로 매핑.
///
/// 새 v1 엔드포인트(`/api/v1/journal/analyze`)로 swap할 때 이 파일의
/// `_callBackend`만 교체하면 된다.
class VoiceJournalService {
  VoiceJournalService({
    UserHashService? userHashService,
    http.Client? httpClient,
  })  : _userHashService = userHashService ?? UserHashService(),
        _httpClient = httpClient ?? http.Client();

  final UserHashService _userHashService;
  final http.Client _httpClient;

  // ---------- public API ----------

  /// 사용자가 편집한 텍스트를 익명화한 뒤 백엔드에 보내고 결과를 받는다.
  /// 호출자는 [VoiceAnalyzeException] 만 catch하면 된다.
  Future<VoiceAnalyzeResponse> analyze({
    required String content,
    required String locale,
  }) async {
    final anonymized = anonymize(content);
    final userIdHash = await _userHashService.getUserIdHash();
    final raw = await _callBackend(
      VoiceAnalyzeRequest(
        anonymizedText: anonymized,
        userIdHash: userIdHash,
        locale: locale,
      ),
    );
    return _mapResponse(raw);
  }

  /// 익명화 결과 미리보기 (UI에서 "전송될 텍스트" 표시용 — MVP에서는 미사용).
  String anonymize(String input) {
    var out = input;
    // 이메일은 도메인에 점이 있어 전화번호 정규식과 충돌하지 않도록 먼저.
    out = out.replaceAll(_emailRe, '[이메일]');
    out = out.replaceAll(_residentNumberRe, '[주민번호]');
    out = out.replaceAll(_phoneRe, '[전화번호]');
    return out;
  }

  // ---------- internal ----------

  /// 백엔드 호출. 신규 엔드포인트 배포 시 이 메서드만 교체.
  Future<Map<String, dynamic>> _callBackend(
    VoiceAnalyzeRequest req,
  ) async {
    final uri = Uri.parse('$_apiBaseUrl/api/diary/analyze');
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            // 기존 엔드포인트는 user_id_hash를 무시한다. 신규 엔드포인트로
            // swap 시 body에 추가하면 됨 (서버 변경과 동시에).
            body: jsonEncode({
              'content': req.anonymizedText,
              'locale': req.locale,
            }),
          )
          .timeout(_httpTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final ex = VoiceAnalyzeException(
          response.body,
          statusCode: response.statusCode,
        );
        unawaited(FirebaseCrashlytics.instance.recordError(
          ex,
          StackTrace.current,
          reason: 'voice_journal analyze HTTP ${response.statusCode}',
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
        reason: 'voice_journal analyze timeout',
      ));
      throw const VoiceAnalyzeException('timeout');
    } on http.ClientException catch (e, st) {
      unawaited(FirebaseCrashlytics.instance.recordError(
        e,
        st,
        reason: 'voice_journal analyze network failure',
      ));
      throw VoiceAnalyzeException(e.message);
    }
  }

  /// 기존 `/api/diary/analyze` 응답 → 신규 [VoiceAnalyzeResponse] 매핑.
  VoiceAnalyzeResponse _mapResponse(Map<String, dynamic> parsed) {
    final primaryRaw = parsed['primary_emotion'];
    final dominant = (primaryRaw is String)
        ? EmotionType.values.firstWhere(
            (e) => e.name == primaryRaw,
            orElse: () => EmotionType.calm,
          )
        : EmotionType.calm;

    final emotionsRaw = parsed['emotions'];
    final emotionScores = emotionsRaw is Map<String, dynamic>
        ? EmotionScores.fromJson(emotionsRaw)
        : EmotionScores.empty;

    final dominantScore = emotionScores.scoreOf(dominant);
    final intensity = (dominantScore / 100.0).clamp(0.0, 1.0);

    final comment =
        parsed['comment'] is String ? parsed['comment'] as String : '';
    final color = emotionInfoOf(dominant).hex;

    // 기존 엔드포인트는 themes를 주지 않는다. 신규 엔드포인트로 swap 시
    // 채워짐.
    final themes = <String>[];

    final emotions = emotionScores
        .toMap()
        .entries
        .map((e) => Emotion(
              label: e.key.name,
              intensity: (e.value / 100.0).clamp(0.0, 1.0),
            ))
        .toList();

    return VoiceAnalyzeResponse(
      dominantEmotion: dominant,
      intensityScore: intensity,
      empathyResponse: comment,
      suggestedColorHex: color,
      themes: themes,
      emotions: emotions,
    );
  }
}

// ---------- 정규식 (PII 익명화) ----------

// 010-XXXX-XXXX / 010XXXXXXXX / 02-XXX-XXXX / 010 1234 5678 등.
// 한국 휴대전화 + 일반전화. 너무 공격적이지 않게 보수적으로.
final RegExp _phoneRe = RegExp(
  r'(?<!\d)(\+?\d{1,3}[\s-]?)?(0\d{1,2})[\s-]?\d{3,4}[\s-]?\d{4}(?!\d)',
);

final RegExp _emailRe = RegExp(
  r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
);

// 주민등록번호: YYMMDD-NNNNNNN. 공백/하이픈 약간 허용.
final RegExp _residentNumberRe = RegExp(
  r'(?<!\d)\d{6}\s*-\s*\d{7}(?!\d)',
);
