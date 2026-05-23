---
name: run-build
description: Build Feeling Palette for Android/iOS, with the .env.json secret injection convention. Use to verify build-ability before merge, or to ship a release artifact.
status: living
last_verified: 2026-05-23
---

# Skill: run-build (Feeling Palette)

`.env.json` 시크릿 주입 컨벤션을 따르는 빌드 명령 모음.

## Debug 빌드 (CI / verify용)

```bash
# Android
flutter build apk --debug --dart-define-from-file=.env.json

# iOS (no codesign — verify만)
flutter build ios --debug --no-codesign --dart-define-from-file=.env.json
```

목적: 컴파일 가능 여부 확인. PR verify 단계.

## Release 빌드 (출시용)

```bash
# Android APK (직접 배포)
flutter build apk --release --dart-define-from-file=.env.json

# Android App Bundle (Play Console 업로드)
flutter build appbundle --release --dart-define-from-file=.env.json

# iOS .ipa (Xcode에서 Team 한 번 지정한 후)
flutter build ipa --release --dart-define-from-file=.env.json
```

**iOS 주의**: `flutter build ipa` 전 Xcode에서 Team 한 번 지정 필요 (인증서 생성).
[feedback_ios_build_signing 메모리]

## 사전 점검

- `.env.json` 존재 (`ls .env.json`).
- `pubspec.yaml`의 `version:` 필드가 출시 의도와 맞음 (`X.Y.Z+빌드`).
- `flutter pub get` 신규 실행.
- `flutter analyze` clean.
- `flutter gen-l10n` 또는 build가 알아서 호출함.

## 출시 후 단계

- Android: `build/app/outputs/bundle/release/app-release.aab` → Play Console
  업로드 (`docs/RELEASE_PREP.md`).
- iOS: `build/ios/ipa/Runner.ipa` → Transporter 앱 또는 fastlane으로 App Store
  Connect 업로드 (`docs/IOS_UPLOAD_TRANSPORTER.md`).

## 클린 빌드 (캐시 문제 시)

```bash
flutter clean
rm -rf ~/Library/Developer/Xcode/DerivedData/*
cd ios && pod install --repo-update && cd ..
flutter pub get
flutter build apk --debug --dart-define-from-file=.env.json
```

## 빌드 번호 bump

```bash
# pubspec.yaml의 version: X.Y.Z+빌드 — 수동 수정
# 예: 1.0.3+15 → 1.0.3+16

# 그 후 release 빌드
flutter build appbundle --release --dart-define-from-file=.env.json
```

빌드 번호는 스토어가 같은 버전 재업로드를 거부하므로 항상 monotonic 증가.

## 관련

- [docs/RELEASE_PREP.md](../../docs/RELEASE_PREP.md)
- [docs/IOS_RELEASE_GUIDE.md](../../docs/IOS_RELEASE_GUIDE.md)
- [docs/IOS_UPLOAD_TRANSPORTER.md](../../docs/IOS_UPLOAD_TRANSPORTER.md)
