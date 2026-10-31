// The one file you edit per project. Everything else reads from here.
// Placeholders are filled by the skill's scripts/init.sh from `git remote`.
const owner = "OWNER";
const repoName = "REPO";

export default {
  name: "PROJECT_NAME",
  tagline: "One sentence: who it is for and what it does for them.",
  description: "One or two sentences for search results and link previews.",
  owner,
  repoName,
  branch: "main",
  repoUrl: `https://github.com/${owner}/${repoName}`,
  // Project Pages live at https://OWNER.github.io/REPO/. For a custom domain
  // set site to https://docs.example.com and base to "".
  site: `https://${owner}.github.io`,
  base: `/${repoName}`,
  // Shown in the footer. State real constraints (synthetic data, alpha, etc.).
  footnote: "",
  // Markdown rendered in place under /guide (repo-relative globs, "!" excludes).
  // No copies: a doc fixed in the repo is fixed on the site at the next build.
  guide: ["docs/**/*.md", "README.md", "CONTRIBUTING.md"],
  guideRoot: "README.md", // becomes /guide/readme; docs/README.md becomes /guide/
};
