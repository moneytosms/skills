// The one file you edit per project. Everything else reads from here.
// Placeholders are filled by the skill's scripts/init.sh from `git remote`.
const owner = "moneytosms";
const repoName = "skills";

export default {
  name: "skills",
  tagline: "Agent skills for people on a usage cap.",
  description: "Manual Claude Code skills that move legwork off your most expensive model: offload one task to Codex or a free model, delegate to a Haiku swarm, recall lessons from past sessions.",
  owner,
  repoName,
  branch: "main",
  repoUrl: `https://github.com/${owner}/${repoName}`,
  // Project Pages live at https://OWNER.github.io/REPO/. For a custom domain
  // set site to https://docs.example.com and base to "".
  site: `https://${owner}.github.io`,
  base: `/${repoName}`,
  // Shown in the footer. State real constraints (synthetic data, alpha, etc.).
  footnote: "MIT licensed. Timings quoted are single runs on one laptop.",
  // Markdown rendered in place under /guide (repo-relative globs, "!" excludes).
  // No copies: a doc fixed in the repo is fixed on the site at the next build.
  guide: ["README.md", "skills/*/SKILL.md"],
  guideRoot: "README.md", // becomes /guide/readme; docs/README.md becomes /guide/
};
