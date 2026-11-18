---
name: offload
description: Hand one low-judgment task (bulk reading, repo-wide search, summarizing logs or docs, boilerplate from a clear spec) to a non-Claude model (Codex CLI or a free opencode model) so it costs no Claude usage. Claude writes the prompt, runs one command and checks the short answer. Run manually with /offload [codex|free|edit] <task>.
argument-hint: "[codex|free|edit] <task>"
disable-model-invocation: true
---

# Offload

Request: $ARGUMENTS

The first word picks the backend. No backend word means `codex`.

| Word | Backend | Use for |
|---|---|---|
| `codex` | `codex exec`, read-only sandbox, your ChatGPT/Codex quota | private repos, anything needing decent quality |
| `free` | `opencode run --agent plan`, a free `opencode/*-free` model | public repos only: free tiers may log or train on prompts |
| `edit` | `codex exec`, workspace-write sandbox | boilerplate, stubs, config, mechanical renames |

Needs `codex` (logged in) for `codex`/`edit`, `opencode` for `free`, and `gh` to confirm a repo is public.

## Good and bad fits

Offload: summarizing big files or logs, "find every use of X", explaining unfamiliar code, doc lookups, boilerplate from a precise spec, mechanical renames.

Keep on Claude, and say so instead of offloading: planning and architecture, multi-file bug fixes, code review and security, writing tests, anything touching secrets, final verification. A single grep or a short file read is cheaper done directly.

## Steps

1. **Don't do the task yourself first.** You write the prompt, run one command, check the answer.
2. **Write the prompt** to `$T/prompt.md`, where `$T` is a fresh dir in your scratchpad. Make it self-contained: exact paths, what to find or produce, the format wanted. End with: "Do not edit files." (unless `edit`) and "Reply in under 30 lines with file:line refs." Never include secrets, `.env` contents or tokens.
3. **Run** from the project root, as one Bash call with a 650000 ms timeout:
   ```bash
   "${CLAUDE_SKILL_DIR}/scripts/offload.sh" <codex|free|edit> "$T/prompt.md" "$T"
   ```
   It refuses (exit 2) on a prompt that looks like it holds a secret, `free` on a repo it can't confirm is public, and `edit` outside git or on a dirty tree. Pass a refusal on to the user; don't work around it. Set `OFFLOAD_ALLOW_FREE=1` only when the user says the code may go to a free provider.
4. **Spot-check** one or two cited `path:line` refs with a ranged Read. If a ref is wrong, say so and don't build on the answer.
5. **`edit` only:** read `git diff`, run the project's tests/lint, and report the result. Reverting (only on the user's say-so) is `git restore .` plus removing the new `??` files the script listed.
6. **On FAILED** (exit 1): report the status line and log tail. Don't silently redo the task on Claude; offer to.

Env knobs: `OFFLOAD_TIMEOUT` (seconds, default 600), `OFFLOAD_CODEX_MODEL`, `OFFLOAD_FREE_MODEL` (falls back to the first listed free model if missing), `OFFLOAD_MAX_LINES` (default 80).

## Report

The script's status line (backend, model, time), the answer, then any ref that failed the spot-check. End with the next step, for example `/offload edit <follow-up>` or what to keep on Claude.
