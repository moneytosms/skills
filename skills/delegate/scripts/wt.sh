#!/usr/bin/env bash
# wt.sh add   <run-dir> <unit-id>   -> worktree at <run-dir>/wt/<unit> on branch delegate/<run>/<unit>, from HEAD
# wt.sh merge <run-dir> <unit-id>   -> merge that branch into the current branch (stops on conflict)
# wt.sh clean <run-dir> [--keep-branches] -> remove every worktree of this run, prune, delete merged branches
set -euo pipefail

cmd=$1 run=$2
id=$(basename "$run")
root=$(git rev-parse --show-toplevel)

case $cmd in
  add)
    unit=$3
    git -C "$root" worktree add -q "$run/wt/$unit" -b "delegate/$id/$unit" HEAD
    echo "$run/wt/$unit"
    ;;
  merge)
    unit=$3 br="delegate/$id/$unit"
    if [[ -z $(git -C "$root" log --oneline "HEAD..$br") ]]; then
      echo "$unit: no commits, nothing to merge"; exit 0
    fi
    git -C "$root" merge --no-ff -q -m "merge $unit" "$br" \
      || { echo "$unit: MERGE FAILED (conflict or dirty tree, see git output above). Conflict: resolve, then git commit --no-edit"; exit 1; }
    echo "$unit: merged"
    ;;
  clean)
    keep=${3:-}
    for wt in "$run"/wt/*/; do
      [[ -d $wt ]] && git -C "$root" worktree remove --force "$wt"
    done
    git -C "$root" worktree prune
    [[ $keep == --keep-branches ]] && exit 0
    git -C "$root" for-each-ref --format='%(refname:short)' "refs/heads/delegate/$id/" |
      while read -r br; do
        # -d refuses unmerged branches, so unmerged work is never lost
        git -C "$root" branch -q -d "$br" 2>/dev/null || echo "kept unmerged: $br"
      done
    ;;
  *) echo "usage: wt.sh add|merge|clean <run-dir> [unit|--keep-branches]" >&2; exit 2 ;;
esac
