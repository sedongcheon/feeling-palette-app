# Feeling Palette

Flutter 기반 AI 감정일기 앱. SQLite 로컬 저장, AWS API 분석.

## 빌드/실행
```bash
flutter pub get
flutter run --dart-define-from-file=.env.json
flutter build apk --release --dart-define-from-file=.env.json
flutter build ipa --release --dart-define-from-file=.env.json
```
API 키는 `.env.json`에서 주입 — 하드코딩 금지.

## 아키텍처
- `lib/main.dart` — Firebase·Crashlytics·IAP 부트스트랩
- `lib/screens/` — 10개 화면 (calendar, timeline, stats, settings 등)
- `lib/services/` — ads, auth, backup, drive_backup, emotion_analyzer,
  month_summary, premium, weekly_insight, consent
- `lib/providers/` — DiaryProvider, AuthProvider (ChangeNotifier)
- `lib/db/` — sqflite DAO (diary, month_summary, weekly_insight)
- `lib/models/`, `lib/widgets/`, `lib/constants/` — 모델/공용 위젯/상수
- `lib/l10n/` — ARB 다국어 (ko 템플릿, en). `l10n.yaml` 설정, build 시 `AppLocalizations` 자동 생성

API: `https://feeling-api-aws.sedoli.co.kr`

## 플랫폼 특이사항
- **iOS / Android**: IAP·광고 모두 동일하게 활성화 (`PremiumService.initialize()`,
  `AdsService.initialize()` 양 플랫폼 호출). 한때 iOS만 Apple Paid Apps Agreement
  미완료로 IAP 분기 비활성화했지만 현재는 가드 제거됨.
- **Android 15 SDK 35**: edge-to-edge 필수. `SystemUiOverlayStyle`에서
  statusBar/navigationBar 색상 필드 비워둠 (deprecated 회피).
- **Samsung 기기**: secure storage 무한 로딩 이슈 → `_init` 5s,
  read 3s 타임아웃.

## Firebase
- `firebase_options.dart` 자동생성. Crashlytics는 release만 수집.
- `firebase.json` 참고.

## docs/
- `IOS_RELEASE_GUIDE.md`, `IOS_UPLOAD_TRANSPORTER.md` — iOS 출시
- `ADS_PLAN.md`, `ADS_TESTING.md` — AdMob
- `IAP_SETUP.md`, `APP_LOCK.md`, `DIARY_FEATURES.md`
- `AWS_INFRA.md`, `RELEASE_PREP.md`
- `STORE_METADATA.md`, `STORE_METADATA_EN.md`, `STORE_SCREENSHOTS.md` — 스토어 출시 자료
- `PRIVACY_POLICY_KO.md`, `PRIVACY_POLICY_EN.md`, `PRIVACY_POLICY_HOSTING.md` — 개인정보처리방침 + 호스팅
- `GOOGLE_DRIVE_SETUP.md` — Drive 백업 설정

## Gotchas
- 앱 잠금은 옵션. 신규 사용자는 PIN 없이 바로 진입하고 Settings → "앱 잠금 사용"에서
  켜야 PinSetupScreen 진입. PIN 존재 여부 = 잠금 활성 여부 (별도 키 없음).
  Play Console이 잠금 우회 정보 없이도 검토할 수 있게 한 설계.
- `flutter build ipa` 전 Xcode에서 Team 한 번 지정 필요 (인증서 생성).
- 시크릿(`.env.json`, `*.jks`, `*.p12`, `key.properties`) gitignore 등록됨.
- 빌드 번호 증가 시 `pubspec.yaml` `version:` 필드 (`X.Y.Z+빌드` 형식).
- ARB 수정 후 `flutter gen-l10n` 또는 `flutter run`/`build`로 `AppLocalizations` 재생성.
