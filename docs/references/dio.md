---
title: dio — quick reference (향후 마이그레이션)
owner: harness-engineer
status: living
last_verified: 2026-05-23
upstream: https://pub.dev/packages/dio
---

# dio (향후 도입)

> **현재 미도입.** HTTP는 `http` 패키지. tech-debt: `dio-migration`.

dio의 장점:
- request/response interceptor (logging, auth header, retry 일괄 적용)
- 연결/응답 타임아웃 분리
- cancellation token

## 도입 시 setup

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://feeling-api-aws.sedoli.co.kr',
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 8),
  headers: {'Content-Type': 'application/json'},
));

dio.interceptors.add(LogInterceptor(
  requestBody: kDebugMode,
  responseBody: kDebugMode,
));
```

provider/riverpod로 단일 인스턴스 노출:

```dart
@riverpod
Dio dio(DioRef ref) {
  final d = Dio(BaseOptions(...));
  d.interceptors.add(...);
  return d;
}
```

## Typed 호출

```dart
final res = await dio.post('/api/diary/analyze', data: {
  'content': text,
  'locale': locale,
});
return EmotionAnalysis.fromJson(res.data as Map<String, dynamic>);
```

`as Map<String, dynamic>`은 `res.data`가 `dynamic`이라 필요한 *유일한* 캐스트.
즉시 boundary 파싱.

## 규칙

- 앱 전체에 단일 `Dio` 인스턴스.
- 위젯에서 `dio.X(...)` 직접 호출 금지 — service 또는 controller 경유.
- 새 외부 host는 `providers/connectors/` (향후 모노레포 구조) allowlist 추가.

## 도입 절차

1. `pubspec.yaml`에 `dio: ^5.x` 추가.
2. `lib/services/api_client.dart` 신설 — 단일 `Dio` + interceptor.
3. 한 service의 `http` 호출을 `dio`로 교체.
4. 통과 → 다음 service.
5. 모두 끝나면 `http` 의존성 제거 + `pubspec.lock` 갱신.

## 디버그

```bash
# 동일한 요청을 curl로 (interceptor의 logging이 print하는 형식과 비교)
curl -sS -X POST https://feeling-api-aws.sedoli.co.kr/api/diary/analyze \
  -H 'Content-Type: application/json' \
  -d '{"content":"테스트","locale":"ko"}' --max-time 8
```
