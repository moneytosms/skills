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
  case "${f,,}" in *.pdf) ocr_pdf "$f" ;; esac
}

# Image-heavy PDFs (slides that are pictures, scans): find low-text pages and OCR
# them with tesseract. Writes <base>.ocr.txt and <base>.imgpages.txt; pages in
# imgpages.txt should also be looked at (render with pdftoppm, Read the PNG).
ocr_pdf() {
  local f="$1" base n p words
  base="$(basename "${f%.*}")"
  command -v pdftotext >/dev/null 2>&1 || return 0
  n="$(pdfinfo "$f" 2>/dev/null | awk '/^Pages:/{print $2}')"
  : > "$OUT/$base.imgpages.txt"
  for p in $(seq 1 "${n:-0}"); do
    words="$(pdftotext -f "$p" -l "$p" "$f" - 2>/dev/null | wc -w)"
    [ "$words" -ge 15 ] && continue
    echo "$p" >> "$OUT/$base.imgpages.txt"
    if command -v tesseract >/dev/null 2>&1; then
      pdftoppm -r 200 -f "$p" -l "$p" -png "$f" "$OUT/.ocr-$base" 2>/dev/null
      for img in "$OUT"/.ocr-"$base"*.png; do
        { echo "=== page $p ==="; tesseract "$img" - 2>/dev/null; } >> "$OUT/$base.ocr.txt"
        rm -f "$img"
      done
    fi
  done
  if [ -s "$OUT/$base.imgpages.txt" ]; then
    echo "[extract] $base: $(wc -l < "$OUT/$base.imgpages.txt")/$n low-text pages -> $OUT/$base.imgpages.txt (OCR in $base.ocr.txt)" >&2
  else
    rm -f "$OUT/$base.imgpages.txt"
  fi
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
