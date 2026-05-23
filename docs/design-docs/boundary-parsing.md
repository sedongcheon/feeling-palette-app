---
title: Parse at the boundary
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Parse at the boundary

a.k.a. "데이터는 스키마를 통과하기 전까지 dirty다."

## Why

타입이 없는 데이터가 시스템 안으로 들어오면 load-bearing이 된다. boundary에서
터지는 런타임 예외는 회복 가능하지만, 세 계층 안에서 손상된 레코드는 회복
불가다. 가장자리(edge)에서 스키마로 잡으면 안쪽 코드가 total해진다.

## Where (Feeling Palette)

| Boundary                          | 스키마 위치                                                  |
|-----------------------------------|--------------------------------------------------------------|
| AWS API 응답 (감정 분석)          | `lib/models/diary.dart` 내 emotion field + `EmotionAnalyzer.parseResponse` |
| AWS API 응답 (월간/주간 요약)     | `lib/models/{month_summary,weekly_insight}.dart` `fromJson`  |
| sqflite row                       | `lib/models/<name>.dart` `fromMap`                           |
| `.env.json` 환경 변수             | `String.fromEnvironment` (현재) — 향후 `lib/utils/env.dart` 단일 파서 |
| IAP `PurchaseDetails`             | `lib/services/premium_service.dart`의 핸들러                 |
| Google Drive API 응답             | `lib/services/drive_backup_service.dart` 내 파싱             |
| AdMob 콜백 (`AdEvent`)            | `lib/services/ads_service.dart`                              |
| Deep link / app link              | (현재 미사용 — 도입 시 단일 라우터 파서)                     |
| secure storage 값                 | `flutter_secure_storage` → 로드 시 형식 검증                 |
| Firebase RemoteConfig (도입 시)   | `lib/utils/remote_config.dart` (예정)                        |

## How

### sqflite row (현재 패턴)

```dart
class Diary {
  final int id;
  final DateTime createdAt;
  final String content;
  final String? emotion;

  factory Diary.fromMap(Map<String, Object?> row) {
    return Diary(
      id: row['id'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
      content: row['content'] as String,
      emotion: row['emotion'] as String?,
    );
  }
}
```

`as Foo`는 boundary 한 곳에서만 허용. service 안에는 `row['content']`
같은 dynamic 접근 금지.

### HTTP 응답 (현재 패턴 → 목표)

```dart
// service/emotion_analyzer.dart
final res = await http.post(uri, body: jsonEncode({...}));
if (res.statusCode != 200) return Result.error(ApiError.parse(res));
final json = jsonDecode(res.body) as Map<String, dynamic>;
final analysis = EmotionAnalysis.fromJson(json); // boundary 파싱
return Result.ok(analysis);
```

`as Map<String, dynamic>`은 응답 디코드 직후 한 줄에만. 이후 코드는
타입 안전.

### freezed 도입 후 (향후)

```dart
@freezed
class EmotionAnalysis with _$EmotionAnalysis {
  const factory EmotionAnalysis({
    required String primary,
    required double confidence,
    required List<String> keywords,
  }) = _EmotionAnalysis;

  factory EmotionAnalysis.fromJson(Map<String, dynamic> json) =>
      _$EmotionAnalysisFromJson(json);
}
```

`tryParse` variant는 `Result<T, E>`로 에러 컨텍스트를 흘려보낼 때 사용.

## Check

- `tool/check_layers.dart` (도입 시): `lib/services/*.dart`가 `dart:convert`나
  `dart:io`를 직접 import하면 smell 표시. boundary는 service 위/아래 (model 또는
  runtime/provider 계층)에 있어야.
- Gardener regex (수동 또는 자동):
  `jsonDecode\([^)]*\)\s+as\s+Map<String,\s*dynamic>` 가 `lib/services/` 외에
  나오면 정상이지만, `lib/services/` 안에서 *내부 호출에 흘리면* 위반.
- `analysis_options.yaml`에 `strict-casts: true` 추가 (목표 — tech-debt).

## Anti-patterns

- `jsonDecode(...) as Map<String, dynamic>` 이후 dict 그대로 service 호출에 전달.
- `// 백엔드를 신뢰` 같은 주석.
- DB row → API 응답을 스키마 없이 매핑.
- `dynamic` parameter (즉시 타입 narrow하지 않는 경우).
- IAP `PurchaseDetails.purchaseID`를 검증 없이 서버에 그대로 전달.
- Google Drive 응답 dict의 `files[0]['id']` 같은 raw 접근.
