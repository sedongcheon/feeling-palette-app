---
title: Reliability and observability
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Reliability

Feeling Palette는 모바일 클라이언트 + AWS API 백엔드 구조다. 자체 관측 스택은
없고, **Firebase Crashlytics + Analytics + AWS 백엔드 로그**가 관측 도구.

## 관측의 세 축

| 축      | 도구                          | 도달 위치                                        |
|---------|-------------------------------|--------------------------------------------------|
| 크래시  | Firebase Crashlytics (release만) | Firebase Console → Crashlytics                |
| 이벤트  | Firebase Analytics            | Firebase Console → Analytics → Events            |
| 서버 로그 | AWS CloudWatch (백엔드)      | `docs/AWS_INFRA.md` 참조                         |

향후 클라이언트-사이드 structured logger 추가가 tech-debt에 있음 (현재는
`debugPrint`가 일부 남아있음 — 점진 제거).

## main.dart 부트스트랩

```dart
FlutterError.onError = (details) {
  if (kReleaseMode) FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};
PlatformDispatcher.instance.onError = (error, stack) {
  if (kReleaseMode) FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
```

debug/profile 빌드는 Crashlytics를 수집하지 않는다.

## 모든 service 호출

(목표 상태) 새로운 `service.X` 함수는:

1. 진입/종료에서 구조적 로그 1줄을 남긴다 — `{domain, op, actor, result, durationMs}`.
2. 의미 있는 사용자 이벤트는 Firebase Analytics `logEvent`로 발행.
3. 실패는 Crashlytics `recordError(e, stack, reason: ...)`로 수집.

현재는 logger 인프라가 없어 `try/catch` + `debugPrint`가 많다 — 마이그레이션 중.
신규 코드부터 적용. 헬퍼 `lib/services/telemetry.dart` 도입은 tech-debt.

## 건강성 예산 (Health budgets)

| 신호                           | 예산                  | 측정 방법                                   |
|--------------------------------|-----------------------|--------------------------------------------|
| 크래시 free users (release)    | ≥ 99.5% / 24h         | Firebase Crashlytics                       |
| API 4xx/5xx rate               | < 1% / 5m             | AWS CloudWatch                             |
| 감정 분석 응답 시간 (p95)      | < 3s                  | 서버 로그 → CloudWatch metric              |
| IAP 결제 흐름 완료율           | > 70% (구매 시도 → 완료)| Firebase Analytics funnel                 |
| 광고 로드 실패율               | < 5%                  | AdMob console                              |
| 광고 ROI / fill rate           | trend                 | AdMob console                              |

예산 초과 시 `docs/exec-plans/active/`에 `incident` 플랜을 연다.

## 롤백

모든 PR은 단일 `git revert` 또는 `pubspec.yaml` 버전 다운그레이드로 되돌릴
수 있어야 한다. 다음은 금지된 비가역 변경:

- sqflite 스키마 destructive 마이그레이션 (drop column, drop table)
- IAP product id rename (구매한 사용자가 영향받음)
- 광고 unit id 영구 제거 (트래픽 손실)

## 출시 후 모니터링

새 빌드 출시 직후 24~48h:

1. Firebase Crashlytics 새 issue 모니터링
2. Play Console / App Store Connect 충돌 보고서
3. AWS CloudWatch에서 백엔드 4xx/5xx 스파이크 확인
4. AdMob 광고 노출 / IAP 매출 정상 여부

비정상 신호 → `docs/exec-plans/active/<NNN>-incident-<slug>.md` 생성, 재현 →
픽스 → 패치 빌드.

## 도구

- 현재 logger 헬퍼는 없음 — neuro-debug용 `debugPrint`만 (점진 제거).
- 향후 `lib/services/telemetry.dart` 도입 시:
  - `logger.info({...}, msg)` — Crashlytics breadcrumb + (debug에서) console
  - `logger.warn({...}, msg)` — Crashlytics breadcrumb
  - `logger.error(e, stack, reason: ...)` — Crashlytics recordError
  - 모든 service 함수는 `await observe('domain.op', () async { ... })` 래퍼로.

## 관련 문서

- [docs/AWS_INFRA.md](AWS_INFRA.md) — 백엔드 인프라 / CloudWatch
- [docs/ADS_PLAN.md](ADS_PLAN.md), [docs/ADS_TESTING.md](ADS_TESTING.md)
- [docs/IAP_SETUP.md](IAP_SETUP.md)
- [docs/RELEASE_PREP.md](RELEASE_PREP.md)
