#!/usr/bin/env bash
# html-to-pdf.sh <in.html> <out.pdf> : headless chromium print. Waits for
# KaTeX/Three.js (virtual time) then fails if the PDF is empty.
set -euo pipefail
in=$(realpath "$1"); out=$(realpath -m "$2")
chrome=$(command -v chromium || command -v google-chrome-stable || command -v chrome) || { echo "no chromium"; exit 1; }
"$chrome" --headless=new --no-sandbox --disable-gpu --allow-file-access-from-files \
  --virtual-time-budget=15000 --no-pdf-header-footer --print-to-pdf="$out" "file://$in" 2>/dev/null
[ -s "$out" ] && echo "ok: $out ($(pdfinfo "$out" 2>/dev/null | rg '^Pages' || true))" || { echo "empty pdf"; exit 1; }
