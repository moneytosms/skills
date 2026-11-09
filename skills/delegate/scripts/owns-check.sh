#!/usr/bin/env bash
# owns-check.sh <run-dir> <unit-id>... -> prints every path owned by more than one unit (from each unit's `owns:` line); exit 1 on overlap
set -euo pipefail
run=$1; shift
for u in "$@"; do
  line=$(grep -m1 -i '^owns:' "$run/units/$u.md") || { echo "$u: no owns: line"; exit 1; }
  for p in ${line#*:}; do echo "$p $u"; done
done | sort | awk '{n[$1]++; us[$1]=us[$1]" "$2} END {bad=0; for (p in n) if (n[p]>1) {print "overlap: " p " ->" us[p]; bad=1} exit bad}' \
  && echo "no overlap ($# units)"
