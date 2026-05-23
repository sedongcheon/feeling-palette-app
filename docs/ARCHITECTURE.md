---
title: Architecture
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Architecture

Feeling Palette는 현재 **단일 Flutter 패키지** 구조이지만, harness engineering
규약을 적용해 *논리적 계층*을 강제한다. 미래에 melos 모노레포로 확장될 때
도메인 분리가 자연스럽게 떨어지도록, 현재 코드를 다음 매핑에 따라 정렬한다.

## 도메인 (현재 → 목표)

Feeling Palette의 비즈니스 도메인:

| 도메인              | 현재 위치                                                        | 향후 `domains/<name>/` |
|---------------------|------------------------------------------------------------------|------------------------|
| `diary`             | `lib/models/diary.dart`, `lib/db/diary_dao.dart`, `lib/providers/diary_provider.dart`, `lib/screens/{calendar,timeline,diary_detail,home}_screen.dart` | `domains/diary/` |
| `emotion_analysis`  | `lib/services/emotion_analyzer.dart`, `lib/services/api_locale.dart` | `domains/emotion_analysis/` |
| `month_summary`     | `lib/services/month_summary_service.dart`, `lib/db/month_summary_dao.dart`, `lib/models/month_summary.dart` | `domains/month_summary/` |
| `weekly_insight`    | `lib/services/weekly_insight_service.dart`, `lib/db/weekly_insight_dao.dart`, `lib/models/weekly_insight.dart` | `domains/weekly_insight/` |
| `premium` (IAP)     | `lib/services/premium_service.dart`                              | `domains/premium/` |
| `ads`               | `lib/services/ads_service.dart`                                  | `domains/ads/` |
| `backup`            | `lib/services/{backup_service,drive_backup_service}.dart`, `lib/screens/backup_screen.dart` | `domains/backup/` |
| `auth` / `app_lock` | `lib/services/auth_service.dart`, `lib/providers/auth_provider.dart`, `lib/screens/{lock,pin_setup}_screen.dart` | `providers/auth/` (횡단) |
| `consent`           | `lib/services/consent_service.dart`                              | `providers/consent/` (횡단) |
| `stats`             | `lib/screens/stats_screen.dart`                                  | `domains/stats/` |
| `settings`          | `lib/screens/settings_screen.dart`                               | `apps/app/` (조립만) |

## 계층 (Layered domains)

각 도메인은 다음 6개 계층으로 분리한다. 단일 패키지에서는 *디렉토리* 대신
*파일 prefix/네임스페이스*로 계층을 표현한다. 모노레포 전환 시 그대로 옮겨진다.

```
domains/<name>/
  core/                       # pure Dart — Flutter 의존 금지
    types/    →  현재: lib/models/<name>.dart            (immutable model, 향후 freezed)
    config/   →  현재: lib/constants/<name>_config.dart  (상수)
    repo/     →  현재: lib/db/<name>_dao.dart            (sqflite DAO)
    service/  →  현재: lib/services/<name>_service.dart  (비즈니스 규칙, 의존성을 인자로)
    runtime/  →  현재: lib/providers/<name>_provider.dart (ChangeNotifier; 향후 Riverpod AsyncNotifier)
  ui/                         # Flutter — core/types만 의존
    →  현재: lib/screens/<name>_screen.dart + lib/widgets/<name>_*.dart
```

`apps/app`(미래의 main 엔트리)은 `runtime`/`ui`만 조립한다.

## 계층 규칙 (import 방향)

| Layer    | May import                                              |
|----------|---------------------------------------------------------|
| types    | shared, 같은 도메인의 다른 types                        |
| config   | types, shared                                           |
| repo     | types, config, shared, providers                        |
| service  | types, config, repo, shared, providers                  |
| runtime  | types, config, service, shared, providers               |
| ui       | types, shared, providers (auth/consent 등 클라이언트 표면) |

- `repo`가 `service`를 import → 계층 버그.
- `service`가 `runtime`/`ui`를 import → 계층 버그.
- `domains/A/* → domains/B/*` → 도메인 횡단 금지. 공통 헬퍼는 `packages/shared`로.
- `core/* → package:flutter/*` → pure Dart 측에서 Flutter 금지.

현재는 정적 분석기로 강제되지 않는다 — [tech-debt-tracker](exec-plans/tech-debt-tracker.md)
의 `check_layers.dart` 도입 항목 참조.

## 횡단 관심사 (`providers/`)

도메인 간 공유되는 *횡단* 관심사는 단일 진입점을 둔다.
도메인은 providers를 import할 수 있지만, providers는 도메인을 import할 수 없다.

```
providers/
  auth/             # 세션, PIN 잠금, secure storage
  telemetry/        # 구조적 로깅 (현재: Firebase Crashlytics + debugPrint 점진적 제거)
  consent/          # GDPR/광고 동의 (UMP)
  connectors/       # 외부 시스템 (AWS API, Google Drive, AdMob, Play/App Store IAP)
```

새 provider는 `docs/design-docs/<slug>.md` 결정 노트 1개 필요.

## 앱 (`apps/`)

```
apps/
  app/    # 현재: lib/main.dart — Firebase·Crashlytics·IAP·Ads 부트스트랩 + 라우트만
```

`apps/app`은 `service`, `repo`, raw `config`를 **직접 import 금지**.
runtime(ChangeNotifier/AsyncNotifier) 또는 ui를 통해서만 접근.

## 패키지 (`packages/`, 미래)

```
packages/
  shared/         # Result<T,E>, branded ids, Clock, Env 파서, 공통 widget helpers
```

두 도메인에서 동일 헬퍼가 필요해지면 이쪽으로 끌어올린다. 복붙 금지.

## 외부 의존성

- **AWS API**: `https://feeling-api-aws.sedoli.co.kr` (감정 분석). 응답은 boundary에서 파싱.
- **Firebase**: Crashlytics(release만), Analytics, Auth.
- **AdMob**: `lib/services/ads_service.dart` (Android·iOS 동일 활성화).
- **IAP**: `in_app_purchase` (Google Play / App Store StoreKit).
- **Google Drive**: 백업 (`drive_backup_service.dart`).

## 생성 산출물 (Generated artifacts)

다음은 **손으로 편집 금지** (PreToolUse hook이 차단):

- `lib/firebase_options.dart` — `flutterfire configure` 산출물
- `lib/l10n/app_localizations*.dart` — `flutter gen-l10n` 산출물 (ARB → Dart)
- `**/*.g.dart`, `**/*.freezed.dart` — `build_runner` 산출물 (freezed 도입 시)
- `android/app/build/`, `ios/Pods/`, `build/` — 빌드 산출물

## 금지된 import 그래프 요약

- `repo → service` ❌
- `repo → runtime` ❌
- `repo → ui` ❌
- `service → runtime` ❌
- `service → ui` ❌
- `runtime → ui` ❌
- `ui → repo` ❌
- `ui → service` ❌ (controller/notifier 통해서만)
- `apps → service` (직접) ❌
- `providers → domains/**` ❌
- `domains/A/* → domains/B/*` ❌
- `core/* → package:flutter/*` ❌ (현 단계 단일 패키지에서는 도메인 service 계층에서 flutter 금지)

## 새 도메인 추가하기

현재는 수동:

1. `lib/models/<name>.dart` (types)
2. `lib/constants/<name>_config.dart` (config; 필요 시)
3. `lib/db/<name>_dao.dart` (repo; 로컬 저장 필요 시)
4. `lib/services/<name>_service.dart` (service)
5. `lib/providers/<name>_provider.dart` (runtime)
6. `lib/screens/<name>_screen.dart` + `lib/widgets/<name>_*.dart` (ui)
7. `docs/product-specs/<name>.md` — 제품 스펙 stub (필수)
8. `docs/exec-plans/active/<NNN>-<name>-*.md` — 도입 exec-plan
