# CLAUDE.md — Feeling Palette (Flutter) harness entry point

> **Mission.** Feeling Palette는 출시 운영 중인 Flutter 앱(Android·iOS)이며,
> 이 리포는 *agent-first* harness 규약에 따라 다음 기능 개발을 진행한다.
> 사람이 steer, 에이전트가 execute.
>
> **Operating principle.** Humans steer. Agents execute.

이 파일은 **table of contents** — 룰은 인라인으로 적지 않는다. 자명하지
않은 모든 것은 `docs/` 또는 `.claude/`에 있다. 이 파일은 120줄 이내로 유지.

## Top-3 invariants (수동 검토 — 자동 강제 도구는 tech-debt)

1. **Layered architecture.** 도메인의 `repo`는 `service|runtime|ui`를 import하지 않는다. `service`는 `runtime|ui`를 import하지 않는다. 횡단 관심사는 `providers/`(미래)를 통해서만 들어온다. 단일 패키지 매핑은 [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
2. **Parse at the boundary.** AWS API, sqflite, IAP 콜백, secure storage, env, Drive 응답 — 모두 boundary에서 모델의 `fromJson`/`fromMap` 통과. service 내부에는 `dynamic` / `as Foo` 금지. [docs/RELIABILITY.md](docs/RELIABILITY.md) / [docs/design-docs/boundary-parsing.md](docs/design-docs/boundary-parsing.md).
3. **Generated artifacts 손편집 금지.** `*.g.dart`, `*.freezed.dart`, `lib/firebase_options.dart`, `lib/l10n/app_localizations*.dart`, `build/`, `ios/Pods/`, `android/app/build/`. `PreToolUse` hook이 차단. [.claude/settings.json](.claude/settings.json).

## Required loop (every agent, every task)

1. **Plan.** `planner` 에이전트 사용. 출력: `docs/exec-plans/active/<NNN>-<slug>.md` (frontmatter + decision log + progress log). 형식: [docs/PLANS.md](docs/PLANS.md).
2. **Execute.** 한 PR = 한 도메인. `implementer` 에이전트로 phase 단위. 각 phase는 verify 명령 필요.
3. **Self-review.** 자신의 diff를 읽고 [docs/design-docs/self-review-checklist.md](docs/design-docs/self-review-checklist.md)를 걸어간다. `Stop` hook은 `SELF-REVIEW: PASS`가 보일 때까지 yield를 거부 (Write/Edit이 있었던 turn에 한함).
4. **Agent-review.** `.claude/skills/ship-pr.md` 실행. `code-reviewer` + `security-reviewer` 병렬 호출, 둘 다 pass 필요.
5. **Merge.** reviewer 둘 다 approve + 수동 빌드 검증 후 squash-merge. plan은 `completed/`로 mv.

step이 불가능하면 harness에서 capability가 빠진 것이다 — improvise 대신 skill/agent/hook/lint 룰을 추가.

## Knowledge tree (source-of-truth map)

| Topic                          | Source of truth                                                              |
|--------------------------------|------------------------------------------------------------------------------|
| Architecture & layering        | [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)                                 |
| Design principles              | [docs/DESIGN.md](docs/DESIGN.md)                                             |
| Core operating beliefs         | [docs/design-docs/core-beliefs.md](docs/design-docs/core-beliefs.md)         |
| Flutter conventions            | [docs/FLUTTER.md](docs/FLUTTER.md)                                           |
| Product specs (per domain)     | [docs/product-specs/index.md](docs/product-specs/index.md)                   |
| Reliability, observability     | [docs/RELIABILITY.md](docs/RELIABILITY.md)                                   |
| Security model                 | [docs/SECURITY.md](docs/SECURITY.md)                                         |
| Product sense / UX taste       | [docs/PRODUCT_SENSE.md](docs/PRODUCT_SENSE.md)                               |
| Quality score (D×L matrix)     | [docs/QUALITY_SCORE.md](docs/QUALITY_SCORE.md)                               |
| External refs                  | [docs/references/index.md](docs/references/index.md)                         |
| Exec-plan workflow             | [docs/PLANS.md](docs/PLANS.md)                                               |
| Active plans                   | [docs/exec-plans/index.md](docs/exec-plans/index.md)                         |
| Tech debt backlog              | [docs/exec-plans/tech-debt-tracker.md](docs/exec-plans/tech-debt-tracker.md) |
| Subagent catalog               | [.claude/agents/](.claude/agents/)                                           |
| Skill catalog                  | [.claude/skills/](.claude/skills/)                                           |
| Hooks                          | [.claude/settings.json](.claude/settings.json)                               |

## App legibility (앱 동작 관찰)

- Android 실기기/emulator: `.claude/skills/drive-app.md` § Android — `adb screencap`, `flutter logs`.
- iOS simulator: `.claude/skills/drive-app.md` § iOS — `xcrun simctl io screenshot`.
- 빌드: `.claude/skills/run-build.md`.
- Crashlytics: `.claude/skills/query-crashlytics.md` — Firebase Console.
- 백엔드 로그: AWS CloudWatch ([docs/AWS_INFRA.md](docs/AWS_INFRA.md)).

## Build verify (merge 전 필수)

```bash
flutter pub get
flutter analyze                                                          # clean 필수
flutter test                                                             # 현재는 미구현 다수
flutter build apk --debug --dart-define-from-file=.env.json              # 빌드 가능 여부
```

Release 빌드:
```bash
flutter build appbundle --release --dart-define-from-file=.env.json      # Play Console
flutter build ipa --release --dart-define-from-file=.env.json            # App Store Connect
```

## 새 기능 추가하기

1. `docs/product-specs/<domain>.md` 생성 또는 갱신.
2. `planner` 에이전트로 `docs/exec-plans/active/<NNN>-<slug>.md` 생성.
3. `implementer` 에이전트로 phase 진행.
4. `ship-pr` 스킬로 review + merge.

## 운영 노트 (자주 참조)

| 주제                       | 위치                                                |
|----------------------------|-----------------------------------------------------|
| 빌드/시크릿 주입           | `.env.json` + `--dart-define-from-file=.env.json`. 시크릿 하드코딩 금지. |
| iOS 빌드 사이닝            | `flutter build ipa` 전 Xcode에서 Team 1회 지정 필요. |
| 빌드 번호 bump             | `pubspec.yaml`의 `version: X.Y.Z+빌드`.              |
| ARB 다국어                 | ko 마스터, en 동기화. `flutter gen-l10n` 또는 build가 자동 호출. |
| 앱 잠금 (옵션)             | PIN 존재 여부 = 잠금 활성 여부. 신규 사용자는 PIN 없이 진입 (Play 검토 회피 설계). [docs/APP_LOCK.md](docs/APP_LOCK.md). |
| Samsung secure storage     | `_init: 5s`, `read: 3s` 타임아웃 적용됨 (`lib/services/auth_service.dart`). |
| Android 15 SDK 35          | edge-to-edge 필수. `SystemUiOverlayStyle`에서 statusBar/navigationBar 색상 필드 비워둠. |
| iOS / Android 동일 활성화  | IAP·광고 양 플랫폼 동시 활성화 — 한쪽만 비활성화는 exec-plan으로 추적. |
| Firebase Crashlytics       | release 빌드만 수집. debug/profile은 skip. |
| 출시 가이드                | [docs/RELEASE_PREP.md](docs/RELEASE_PREP.md), [docs/IOS_RELEASE_GUIDE.md](docs/IOS_RELEASE_GUIDE.md), [docs/IOS_UPLOAD_TRANSPORTER.md](docs/IOS_UPLOAD_TRANSPORTER.md). |

## 막혔을 때

문제를 silent하게 회피하지 말 것. tech-debt 항목을 적고, harness에서 빠진
capability(analyzer 룰, skill, doc, fixture)를 추가하는 exec-plan을 연다.
harness가 deliverable이다.
