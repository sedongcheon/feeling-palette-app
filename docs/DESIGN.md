---
title: Design principles
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Design

에이전트가 이 리포의 Dart/Flutter 코드를 작성할 때 따르는 원칙.
가능한 한 기계적으로 강제한다 — 원칙별 강제 수단은
[design-docs/core-beliefs.md](design-docs/core-beliefs.md) 참조.

## 1. Boring is best

안정된, 잘 문서화된 라이브러리만 사용: `flutter` (stable channel), `sqflite`,
`http` (현재) / `dio` (마이그레이션 대상), `provider` (현재) / `flutter_riverpod`
(향후), `freezed` (도입 예정), `firebase_*`, `in_app_purchase`,
`google_mobile_ads`. 영리한 프레임워크 회피.

## 2. Parse at the boundary

모든 입력 — AWS API 응답, sqflite row, 환경 변수, secure storage 값, IAP 콜백,
deep link, Firebase RemoteConfig 등 — 은 `service` 계층에 도달하기 전에
**모델의 `fromJson` 또는 `fromMap`** 으로 파싱한다. `as Map<String, dynamic>`은
boundary 한 곳에서만 허용. 내부 코드에는 `dynamic` 금지.

freezed 도입 후에는 `@freezed` + `tryParse` 패턴이 표준.

## 3. Layered, not feature-folder

도메인을 *계층*(types/config/repo/service/runtime/ui)으로 자른다.
"feature folder"로 자르지 않는다. 그래야 의존 그래프가 lint 가능하고
변경의 blast radius가 명확해진다. [ARCHITECTURE.md](ARCHITECTURE.md) 참조.

## 4. One domain per PR

하나의 PR은 정확히 하나의 도메인 디렉토리(+ 생성된 파일 + `packages/shared`)만
건드린다. 멀티 도메인 변경은 쪼갠다. 현재는 manual review로만 검증.
(`tool/check_one_domain.dart`는 향후 도입 — tech-debt 참조.)

## 5. Files ≤ 400 lines

400줄 넘는 Dart 파일은 에이전트가 읽기 힘들다. 분할/추출. `*.g.dart`,
`*.freezed.dart`, `app_localizations*.dart` 같은 생성 파일은 예외.

## 6. Result, not throw, for expected failure

도메인 함수는 예상 가능한 실패(검증 실패, not-found, conflict, IAP 거절,
네트워크 4xx)에 대해 `Result<T, E>` 또는 nullable + sentinel을 반환한다.
throw는 invariant 위반(서버가 미친 응답, DB 손상)에만.

현 코드에는 `try/catch`로 throw를 잡고 null/false 반환하는 패턴이 많다 —
점진적으로 `Result`로 통합. `packages/shared/result.dart` 도입은 tech-debt.

## 7. Pure functions in service; effects in runtime

`service` 함수는 의존성(`Clock`, `DAO`, `ApiClient`)을 **인자**로 받는다.
`runtime`(ChangeNotifier/AsyncNotifier)이 의존성을 조립하고 UI에 노출한다.
이렇게 해야 service가 `flutter_test` 단독으로 trivially 테스트 가능.

현재는 service 안에서 직접 sqflite/http를 호출하는 경우가 있다 — 점진적 분리.

## 8. Structured logging only

`print()`, `debugPrint()`, `developer.log()`는 비-test 소스에서 **금지**.
대신 `providers/telemetry`의 logger를 통한다. 현재는 마이그레이션 중이므로
신규 코드에만 적용; 기존 `debugPrint` 호출은 tech-debt로 추적.

analyzer 규칙 `avoid_print: error`는 `analysis_options.yaml`에 향후 추가
(현재 적용 안 됨 — tech-debt).

릴리스 빌드에서 Firebase Crashlytics가 `FlutterError` + `PlatformDispatcher.onError`
를 자동 수집한다 (`main.dart`).

## 9. No YOLO probing

알 수 없는 실패에 `try { ... } catch (_) { }`를 두르기 전에 **실패를 재현**한다.
`// just in case`, `// might fail`, `// 혹시 모를` 주석은 taste-linter가 잡는다.

특정 예외 타입을 잡고 logger에 *why*를 남긴다. catch-all silently swallow 금지.

## 10. Shared utility first

두 도메인에서 같은 헬퍼가 필요하면 `packages/shared`(또는 현재는
`lib/utils/`)로 끌어올린다. 복붙 금지. cross-domain import 금지.

## 11. Code paths must be observable

새로운 service 함수마다 다음을 발행한다:

- **구조적 로그** 1줄 (enter → outcome): `{domain, op, actor, result, durationMs}`.
- **카운터/이벤트** 1개: Firebase Analytics `logEvent` 또는 Crashlytics
  `recordError`.

현재는 Crashlytics만 있고 logger 인프라는 없다 — 점진적 도입.

## 12. The diff is the spec

PR 설명은 exec-plan + diff에서 자동 생성한다. PR 설명에 추가로 적어야 할
내용이 있다면, 그건 harness(spec, plan, 또는 코드 자체)에서 빠진 것이다.

## 플랫폼 분기 원칙

iOS/Android 모두 IAP·광고를 *동일하게* 활성화한다 (`PremiumService.initialize()`,
`AdsService.initialize()` 양 플랫폼 호출). 한쪽만 비활성화하는 *임시* 가드는
허용하지 않는다. 스토어 검토 사유로 일시 비활성이 필요한 경우 exec-plan으로
명시적 추적 후 가드 + 복구 시점을 기록.
