---
title: Tech-debt tracker
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Tech debt

단일 파일 백로그. 각 항목은 `tech-debt-collector` 에이전트가 pick해서 작은
PR로 ship 가능한 bounded item.

## Format

```markdown
- [ ] **YYYY-MM-DD <area>**: 한 줄 problem statement.
      Source: <ci-run | quality-score-cell | gardener-signature | human>.
      Hint: <어디서 시작할지>.
```

## Open items

### 광고 (Plan 001 follow-up)

- [ ] **2026-05-23 rewarded-ad-safety-net (Plan 002 후보)**: iOS에서
      보상 광고의 닫기 X 버튼이 시청 완료 후에도 안 보이는 외부 SDK 케이스.
      `showRewarded()`의 `Completer<RewardedOutcome>`가 영원히 대기 → caller
      가 in-flight 상태로 갇힐 위험. Source: plan 001 사용자 보고.
      Hint: `onUserEarnedReward` 콜백 후 N초(예: 5s) 안에 `onAdDismissed`가
      안 오면 Completer를 `earned`로 강제 complete + dispose. 추가로
      `google_mobile_ads` 5.3.x/5.4.x 검토, Crashlytics에 광고 lifecycle
      이벤트(`onAdShowed`/`onUserEarnedReward`/`onAdDismissed`) 기록.

- [ ] **2026-05-23 ads-not-ready-button-unused**: Plan 001 Phase C revert로
      `adsNotReadyButton` ARB 키가 unused 상태로 남음. ko/en ARB +
      generated AppLocalizations에 남아 있음. Source: plan 001.
      Hint: Plan 002에서 "광고 준비 중…" 라벨이 재사용될 가능성 있어 일단
      유지. 002 후 결정.

### Harness 인프라

- [ ] **2026-05-23 check-layers**: `tool/check_layers.dart` 미존재 — 계층
      위반이 IDE에 표시되지 않고 PR 시점에도 못 잡음. Source: harness 이식.
      Hint: 단일 패키지 변형 — `lib/services/*.dart`가 `lib/screens/`나
      `lib/widgets/`를 import하면 위반. AST 파싱은 `package:analyzer` 사용.

- [ ] **2026-05-23 check-one-domain**: 한 PR에 멀티 도메인 변경이 들어가도
      잡지 못함. Source: harness 이식. Hint: `git diff --name-only` 결과를
      `lib/{models,db,services,providers,screens,widgets}/<name>_*` 그룹에
      매핑하고 그룹 수를 카운트.

- [ ] **2026-05-23 score-quality**: `tool/score_quality.dart` 미존재 —
      `docs/QUALITY_SCORE.md` 수동 갱신. Source: harness 이식.
      Hint: 계층별로 (a) 테스트 커버리지, (b) `dynamic`/`as Foo` 카운트,
      (c) 파일 길이, (d) `debugPrint` 카운트를 합산해서 A-D 등급화.

- [ ] **2026-05-23 doc-gardener**: 자동 staleness 검사 미존재 — `last_verified`
      필드가 6개월 넘은 doc, broken link, 누락된 frontmatter를 못 잡음.
      Source: harness 이식. Hint: walk `docs/`와 `.claude/` 모든 `.md` 파일,
      frontmatter YAML 파싱.

### Code 품질 (Feeling Palette)

- [ ] **2026-05-23 telemetry-helper**: 구조적 logger가 없어 `debugPrint`가
      여러 services에 남아 있음. Source: 기존 코드 검토. Hint:
      `lib/services/telemetry.dart` 만들고 `logger.info/warn/error` +
      Crashlytics breadcrumb 통합. 그 다음 점진적으로 `debugPrint` 교체.

- [ ] **2026-05-23 strict-casts**: `analysis_options.yaml`에 `strict-casts: true`,
      `strict-inference: true` 미적용. 추가 후 발생하는 오류는 boundary
      파싱으로 수정. Source: design-docs/boundary-parsing.md. Hint: 한 번에
      켜면 폭발 — 도메인별 plan으로 점진 적용.

- [ ] **2026-05-23 result-type**: `Result<T, E>` 타입이 없어 service 실패가
      throw + try/catch 패턴. Source: docs/DESIGN.md #6. Hint:
      `lib/utils/result.dart`에 sealed class 도입 (Dart 3 패턴 매칭).

- [ ] **2026-05-23 freezed-migration**: 수동 `fromMap`/`fromJson`이 많아
      boundary가 verbose하고 일관되지 않음. Source: docs/design-docs/boundary-parsing.md.
      Hint: 도메인당 1 PR — model부터 시작. `build_runner` codegen 첫 도입.

- [ ] **2026-05-23 riverpod-migration**: `provider` + `ChangeNotifier`에서
      `flutter_riverpod` `AsyncNotifier`로. Source: docs/FLUTTER.md. Hint:
      복잡하니 도메인당 1 PR. diary 도메인부터.

- [ ] **2026-05-23 dio-migration**: `http` 패키지 → `dio` (interceptor,
      타임아웃 일원화). Source: docs/references/dio.md. Hint:
      `lib/services/api_client.dart` 신설, services는 이쪽을 통과하게.

- [ ] **2026-05-23 pin-hash**: PIN이 secure storage에 평문 저장되는지 확인
      필요. 평문이면 `crypto.sha256` + salt로 해시. Source: docs/SECURITY.md.
      Hint: `lib/services/auth_service.dart` 검토.

- [ ] **2026-05-23 melos-monorepo**: 모노레포 전환 — `apps/app`,
      `domains/{diary,emotion_analysis,...}/{core,ui}`, `packages/shared`,
      `providers/*`. Source: docs/ARCHITECTURE.md. Hint: 출시 운영이 안정된
      후, 별도 refactor 브랜치에서. iOS Pods/Android gradle 경로 변경 폭탄
      주의.

### 출시 운영

- [ ] **2026-05-23 ci-workflow**: GitHub Actions가 `flutter analyze` /
      `flutter test`를 PR마다 돌리지 않음. Source: 운영. Hint:
      `.github/workflows/flutter-ci.yml` 추가.

- [ ] **2026-05-23 release-tag**: `git tag v<X.Y.Z>+<빌드>` 자동화 없음.
      Source: docs/PLANS.md. Hint: release 빌드 직후 hook 또는 수동 명령
      문서화.

- [ ] **2026-05-23 fastlane**: iOS Transporter 업로드가 수동.
      `docs/IOS_UPLOAD_TRANSPORTER.md` 참조. Source: 운영. Hint: fastlane
      `deliver` + `pilot` 설정. App Store Connect API key 필요.
