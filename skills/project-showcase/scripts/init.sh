#!/usr/bin/env bash
# Usage: init.sh <project-root>
# Copies the template to <project-root>/site, the Pages workflow to
# <project-root>/.github/workflows/, and fills owner/repo from `git remote`.
# Refuses to overwrite an existing site/.
set -euo pipefail
root=$(cd "${1:?project root}" && pwd)
here=$(cd "$(dirname "$0")/.." && pwd)
[ -e "$root/site" ] && { echo "site/ already exists in $root; edit it instead" >&2; exit 1; }
cp -r "$here/assets/astro-template" "$root/site"
mkdir -p "$root/.github/workflows"
mv "$root/site/.github/workflows/pages.yml" "$root/.github/workflows/pages.yml"
rmdir "$root/site/.github/workflows" "$root/site/.github"
remote=$(git -C "$root" remote get-url origin 2>/dev/null || true)
if [[ "$remote" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
  sed -i "s/const owner = \"OWNER\"/const owner = \"${BASH_REMATCH[1]}\"/; s/const repoName = \"REPO\"/const repoName = \"${BASH_REMATCH[2]}\"/" "$root/site/site.config.mjs"
  echo "owner/repo: ${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
else
  echo "no GitHub remote found: set owner/repoName in site/site.config.mjs" >&2
fi
echo "next: cd $root/site && npm install && npm run dev"
