---
name: query-crashlytics
description: Look at Firebase Crashlytics for the Feeling Palette app — find new issues, check stack traces, correlate with a recent build.
status: living
last_verified: 2026-05-23
---

# Skill: query-crashlytics

Feeling Palette는 자체 observability stack 없이 Firebase Crashlytics를 신뢰한다.
release 빌드에서만 수집되며 (`main.dart` 가드), debug/profile은 수집 안 함.

## 접근

브라우저 — Firebase Console > 프로젝트 > Crashlytics > Issues.
(현재 자동화된 query API 사용 없음 — 향후 Firebase Admin SDK 도입 가능)

## 일상 워크플로

1. 새 빌드 출시 후 24-48h:
   - 새 issue가 갑자기 솟구치는지 확인.
   - 충돌 free users 비율이 떨어지는지.
2. Crashlytics issue에서 *Versions* 탭을 보고 어느 빌드부터 발생했는지 확인.
3. *Sessions* 탭에서 stack trace + breadcrumb 검토.

## breadcrumb로 컨텍스트 키우기

향후 `lib/services/telemetry.dart` 도입 시:

```dart
FirebaseCrashlytics.instance.log('emotion_analysis.call locale=$locale');
```

`recordError` 직전의 모든 `log` 호출이 stack에 첨부됨. PII 금지.

## 커스텀 키

```dart
await FirebaseCrashlytics.instance.setCustomKey('app_lock_enabled', hasPinSet);
await FirebaseCrashlytics.instance.setCustomKey('locale', currentLocale);
await FirebaseCrashlytics.instance.setCustomKey('is_premium', isPro);
```

issue 검색 시 필터로 사용 가능.

## 자주 발생하는 카테고리

| 패턴                                   | 원인 후보                                                      |
|----------------------------------------|----------------------------------------------------------------|
| `PlatformException(channel-error)`     | 플러그인 native 측 미초기화 — `main.dart` 부트 순서 확인       |
| `MissingPluginException`                | pubspec 추가했는데 pod install 안 됨 (iOS), gradle clean 필요 (Android) |
| `TimeoutException` on secure storage   | Samsung issue — 이미 타임아웃 적용됨, 다른 매니페스트인지 확인 |
| `FormatException` in fromMap/fromJson  | boundary 파싱 실패 — DB 마이그레이션 누락 또는 서버 응답 형식 변경 |
| `_CastError` (as Foo)                  | dynamic cast 실패 — boundary 위에서 `as` 사용                  |

## issue → exec-plan

새 issue가 심각하면:

1. issue ID + stack trace를 `docs/incidents/<date>-<slug>/CRASHLYTICS.md`에 저장.
2. `docs/exec-plans/active/<NNN>-incident-<slug>.md` plan 생성.
3. `bug-reproducer` 에이전트로 재현 시나리오 만들기.
4. fix → ship-pr.

## AWS 백엔드 로그

클라이언트 stack에서 API 호출 시각이 보이면, AWS CloudWatch에서 그 시각의
백엔드 로그를 cross-reference (`docs/AWS_INFRA.md`).

대부분의 "버튼 안 먹어요" / "분석이 안 돼요"는 백엔드 4xx/5xx — 클라이언트
crash가 아님.
