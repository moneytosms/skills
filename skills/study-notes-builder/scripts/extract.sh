#!/usr/bin/env bash
# Batch-extract source documents to plain text for the study-notes-builder skill.
# Uses `lit` (liteparse) when available; falls back to a note if not.
#
# Usage: extract.sh <src_dir_or_file> <out_dir>
#   extract.sh ./lectures ./scratchpad/txt
set -euo pipefail

SRC="${1:?usage: extract.sh <src_dir_or_file> <out_dir>}"
OUT="${2:?usage: extract.sh <src_dir_or_file> <out_dir>}"
mkdir -p "$OUT"

if ! command -v lit >/dev/null 2>&1; then
  echo "[extract] 'lit' not found — use the Read tool on each source instead." >&2
  exit 3
fi

lit --version >&2 || true

emit() {
  local f="$1"
  local base
  base="$(basename "${f%.*}")"
  echo "[extract] $f -> $OUT/$base.txt" >&2
  lit parse "$f" > "$OUT/$base.txt" 2>/dev/null || \
    echo "[extract] FAILED on $f" >&2
}

if [ -d "$SRC" ]; then
  # common document types liteparse handles
  find "$SRC" -maxdepth 1 -type f \
    \( -iname '*.pdf' -o -iname '*.pptx' -o -iname '*.ppt' -o -iname '*.docx' \
       -o -iname '*.xlsx' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
    -print0 | while IFS= read -r -d '' f; do emit "$f"; done
else
  emit "$SRC"
fi

echo "[extract] done. Text files in $OUT/" >&2
wc -l "$OUT"/*.txt 2>/dev/null | tail -n +1 >&2 || true
