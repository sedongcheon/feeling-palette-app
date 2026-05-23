#!/usr/bin/env bash
# PreToolUse(Write|Edit): generated 산출물 손편집을 거부.
# 차단 대상: *.g.dart, *.freezed.dart, *.mocks.dart, l10n generated,
# firebase_options.dart, build 디렉토리, iOS Pods, Android build, generated docs.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print((d.get("tool_input") or {}).get("file_path",""))')"

case "$file_path" in
  */lib/firebase_options.dart \
  | */lib/l10n/app_localizations*.dart \
  | *.g.dart \
  | *.freezed.dart \
  | *.mocks.dart \
  | */docs/generated/* \
  | */build/* \
  | */ios/Pods/* \
  | */android/app/build/* \
  | */.dart_tool/*)
    >&2 echo "BLOCK: $file_path 는 generated artifact입니다."
    >&2 echo ""
    >&2 echo "Reason: build_runner, flutter gen-l10n, flutterfire configure, gradle, CocoaPods 등이 생성합니다. 손편집은 다음 빌드 시 덮어쓰여집니다."
    >&2 echo ""
    >&2 echo "Fix:"
    >&2 echo "  - *.g.dart / *.freezed.dart → freezed 어노테이션 또는 model 파일을 수정 후 'dart run build_runner build --delete-conflicting-outputs'"
    >&2 echo "  - lib/l10n/app_localizations*.dart → lib/l10n/app_ko.arb 또는 app_en.arb 수정 후 'flutter gen-l10n'"
    >&2 echo "  - lib/firebase_options.dart → 'flutterfire configure' 다시 실행"
    >&2 echo "  - build/, ios/Pods/, android/app/build/, .dart_tool/ → 'flutter clean' 후 재빌드"
    exit 2
    ;;
esac

exit 0
