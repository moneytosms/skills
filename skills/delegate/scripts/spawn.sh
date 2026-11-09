#!/usr/bin/env bash
# spawn.sh <role> <run-dir> <unit-id> [workdir]   (DELEGATE_MODEL=sonnet to escalate, default haiku)
# Runs one lean headless Haiku worker. Prints one status line; full output in <run-dir>/results/.
set -euo pipefail

role=$1 run=$2 unit=$3 workdir=${4:-$PWD}
skill=$(cd "$(dirname "$0")/.." && pwd)

case $role in
  # Write for every role: scouts/verifiers need it for their result file (role prompt forbids project writes)
  scout)    tools="Read,Grep,Glob,Write,Bash,WebSearch,WebFetch" ;;
  editor)   tools="Read,Grep,Glob,Edit,Write,Bash" ;;
  verifier) tools="Read,Grep,Glob,Write,Bash" ;;
  *) echo "unknown role: $role (scout|editor|verifier)" >&2; exit 2 ;;
esac

for f in "$skill/roles/$role.md" "$run/brief.md" "$run/units/$unit.md"; do
  [[ -f $f ]] || { echo "missing: $f" >&2; exit 2; }
done
mkdir -p "$run/results"

prompt="$(cat "$run/brief.md")

---

$(cat "$run/units/$unit.md")

---
Run dir: $run
Write your full result to: $run/results/$unit.md"

# User's tool hooks (safety guards, rtk) without plugins or other settings; SessionStart hooks dropped,
# they're per-session side effects a worker doesn't need.
hooks=$(jq -c '{hooks: ((.hooks // {}) | del(.SessionStart))}' ~/.claude/settings.json 2>/dev/null || echo '{}')
settings=$(jq -c --argjson h "$hooks" '. + $h' <<<'{"attribution":{"commit":"","pr":"","sessionUrl":false}}')

cd "$workdir"
# Own Compose project per container-allowed unit, so parallel stacks never share names, networks or volumes.
if grep -qi '^containers: *yes' "$run/units/$unit.md"; then
  export COMPOSE_PROJECT_NAME
  COMPOSE_PROJECT_NAME=$(tr 'A-Z' 'a-z' <<<"$(basename "$run")-$unit" | tr -c 'a-z0-9_\n-' '-')
fi
# Lean worker: own system prompt, only the role's tools, no MCP, no user/project settings or hooks.
# 5m cache: worker turns are seconds apart, the 1h default on subscriptions buys nothing.
# Autocompact at 100k (CLI minimum) keeps Haiku's context small enough to stay sharp.
raw=$(CLAUDE_CODE_PROMPT_CACHE_TTL=5m claude -p \
  --model "${DELEGATE_MODEL:-haiku}" \
  --system-prompt-file "$skill/roles/$role.md" \
  --tools "$tools" --allowedTools "$tools" \
  --strict-mcp-config --setting-sources "" \
  --settings "$settings" \
  --permission-mode acceptEdits \
  --add-dir "$run" \
  --autocompact 100000 \
  --output-format json \
  "$prompt" 2>&1 | grep '^{' | tail -n1) || true

if [[ -z $raw ]]; then
  echo "$unit FAILED: worker produced no output"; exit 1
fi
printf '%s\n' "$raw" > "$run/results/$unit.json"

result=$(jq -r '.result // ""' <<<"$raw")
[[ -f $run/results/$unit.md ]] || printf '%s\n' "$result" > "$run/results/$unit.md"

if [[ $(jq -r '.is_error' <<<"$raw") == true ]]; then
  echo "$unit FAILED: $(head -c 300 <<<"$result")"; exit 1
fi
# Last line of the worker's reply is its status line (DONE|BLOCKED|FAILED: ...).
echo "$unit $(tail -n1 <<<"$result")"
