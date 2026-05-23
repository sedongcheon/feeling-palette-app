#!/usr/bin/env bash
# PostToolUse(Write|Edit): lib/ 내 Dart 파일이 편집되면 flutter analyze를
# 백그라운드 hint로 출력. 차단하지 않는다 (에이전트가 다음 턴 컨텍스트로
# 활용).
#
# flutter analyze는 첫 실행 시 무거우므로, 변경된 파일이 .dart일 때만 호출.

set -uo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print((d.get("tool_input") or {}).get("file_path",""))')"

# .dart 파일이 아니면 패스
case "$file_path" in
  *.dart) ;;
  *) exit 0 ;;
esac

# generated 파일은 패스 (이미 pre-hook이 차단했어야 하지만 안전망)
case "$file_path" in
  *.g.dart | *.freezed.dart | *.mocks.dart | */l10n/app_localizations*.dart | */firebase_options.dart)
    exit 0
    ;;
esac

# lib/ 외는 패스
case "$file_path" in
  */lib/*) ;;
  *) exit 0 ;;
esac

# 프로젝트 루트로 이동 (.claude/hooks/ 의 상위 2단계)
cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.." 2>/dev/null || exit 0

# flutter analyze 실행 — 무거울 수 있으니 타임아웃과 함께. 결과는 hint로만.
analyze_out="$(timeout 60 flutter analyze --no-fatal-warnings --no-fatal-infos 2>&1 || true)"
if printf '%s' "$analyze_out" | grep -qE 'error -|warning -'; then
  printf '\n[harness] flutter analyze (post-edit):\n%s\n' "$analyze_out"
fi

exit 0
