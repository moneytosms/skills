# Publishing to GitHub Pages

## Steps
1. Workflow is already at `.github/workflows/pages.yml` (from init.sh). It builds, checks, verifies, smoke-tests, and deploys only from `main`; PRs run checks without deploying.
2. Repo Settings > Pages > Build and deployment > Source: **GitHub Actions** (one-time; `gh api` is off-limits per user rules, so tell the user to click it, or use the web UI).
3. Push to `main`. Site appears at `https://OWNER.github.io/REPO/`. Confirm with the user before pushing.
4. Set the repo About description, website and topics (SKILL.md step 10) and add the URL to the README.

## Limits and subdomains (GitHub docs, verify current numbers before quoting)
- Number of Pages sites: **one per repository**, no cap on repositories. Each project repo gets `owner.github.io/repo` for free; the special repo `owner/owner.github.io` is the user/org root site.
- Soft limits: published site <= 1 GB, <= 100 GB/month bandwidth, 10 builds/hour. Not for commercial SaaS.
- Public repos on free plans; private-repo Pages needs a paid plan.
- Custom domains: one per repo. A subdomain per project (`docs.you.dev`, `proj.you.dev`) needs a domain you own plus a CNAME record to `owner.github.io`; set it in Settings > Pages (creates a `CNAME` file; with the Actions deploy, set the domain in settings instead). With a custom domain set `site` to it and `base` to `""` in `site.config.mjs`.
- Enforce HTTPS after DNS propagates.

## Alternatives if Pages is not enough
Cloudflare Pages, Netlify, Vercel: same static `dist/`, unlimited-ish projects, per-project subdomains on their domains.
