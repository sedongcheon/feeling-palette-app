---
name: warn-non-flutter-edit
enabled: true
event: file
action: warn
conditions:
  - field: file_path
    operator: regex_match
    pattern: (?:^|/)(?:ios|android|macos|windows|linux|build|\.dart_tool)(?:/|$)
---

⚠️ **Flutter 소스 외 파일 편집 시도**

이 프로젝트는 **Flutter 소스(lib/, test/, pubspec, assets/)만 수정**하는 규칙이 있습니다.

지금 편집하려는 파일은 네이티브/빌드 산출물 영역입니다:
- `ios/`, `android/`, `macos/`, `windows/`, `linux/` — 네이티브 플랫폼 코드
- `build/`, `.dart_tool/` — 빌드 산출물 (재생성됨)

**계속 진행하기 전에 확인:**
- 정말 Flutter 레이어(Dart/pubspec/assets)에서 해결할 수 없는 작업인가요?
- 네이티브 수정이 필요한 합리적인 사유가 있나요? (예: Info.plist 권한 키, AndroidManifest, 서명 설정, Crashlytics 설치 등)

사유가 있다면 사용자에게 한 줄로 설명한 뒤 진행하세요. 아니라면 Dart 코드로 해결하는 방법을 먼저 고민해보세요.
