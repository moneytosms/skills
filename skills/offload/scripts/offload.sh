#!/usr/bin/env bash
# offload.sh <codex|agy|free|edit> <prompt-file> [out-dir]
# Runs one task on a non-Claude backend and prints a status line plus the answer.
# Env: OFFLOAD_TIMEOUT (s, default 600), OFFLOAD_CODEX_MODEL (default gpt-6-luna), OFFLOAD_CODEX_EFFORT (default high),
#      OFFLOAD_AGY_MODEL (default gemini-3.8-flash-high), OFFLOAD_FREE_MODEL,
#      OFFLOAD_ALLOW_FREE=1 (free backend on a repo not confirmed public), OFFLOAD_MAX_LINES (default 80)
set -uo pipefail

mode=${1:-} prompt_file=${2:-}
out=${3:-$(mktemp -d -t offload-XXXX)}
max=${OFFLOAD_MAX_LINES:-80}
die() { echo "offload: $*" >&2; exit 2; }

[[ $mode =~ ^(codex|agy|free|edit)$ ]] || die "usage: offload.sh <codex|agy|free|edit> <prompt-file> [out-dir]"
[[ -s $prompt_file ]] || die "prompt file missing or empty: $prompt_file"
mkdir -p "$out"

# trust boundary: the prompt leaves the machine
if grep -qE -- '-----BEGIN [A-Z ]*PRIVATE KEY|sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9]{30,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,}' "$prompt_file"; then
  die "prompt looks like it contains a secret; remove it"
fi

in_git() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

case $mode in
  codex|edit)
    command -v codex >/dev/null || die "codex not installed (npm i -g @openai/codex, then codex login)"
    sandbox=read-only
    if [[ $mode == edit ]]; then
      in_git || die "edit needs a git repo so the diff can be reviewed"
      [[ -z $(git status --porcelain) ]] || die "edit needs a clean tree; commit or stash first"
      sandbox=workspace-write
    fi
    model=${OFFLOAD_CODEX_MODEL:-gpt-6-luna}
    effort=${OFFLOAD_CODEX_EFFORT:-high}
    cmd=(codex exec -m "$model" -c "model_reasoning_effort=\"$effort\"" -s "$sandbox" --skip-git-repo-check
      --ephemeral -C "$PWD" -o "$out/answer.md" "$(cat "$prompt_file")")
    ;;
  agy)
    command -v agy >/dev/null || die "agy (Antigravity CLI) not installed"
    model=${OFFLOAD_AGY_MODEL:-gemini-3.8-flash-high}
    # plan mode + terminal sandbox keep it read-only; headless mode auto-denies commands without an allow rule
    cmd=(agy -p "$(cat "$prompt_file")" --mode plan --sandbox --model "$model"
      --settings '{"permissions":{"allow":["command(*)"]}}')
    ;;
  free)
    command -v opencode >/dev/null || die "opencode not installed (https://opencode.ai)"
    if [[ ${OFFLOAD_ALLOW_FREE:-} != 1 ]]; then
      # free tiers may log or train on prompts: only public repos, unless overridden
      in_git && [[ $(gh repo view --json isPrivate -q .isPrivate 2>/dev/null) == false ]] ||
        die "free models may keep your code; repo not confirmed public. Use codex, or set OFFLOAD_ALLOW_FREE=1"
    fi
    models=$(opencode models 2>/dev/null | grep -- '-free$' || true)
    model=${OFFLOAD_FREE_MODEL:-opencode/deepseek-v4.1-flash-free}
    if ! grep -qxF "$model" <<<"$models"; then
      model=$(head -1 <<<"$models")
      [[ -n $model ]] || die "no free opencode models available"
    fi
    cmd=(opencode run --agent plan -m "$model" "$(cat "$prompt_file")")
    ;;
esac

start=$SECONDS
# </dev/null: codex exec otherwise blocks forever reading an open stdin
if [[ $mode == free || $mode == agy ]]; then
  timeout "${OFFLOAD_TIMEOUT:-600}" "${cmd[@]}" </dev/null >"$out/answer.md" 2>"$out/log"
else
  timeout "${OFFLOAD_TIMEOUT:-600}" "${cmd[@]}" </dev/null >"$out/log" 2>&1
fi
rc=$?
secs=$((SECONDS - start))

if [[ $rc -ne 0 || ! -s $out/answer.md ]]; then
  [[ $rc -eq 124 ]] && why="timed out after ${OFFLOAD_TIMEOUT:-600}s" || why="exit $rc"
  echo "offload $mode ($model) FAILED: $why, ${secs}s. Last log lines ($out/log):"
  tail -15 "$out/log"
  exit 1
fi

lines=$(wc -l <"$out/answer.md")
echo "offload $mode ($model) DONE in ${secs}s. Full answer: $out/answer.md"
head -"$max" "$out/answer.md"
[[ -n $(tail -c1 "$out/answer.md") ]] && echo
((lines > max)) && echo "[showing $max/$lines lines; read $out/answer.md for the rest]"
if [[ $mode == edit ]]; then
  echo "--- changed files"
  git status --short
fi
exit 0
