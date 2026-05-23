#!/usr/bin/env bash
# Stop: 코드 변경이 있었던 turn에 대해서만 self-review checklist를 강제.
# 변경(transcript에 Write/Edit tool 사용)이 없으면 통과.
# 변경이 있었으면 transcript 마지막 ~4000자에 다음 마커 중 하나가 필요:
#   SELF-REVIEW: PASS
#   SELF-REVIEW: FAIL — <reason>

set -uo pipefail

input="$(cat)"
transcript_path="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("transcript_path",""))' 2>/dev/null || true)"

# transcript 없거나 못 읽으면 패스 (안전)
if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
  exit 0
fi

# transcript 전체에서 Write/Edit tool 사용 흔적이 있는지 확인 (이번 세션에 코드 변경 있었는지)
if ! grep -qE '"tool_name"[[:space:]]*:[[:space:]]*"(Write|Edit)"' "$transcript_path" 2>/dev/null; then
  exit 0
fi

# 코드 변경이 있었으면 self-review 마커 확인
tail_chars="$(tail -c 4000 "$transcript_path" 2>/dev/null || printf '')"

if printf '%s' "$tail_chars" | grep -q 'SELF-REVIEW: PASS'; then
  exit 0
fi

if printf '%s' "$tail_chars" | grep -q 'SELF-REVIEW: FAIL'; then
  >&2 echo "[harness] SELF-REVIEW: FAIL 감지 — docs/design-docs/self-review-checklist.md 에 따라 escalate 권장."
  exit 0
fi

cat <<'EOF' >&2
BLOCK: self-review checklist 미확인.

이 턴에서 Write/Edit으로 코드를 변경했습니다.
docs/design-docs/self-review-checklist.md 를 걸어보고 최종 메시지에 다음
중 하나를 포함하세요:

  SELF-REVIEW: PASS
  SELF-REVIEW: FAIL — <one-sentence reason>

그 후 턴을 종료하세요.
EOF
exit 2
