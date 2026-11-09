#!/usr/bin/env bash
# mine.sh <run-dir> <batch-id>   (RECALL_MODEL=sonnet to escalate, default haiku)
# One lean headless Haiku miner over <run-dir>/batches/<batch-id>.md.
# Writes <run-dir>/findings/<batch-id>.json and prints one status line.
set -euo pipefail

run=$1 batch=$2
skill=$(cd "$(dirname "$0")/.." && pwd)
[[ -f $run/batches/$batch.md ]] || { echo "$batch FAILED: missing batch file"; exit 2; }
mkdir -p "$run/findings"

prompt="Excerpts: $run/batches/$batch.md
Write your findings to: $run/findings/$batch.json"

# Lean worker: own system prompt, read/write only, no MCP, no user settings or hooks.
raw=$(CLAUDE_CODE_PROMPT_CACHE_TTL=5m claude -p \
  --model "${RECALL_MODEL:-haiku}" \
  --system-prompt-file "$skill/roles/miner.md" \
  --tools "Read,Write" --allowedTools "Read,Write" \
  --strict-mcp-config --setting-sources "" \
  --permission-mode acceptEdits \
  --add-dir "$run" \
  --output-format json \
  "$prompt" 2>&1 | grep '^{' | tail -n1) || true

[[ -n $raw ]] || { echo "$batch FAILED: miner produced no output"; exit 1; }
printf '%s\n' "$raw" > "$run/findings/$batch.meta.json"
[[ -f $run/findings/$batch.json ]] || { echo "$batch FAILED: no findings file"; exit 1; }
echo "$batch $(jq -r '.result // ""' <<<"$raw" | tail -n1) · \$$(jq -r '.total_cost_usd // 0' <<<"$raw")"
