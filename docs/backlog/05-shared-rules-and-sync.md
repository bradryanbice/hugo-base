Shared rules and managed file sync

## Summary

Make hugo-base the single source of truth for how every site is built and maintained. Conventions live in the module as rule files. A sync tool copies them, plus a small set of other managed files, into each consuming site at the exact module version that site pins. CI fails when a site's copies are stale, so a hugo-base bump carries its updated instructions with it in the same PR.

## Detailed scope

- `agents/rules/` in this repo: the shared rule set, one topic per file, written for both humans and Claude.
  - `principles.md` (always loaded): the scope test, progressive enhancement, no dashes in prose, upstream first (a change true for every site goes to hugo-base, not into one site).
  - `accessibility.md` (always loaded): the WCAG 2.2 AA rules.
  - `css.md` (scoped with `paths` to `assets/css/**`): OKLCH only, token layering, the 8pt scale, cascade layers, which files are foundation and must not be overridden, how to theme.
  - `templates.md` (scoped to `layouts/**`): v0.146+ template layout, override rules, the stable seam list, hooks.
  - `content.md` (scoped to `content/**`, `archetypes/**`): front matter conventions, image and alt rules, shortcode usage.
  - `maintenance.md` (always loaded): toolchain and version sync, handling Renovate PRs, never edit managed files, running the upgrade skill, `hugo mod tidy` not `go mod tidy`.
- `agents/skills/hugo-base-upgrade/SKILL.md`: placeholder here, filled in by issue 16.
- `tools/managed-files.toml`: the manifest of files hugo-base owns inside a consuming site, mapping source to destination:
  - `agents/rules/*` to `.claude/rules/hugo-base/*`
  - `agents/skills/*` to `.claude/skills/*`
  - `tools/templates/pull_request_template.md` to `.github/pull_request_template.md`
  - `tools/templates/editorconfig` to `.editorconfig`
  - `tools/templates/site-ci.yml` to `.github/workflows/ci.yml` (the thin caller from the CI distribution decision)
- `tools/sync.sh`: copies manifest entries into the site, prepends a "managed by hugo-base vX.Y.Z, do not edit" header where the format allows, deletes files that were removed from the manifest, and supports `--check` (exit non-zero and print a diff if anything is out of date).
- `tools/templates/hugo-base.sh`: a tiny stub committed in each site (itself a managed file). It finds the module directory for the version in `go.mod` and runs that version's `tools/sync.sh`. The logic therefore always matches the pinned version.
- Dogfooding: this repo's `.claude/rules/shared` is a symlink to `../../agents/rules`, so Claude working on hugo-base follows the same rules it ships. `CLAUDE.md` keeps only base-maintenance guidance.
- Reusable CI workflow: add a `hugo-base.sh sync --check` step.

## Design or architecture considerations

- Why committed copies instead of reading the module cache directly:
  - Claude Code treats an `@import` or rules symlink that points outside the working directory as external. It prompts for approval, and path-scoped external rules do not load at all. Files inside the repo load with no prompt.
  - Committed copies show up in the Renovate PR diff. Anyone reviewing a hugo-base bump sees exactly which instructions changed.
  - Copies work for any tool (other agents, humans) and in CI without Go or Hugo being able to fetch.
- Why version pinned rather than latest: the instructions a site follows must describe the code that site actually has. A Claude plugin marketplace would deliver the latest rules independently of `go.mod`, so the rules could describe tokens or partials the site does not have yet.
- Locating the module: `hugo config mounts` prints a JSON block per module, including its `dir` on disk (verified locally on v0.166.0). With a local replacement, `path` shows the replacement path instead of the module path. So the stub should identify hugo-base by a marker file (for example `tools/managed-files.toml`) in `dir`, not by `path`.
- Go's module cache is read-only. The sync tool must copy out of it and never write into it.
- Rules are context, not enforcement. The Claude Code docs say so explicitly. Every rule that can be checked by a machine must also be enforced in CI (issue 08, the a11y gate, the dash lint). Prose rules are for judgment calls only.
- Site owned files stay site owned: `CLAUDE.md`, `.claude/settings.json`, `README.md`, `netlify.toml`, `mise.toml`, config. The sync tool never touches a path not in the manifest.

## Task checklist

- [ ] Draft the six rule files by moving the non-negotiables out of `CLAUDE.md`
- [ ] `paths` frontmatter on scoped rules
- [ ] Manifest format and `tools/managed-files.toml`
- [ ] `tools/sync.sh` with write, prune, and `--check`
- [ ] `hugo-base.sh` stub using `hugo config mounts` and the marker file
- [ ] Symlink for dogfooding, trim `CLAUDE.md`
- [ ] Sync check step in the reusable workflow
- [ ] exampleSite runs the sync, and its managed files are committed
- [ ] Dash lint covers `agents/`

## Acceptance criteria

- Running `./hugo-base.sh sync` in exampleSite produces `.claude/rules/hugo-base/*` and the other managed files, each marked as managed.
- Changing a rule in `agents/rules/` without re-syncing exampleSite turns CI red with a readable diff.
- A Claude Code session opened in exampleSite lists the hugo-base rules in `/memory`, and the CSS rule loads only when a CSS file is read.
- Deleting a rule from the manifest removes it from the site on the next sync.
- The stub works both with a local replacement and with a tagged remote version.

## Open questions

- Decided 2026-09-18: managed files are committed in consuming sites (visible in PR diffs, no dependency on Hugo or Go at session start). A `SessionStart` hook was considered and rejected.
- Do sites need to override a rule locally? Recommend no overrides of managed rules. A site adds its own `.claude/rules/site/*.md` for site-specific guidance, and any real exception becomes a hugo-base issue.
- Does `hugo mod vendor` copy non-component files such as `agents/` and `tools/`? If a site vendors, the stub could read from `_vendor/`. A local test with a replaced module did not vendor it, so this needs a test against a real tagged remote.
- Should the stub use `jq` (installed through mise) to parse `hugo config mounts`, or avoid the dependency?
