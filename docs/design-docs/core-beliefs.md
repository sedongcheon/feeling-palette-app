---
title: Core operating beliefs
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Core beliefs (mechanical principles)

각 원칙은 **analyzer 규칙** 또는 **check 스크립트**(매 변경마다 검사) 또는
**doc-gardener 시그니처**(주간 검사)와 짝지어진다. 어느 쪽도 없는 원칙은
이 파일에 속하지 않는다 — `DESIGN.md`로 옮겨야 한다.

Feeling Palette는 현재 melos/check_layers.dart가 도입 전이므로 일부 원칙은
*수동 검토* 단계에 머문다. 항목은 [tech-debt-tracker](../exec-plans/tech-debt-tracker.md)에 추적.

## 1. Layered domains

> 도메인의 `repo`는 `service|runtime|ui`를 import하지 않는다.
> `service`는 `runtime|ui`를 import하지 않는다. 횡단 관심사는
> `providers/`를 통해서만 들어온다.

- **현재 강제 수단**: 수동 검토 (코드 리뷰).
- **목표 Check**: `tool/check_layers.dart` — 모든 Dart `import`를 파싱해서
  금지된 화살표를 거절. tech-debt 등록.
- **Fix message**: `공유 shape를 lib/models/<name>.dart로 옮기고 거기서 import하거나, providers/를 통해 라우팅하세요.`

## 2. Parse at the boundary

> 모든 입력(AWS API 응답, sqflite row, env var, IAP 콜백, Drive 응답)은
> 모델의 `fromJson`/`fromMap`을 거쳐야 service에 도달한다.

- **현재 강제 수단**: 수동 검토 + `security-reviewer` agent.
- **Analyzer**: `strict-casts: true` (목표 — 현재 미적용. tech-debt 등록).
- **Gardener signature**: regex
  `jsonDecode\([^)]*\)\s+as\s+Map<String,\s*dynamic>` 가 `services/` 내부에
  나오면 위반.
- **Fix message**: `값을 <ModelName>.fromJson(...)으로 감싸 boundary에서 파싱하세요.`

## 3. No YOLO probing

> 알 수 없는 실패에 try/catch를 두르지 말고, `// just in case` 주석 쓰지 말고,
> 문서화되지 않은 retry 추가 금지.

- **현재 강제 수단**: 수동 검토 + `taste-linter` agent.
- **Doc-gardener signature**: regex
  `(just in case|in case it fails|TODO probably|might throw|혹시 모를|catch\s*\(\s*_\s*\)\s*\{\s*\})` in `lib/**/*.dart`.
- **Analyzer**: `only_throw_errors: true` (목표).
- **Fix message**: `테스트로 실패를 재현한 다음, 구체적 예외 타입을 잡아 처리하세요.`

## 4. Structured logging only

> 비-test 소스에서 `print`, `debugPrint`, `developer.log` 금지.

- **현재 강제 수단**: 수동 검토 (`debugPrint` 남아있음 — 점진 제거 중).
- **Analyzer (목표)**: `avoid_print: error` (현재 미적용 — tech-debt).
- **Doc-gardener signature**: `\b(debugPrint|developer\.log)\b` in
  `lib/**/*.dart` (`*_test.dart` 제외).
- **Fix message**: `(미래) lib/services/telemetry.dart의 logger.info({...}, msg)를 사용하거나, 의미 있는 사용자 이벤트면 Firebase Analytics logEvent로 발행하세요.`

## 5. Files ≤ 400 lines

> 긴 파일은 읽기 어렵다. 분할/추출.

- **현재 강제 수단**: 수동 (`taste-linter` agent가 `wc -l` 로 검사).
- **목표 Check**: `tool/check_layers.dart`가 400줄 초과 Dart 파일을 finding.
  `*.g.dart`, `*.freezed.dart`, `app_localizations*.dart` 제외.
- **Fix message**: `가장 큰 pure 블록을 같은 계층의 새 파일로 추출하세요.`

## 6. Shared utility first

> 한 헬퍼가 두 도메인에 등장하면 `packages/shared` (또는 현재는 `lib/utils/`)로 끌어올린다.

- **현재 강제 수단**: 수동.
- **목표 Check**: `tool/check_layers.dart`가 `lib/<domain-a>/* → lib/<domain-b>/*` 거절.
- **Fix message**: `헬퍼를 lib/utils/<area>.dart로 옮기고 거기서 import하세요.`

## 7. One domain per PR

> 한 PR은 정확히 하나의 도메인 하위만 건드린다 (+ 생성 파일 + 공통 utils).

- **현재 강제 수단**: 수동 + `code-reviewer` agent.
- **CI 게이트 (목표)**: `.github/workflows/ci.yml`에 `tool/check_one_domain.dart` 단계.
- **Fix message**: `이 PR을 도메인별로 분할하세요. 도메인당 PR 1개, 서로 링크.`

## 8. Platform parity (Feeling Palette 고유)

> iOS와 Android에서 같은 기능을 동일하게 활성화한다. 한쪽만 비활성화하는
> 임시 가드는 exec-plan으로 추적하지 않으면 금지.

- **현재 강제 수단**: 수동 + `code-reviewer` agent.
- **Gardener signature**: `if\s*\(\s*Platform\.is(iOS|Android)\s*\)` 가 IAP/광고
  관련 service에 등장 시 검토.
- **Fix message**: `플랫폼 분기가 필요한 사유를 docs/exec-plans/active/에 plan으로 기록하고 복구 시점을 명시하세요.`

## 9. App Lock은 옵션 (Feeling Palette 고유)

> 신규 사용자는 PIN 없이 진입한다. PIN 존재 여부 = 잠금 활성 여부.
> Settings에서만 `PinSetupScreen` 진입.

- **현재 강제 수단**: 수동 + 코드 리뷰.
- **위반 예시**: `main.dart`에서 PIN 없는 사용자에게 `LockScreen` push,
  또는 별도 `isLocked` flag 키 도입.
- **Fix message**: `PIN 존재 여부만으로 잠금 활성을 결정하세요. 별도 flag 키 도입 금지. docs/APP_LOCK.md 참조.`

---

## 새 원칙 추가 방법

1. 규칙과 Check/Gardener 시그니처를 이 파일에 작성.
2. `tool/`에 check 구현 (또는 `tool/check_layers.dart`에 확장).
3. 일부러 규칙을 위반하는 fixture를 추가하고 check가 잡는지 확인.
4. 이 concern 하나만 다루는 single PR로 land.
