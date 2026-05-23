---
title: http — quick reference
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/http
---

# http (Dart 표준 HTTP)

현재 Feeling Palette의 HTTP 클라이언트. 향후 `dio`로 마이그레이션 예정
(tech-debt: dio-migration).

## 패턴

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

final res = await http.post(
  Uri.parse('https://feeling-api-aws.sedoli.co.kr/api/diary/analyze'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({'content': text, 'locale': locale}),
).timeout(const Duration(seconds: 8));

if (res.statusCode != 200) {
  // 실패 처리 — boundary 파싱 없이 service 안으로 흘리지 말 것.
  return null;
}

final json = jsonDecode(res.body) as Map<String, dynamic>;
final analysis = EmotionAnalysis.fromJson(json); // boundary 파싱
```

## 규칙

- `as Map<String, dynamic>`는 디코드 직후 한 줄에만.
- 응답은 즉시 모델의 `fromJson`/`fromMap`으로 파싱.
- 타임아웃은 `.timeout(Duration(...))`로 명시 — 디폴트 X.
- 위젯 안에서 직접 호출 금지 — service 또는 provider/notifier 경유.

## 한계

- 인터셉터 없음 (logging, auth header 일괄 적용 어려움).
- 연결/응답 타임아웃 분리 안 됨.
- → `dio` 마이그레이션의 동기.

## 디버그 명령

```bash
# 감정 분석 API 직접 호출
curl -sS -X POST https://feeling-api-aws.sedoli.co.kr/api/diary/analyze \
  -H 'Content-Type: application/json' \
  -d '{"content":"오늘 날씨가 맑아서 기분이 좋았다","locale":"ko"}' \
  --max-time 15 -w "\n[HTTP %{http_code}]\n"
```
