---
title: Security model
owner: harness-engineer
status: living
last_verified: 2026-05-23
---

# Security

## Trust boundaries

| Boundary                          | 검증 위치                                                     |
|-----------------------------------|---------------------------------------------------------------|
| AWS API 응답 본문                 | 모델의 `fromJson` (감정 분석 응답, 월간/주간 인사이트 등)      |
| sqflite row                       | 모델의 `fromMap` (`lib/models/<n>.dart`)                       |
| `.env.json` 환경 변수             | `String.fromEnvironment` (현재) — 향후 단일 Env 파서로 통합    |
| Google Drive API 응답             | `lib/services/drive_backup_service.dart` 내 파싱               |
| IAP 콜백 (`PurchaseDetails`)      | `lib/services/premium_service.dart`                            |
| AdMob 콜백                        | `lib/services/ads_service.dart`                                |
| Deep link / app link              | (현재 미사용 — 도입 시 단일 라우터 파서로)                     |
| secure storage 값                 | `flutter_secure_storage` → 로드 시 형식 검증                   |
| Firebase Auth 토큰                | Firebase SDK                                                   |

리포 외부에서 들어온 모든 데이터는 **boundary에서 파싱**한다. 내부 코드에는
`dynamic` 금지, `as Foo` (가드 없음) 금지.

## Authn / authz

- **Firebase Auth**: Google 로그인 사용. 토큰은 Firebase SDK가 관리.
- **App Lock (옵션)**: PIN 4자리. 신규 사용자는 PIN 없이 진입.
  Settings → "앱 잠금 사용" 토글 시 `PinSetupScreen` 진입.
  PIN 존재 여부 = 잠금 활성 여부 (별도 flag 키 없음).
  Play Console 검토 회피 설계 (`docs/APP_LOCK.md`).
- **API 인증**: 현재 미적용 (퍼블릭 엔드포인트). 향후 API key 도입 시
  `flutter_secure_storage` 저장.

## Secret handling

- 시크릿은 `.env.json` (gitignored)에 저장하고 `--dart-define-from-file`로 주입.
  하드코딩 절대 금지.
- gitignored: `.env.json`, `*.jks`, `*.p12`, `key.properties`, `*.keystore`,
  `GoogleService-Info.plist` (확인 필요), `google-services.json` (확인 필요).
- secure storage 키:
  - `pin` — 사용자 4자리 PIN (해시 권장 — 현재 평문 저장 시 tech-debt에 등록)
- 로그에 `password|token|secret|key|cookie|authorization|pin` 같은 필드명
  포함 금지. 향후 taste-linter regex가 잡는다.
- `security-reviewer` 서브에이전트가 diff에 대해 `gitleaks` 재실행 (도입 시).

## 모바일 특이사항

- **iOS ATS**: `NSAllowsArbitraryLoads` = `false`. `Info.plist` 확인.
- **Android cleartext**: `android:usesCleartextTraffic` = `false`
  (테스트 빌드 외).
- **WebView**: 현재 사용 없음. 도입 시 `javascriptMode: disabled` 기본,
  화이트리스트 라우트만 활성화.
- **secure storage**: Samsung 기기 무한 로딩 회피용 `_init: 5s`, `read: 3s`
  타임아웃 — `lib/services/auth_service.dart`.

## Dependency policy

- 새 런타임 dependency는 `docs/design-docs/dep-<pkg>.md` 노트 필요:
  - license, 유지보수 신호 (last release, GitHub stars/issues), 패키지 무게.
- `pubspec.lock` 변경은 PR 설명에 언급. 의존성 추가 없는 PR이 lock을 바꾸면
  `code-reviewer`가 의문 제기.
- `flutter pub outdated --mode=affected` 정기 점검 (현재 수동).

## OWASP top-10 mapping

| 위험                         | 통제                                                          |
|------------------------------|---------------------------------------------------------------|
| A01 Broken access control    | App Lock + Firebase Auth; 백엔드 권한 (서버 측 응답)          |
| A02 Cryptographic failures   | Firebase·Apple/Google SDK 표준 암호화; 자체 crypto 금지       |
| A03 Injection                | sqflite parameterized queries (`?` placeholder); `fromJson` 파싱 |
| A04 Insecure design          | 계층 분리 + design-docs/ 결정 노트                            |
| A05 Misconfiguration         | `.env.json` (gitignored); ATS strict; Crashlytics release-only |
| A06 Vulnerable components    | `flutter pub outdated` 주기적 확인                             |
| A07 Identification failures  | Firebase Auth (Google SSO)                                    |
| A08 Software/data integrity  | `pubspec.lock` 커밋; CI는 frozen lock으로 설치                |
| A09 Logging/monitoring       | Crashlytics + Analytics + 백엔드 CloudWatch                   |
| A10 SSRF                     | 클라이언트 → 자체 API + Firebase + Drive + AdMob — 화이트리스트화 |

## `security-reviewer` 서브에이전트가 점검하는 것

- diff에서 새 I/O가 boundary 모델(`fromJson`/`fromMap`) 없이 들어왔는지.
- 새 Navigator 라우트가 잠금 가드 없이 추가됐는지.
- `pubspec.lock` diff에 advisory.
- 하드코딩된 secret (gitleaks regex).
- cross-domain import 중 파싱 누락.
- secure storage가 아닌 `SharedPreferences`에 secret 저장.

## 관련 문서

- [docs/PRIVACY_POLICY_KO.md](PRIVACY_POLICY_KO.md), [PRIVACY_POLICY_EN.md](PRIVACY_POLICY_EN.md)
- [docs/APP_LOCK.md](APP_LOCK.md)
- [docs/AWS_INFRA.md](AWS_INFRA.md)
- [docs/RELEASE_PREP.md](RELEASE_PREP.md)
