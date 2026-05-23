---
title: Self-review checklist
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Self-review checklist

reviewer agent에 넘기기 전 이 리스트를 실행한다. `Stop` hook은
최종 메시지에 `SELF-REVIEW: PASS` 마커가 보일 때까지 yield를 거부한다.

## 1. Plan & diff alignment

- [ ] diff가 exec-plan의 "Phases" 섹션과 일치.
- [ ] 범위가 변했다면 plan의 **Decision log**에 새 row.

## 2. Architecture

- [ ] `flutter analyze`가 clean.
- [ ] 새 cross-domain import 없음.
- [ ] 새 provider가 추가됐다면 `docs/design-docs/<slug>.md` 노트 작성.
- [ ] (향후) `dart run tool/check_layers.dart` clean.

## 3. Boundary parsing

- [ ] 새 HTTP 호출은 응답을 모델의 `fromJson`/`fromMap`으로 파싱.
- [ ] 새 sqflite 쿼리는 row를 `<Model>.fromMap`으로 파싱.
- [ ] 새 env var는 `.env.example`에 키 등록.
- [ ] 새 외부 API 호출은 응답 스키마가 도메인 모델로 존재.

## 4. Observability

- [ ] 새 service 함수가 의미 있는 실패(API 오류 등)에서 Crashlytics
  `recordError(e, stack, reason: ...)` 호출.
- [ ] 의미 있는 사용자 이벤트는 Firebase Analytics `logEvent`로 발행.
- [ ] `debugPrint`/`print` 신규 추가 없음 (정말 디버그 일회용이면 PR 전 제거).

## 5. Tests

- [ ] 새 service에 happy-path 1개 + boundary 1개 이상.
- [ ] 사용자 가시 변경이면 `integration_test/` 시나리오 추가/연장 (현재
  통합 테스트 인프라 없음 — 수동 시나리오 + 스크린샷도 OK).
- [ ] `flutter test` pass.

## 6. Codegen

- [ ] freezed/json_serializable annotation 변경 시
  `dart run build_runner build --delete-conflicting-outputs` 실행.
- [ ] `*.g.dart`, `*.freezed.dart`, `firebase_options.dart`,
  `lib/l10n/app_localizations*.dart` 손편집 없음.

## 7. l10n

- [ ] 새 사용자 문자열은 `lib/l10n/app_ko.arb`(템플릿)에 키 추가.
- [ ] `lib/l10n/app_en.arb`에도 동일 키.
- [ ] `flutter gen-l10n` 또는 `flutter run` 후 `AppLocalizations`에 메서드
  생성 확인.
- [ ] 하드코딩된 한글/영문 문자열 없음 (스크립트로 grep).

## 8. 플랫폼 점검

- [ ] iOS와 Android 동일 활성화 (IAP·광고).
- [ ] `pubspec.yaml`의 `version:` bump가 필요했다면 적용 (`X.Y.Z+빌드`).
- [ ] secret/key 하드코딩 없음 (`.env.json` 사용).
- [ ] `git status`에 추적 안 된 시크릿 파일 없음 (gitignored 확인).

## 9. Docs

- [ ] 도메인 capability를 추가/변경했다면 `docs/product-specs/<name>.md` 갱신.
- [ ] architecture를 건드렸다면 `docs/ARCHITECTURE.md`가 여전히 참인지 확인.
- [ ] generated 디렉토리 손편집 없음.
- [ ] 출시 관련(스토어 메타데이터, 스크린샷, IAP/광고 설정) 변경은
  `docs/RELEASE_PREP.md` 또는 해당 가이드에 반영.

## 10. Marker

최종 assistant 메시지에 정확히 다음 줄을 포함한다:

```
SELF-REVIEW: PASS
```

체크박스 중 정직하게 체크할 수 없는 항목이 있으면
`SELF-REVIEW: FAIL — <one-sentence reason>`을 적고 gap을 surface.
`Stop` hook은 `FAIL`을 escalation 신호로 취급(yield는 허용).
