# CLAUDE.md

Guidance for maintaining `hugo-base` itself. Read this before changing anything.

The rules that apply to the code (accessibility, CSS and tokens, templates,
content, maintenance) live in `agents/rules/` and are loaded through
`.claude/rules/shared`, a symlink to that directory. This repo follows the same
rules it ships. If this file and a rule ever disagree, the rule wins and this
file must be corrected.

In short, the non-negotiables are: WCAG 2.2 AA, OKLCH color with layered
tokens, an 8pt spacing scale, no CSS framework and no build step beyond Hugo
Pipes, progressive enhancement, and no em or en dashes in prose. Each is
spelled out in `agents/rules/`.

## What this repo is

`hugo-base` is a Hugo Module (`github.com/bradryanbice/hugo-base`). It is
theme-shaped, not a site. Consuming sites import it through `module.imports`
and override individual files by placing their own copy at the same path. It is
versioned with git tags and semver (`vMAJOR.MINOR.PATCH`). While the version is
`0.x`, a MINOR bump may break consumers and must say so in `CHANGELOG.md`.

Consumers today: bradbice.com, royalrumblestats.com, playoffsbracket.com,
headedapp.com, calaround.app, plus an upcoming political statistics site.

`bradryanbice/hugo-starter` is the companion template for new sites: config,
brand inputs and nothing else. It takes its CI workflow and rules from this
module through the sync, so it cannot drift. When something a new site needs is
missing, the fix usually belongs here rather than in the template.

## The scope test

Before adding anything, ask: would this be true for every consuming site? If it
would only be true for one site, it does not belong here.

In scope: design tokens (slots and neutral defaults), reset, typography, base
layouts (`baseof`, `single`, `list`, `404`), head, SEO and schema partials,
header, footer, nav shell, skip link, sitemap and feed output, image processing
pipeline, the shared shortcodes (`figure`, `callout`, `table`), archetypes, the
reusable CI workflow, the Renovate preset, the shared rules, and `exampleSite/`.

Out of scope, always: domain names, brand color values, navigation content,
analytics IDs, any data schema, any content-type-specific layout, chart
components (explicitly deferred).

## Where things are written down

| Audience | File |
|---|---|
| maintaining the base | this file |
| every consuming site | `agents/rules/`, synced into each site |
| someone adopting or using the base | `README.md` |
| why a non-obvious choice was made | `docs/decisions/` |
| what changed, and what a site must do | `CHANGELOG.md` and `migrations/` |

Keep each fact in one of those, not several. When a convention changes, the
rule file is the source of truth and the others point at it.

## Repository layout

| Path | What it holds |
|---|---|
| `layouts/`, `assets/`, `i18n/`, `archetypes/` | the module itself, what consumers get |
| `agents/rules/` | the shared rules, synced into every site |
| `agents/skills/` | skills synced into every site |
| `tools/managed-files.toml` | what hugo-base owns inside a site, and the marker that identifies the module on disk |
| `tools/sync.py` | copies managed files into a site, `--check` fails when stale |
| `tools/templates/` | the files a site receives (CI caller, PR template, editorconfig, the `hugo-base.sh` stub) |
| `tools/ci/`, `tools/quality/` | the gate, run from the version a site pins |
| `renovate/hugo.json` | shared Renovate preset |
| `exampleSite/` | the test harness, and the first consumer of the sync |
| `migrations/` | one note per release that needs work in a site |
| `docs/decisions/` | decision records |

## How a change reaches the sites

Three things travel, all pinned to the version a site has in `go.mod`:

1. **Code**, through the module.
2. **Instructions**, through `agents/` and the sync tool, as committed copies in
   each site.
3. **Enforcement**, through `tools/` run by the reusable workflow.

So a convention change is one pull request containing the rule edit, the CI
enforcement for it where a machine can check it, and a `migrations/vX.Y.Z.md`
note telling sites how to comply. A rule with no enforcement and no migration
is incomplete. Rules are context, not enforcement: anything checkable must also
be checked.

## Hugo conventions

`agents/rules/templates.md` holds the template system rules, which apply here
too. Two more that matter only in this repo:

- Do not define `module.mounts`. Declaring any mount removes every default
  mount for the module. If one becomes necessary, re-declare all seven defaults
  and use `files` (not the deprecated `includeFiles`, `excludeFiles` or `lang`).
  Glob semantics changed in v0.166.0: `**/x` no longer matches a bare `x`.
- Config from a module merges into a site only for `params` (deep), `menus`,
  `mediaTypes` and `outputFormats` (shallow). `outputs`, `imaging`, `markup`,
  `sitemap`, `taxonomies` and root keys do NOT merge. Never assume a setting in
  this repo's `hugo.toml` reaches a site. Document what a consumer must carry.
- Params the base contributes are namespaced under `params.base`.
- Keep `module.hugoVersion.min` equal to the lowest version CI has tested.
  Never set `hugoVersion.extended` (deprecated).
- Renaming or removing a partial, shortcode, token or i18n key is a breaking
  change. List it in `CHANGELOG.md`.

## Version management

The Hugo version lives in `netlify.toml`, `mise.toml` and any workflow that
pins one. They must always agree, Renovate bumps them together, and
`tools/ci/check-versions.sh` fails on drift. The same applies to Go.

Never run `go mod tidy` here or in a consumer: there is no Go code, so it would
drop module requirements. Use `hugo mod tidy`.

Keep `renovate/hugo.json` copyable into any site unchanged. Nothing in it may
be specific to this repo.

## CI gate

CI builds `exampleSite` with `--gc --minify --panicOnWarning`, fails on
deprecation notices, lints prose for dashes, checks version drift, verifies the
managed files in `exampleSite` are current, then runs axe and Lighthouse
against the built output. This is what makes automated Hugo bumps safe.

- A change not exercised by `exampleSite` is not tested. Every layout, partial,
  shortcode and render hook must be rendered by at least one page there.
- The gate must be proven to fail. `tools/quality/fixtures/violation.html` is
  deliberately broken and the gate asserts axe fails on it. Never fix it.
- Lighthouse thresholds are in `tools/quality/lighthouserc.json`. Accessibility
  stays at 1. Raise a threshold when the code improves, never lower one to get
  a pull request green.
- Scripts in `tools/` must stay bash 3.2 compatible (macOS) or use python3 from
  the standard library, and must not assume they run inside this repo: in a
  consumer they run from the read-only Go module cache.

## Common commands

```sh
mise install                                   # install the pinned toolchain
hugo server --source exampleSite               # local dev against the base
hugo mod graph --source exampleSite            # confirm the module resolves

# The checks CI runs:
bash tools/ci/check-versions.sh                # Hugo and Go pins agree
bash tools/ci/lint-dashes.sh                   # no en or em dashes
bash tools/ci/build.sh exampleSite             # strict build, fails on deprecations
python3 tools/sync.py --base . --site exampleSite --check
bash tools/quality/run.sh exampleSite/public   # axe, Lighthouse, gate self test

python3 tools/sync.py --base . --site exampleSite   # refresh managed files
```

## Working agreements

- Read the current Hugo docs at gohugo.io before implementing anything Hugo
  specific. Do not rely on training data for template names, config keys or
  function signatures.
- Keep changes scoped to one issue. Update `exampleSite`, `CHANGELOG.md` and
  the affected rule file in the same change.
- When the Hugo docs are ambiguous, stop and ask rather than guessing.
- Run the gate locally before declaring work done.
