#!/usr/bin/env bash
# Self-check for offload.sh with stub backends. Run: bash scripts/offload.test.sh
set -u
here=$(cd "$(dirname "$0")" && pwd)
t=$(mktemp -d); trap 'rm -rf "$t"' EXIT
mkdir -p "$t/bin" "$t/repo"
cat >"$t/bin/codex" <<'EOF'
#!/usr/bin/env bash
while [[ $# -gt 1 ]]; do [[ $1 == -o ]] && { shift; echo "codex answer" >"$1"; }; shift; done
EOF
cat >"$t/bin/opencode" <<'EOF'
#!/usr/bin/env bash
[[ $1 == models ]] && { printf 'opencode/a-free\nopencode/b\n'; exit 0; }
echo "free answer from $5"
EOF
cat >"$t/bin/agy" <<'EOF'
#!/usr/bin/env bash
echo "agy answer"
EOF
printf '#!/bin/sh\necho true\n' >"$t/bin/gh"  # every repo reads as private
chmod +x "$t/bin/"*
export PATH="$t/bin:$PATH"
cd "$t/repo" && git init -q && git commit -q --allow-empty -m init
fail=0
check() { # name, expected exit, expected substring, args...
  local name=$1 want=$2 sub=$3; shift 3
  out=$("$here/offload.sh" "$@" 2>&1); rc=$?
  [[ $rc == "$want" && $out == *"$sub"* ]] && echo "ok   $name" || { echo "FAIL $name (rc=$rc): $out"; fail=1; }
}
echo "find the config loader" >"$t/p"
echo "key sk-abcdefghijklmnopqrstuvwxyz123" >"$t/secret"
check "codex answers"          0 "codex answer"           codex "$t/p" "$t/o1"
check "codex pins luna"        0 "gpt-6-luna"             codex "$t/p" "$t/o3"
check "agy answers"            0 "agy answer"             agy "$t/p" "$t/o4"
check "bad mode"               2 "usage"                  nope "$t/p"
check "secret refused"         2 "secret"                 codex "$t/secret"
check "free refused private"   2 "not confirmed public"   free "$t/p"
OFFLOAD_ALLOW_FREE=1 check "free falls back to a listed model" 0 "opencode/a-free" free "$t/p" "$t/o2"
touch dirty
check "edit refuses dirty tree" 2 "clean tree"            edit "$t/p"
exit $fail
