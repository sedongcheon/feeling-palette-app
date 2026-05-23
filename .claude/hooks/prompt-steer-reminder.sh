#!/usr/bin/env bash
# UserPromptSubmit: 사용자가 직접 코드를 짤려고 하면 gentle reminder.
# 비차단.

set -uo pipefail

input="$(cat)"
prompt="$(printf '%s' "$input" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("prompt",""))')"

needles=(
  "내가 짤게"
  "내가 작성"
  "내가 수정"
  "직접 수정"
  "직접 짤게"
  "i'll write it"
  "i will write it"
  "let me write"
  "i'll do it manually"
)

prompt_lc="$(printf '%s' "$prompt" | tr '[:upper:]' '[:lower:]')"
for n in "${needles[@]}"; do
  if printf '%s' "$prompt_lc" | grep -qF -- "$n"; then
    cat <<'EOF'

[harness reminder] Humans steer. Agents execute.

만약 에이전트의 결정을 override하고 싶다면, 장기적으로 더 나은 방법은
그 제약을 harness에 인코딩하는 것입니다 — analyzer 룰, doc, skill, subagent.
그래야 다음 변경부터 자동으로 반영됩니다.

일회성이면 무시. 패턴이면 docs/exec-plans/active/ 에 plan을 열어 harness를
강화하세요.
EOF
    exit 0
  fi
done

exit 0
