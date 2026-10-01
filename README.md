# hugo-base

A shared Hugo Module holding the layouts, CSS foundation, partials and
conventions used by every site in this family. Sites import it, override
individual files by placing their own copy at the same path, and update it
with a version bump.

Status: pre-release, working toward v0.1.0. Not ready for use yet.

## Requirements

- Hugo 0.166.0 or later (extended edition, pinned in `mise.toml`)
- Go 1.27 or later (Hugo Modules use it to fetch modules)
- [mise](https://mise.jdx.dev/) to install the pinned toolchain

## Developing

```sh
mise install
hugo server --source exampleSite
hugo build --source exampleSite --gc --minify --panicOnWarning
```

`exampleSite/` is the test harness. It imports this module from the local
checkout, so changes show up immediately.

## Shared rules and managed files

hugo-base is the single source of truth for how its sites are built, not just
for their code. `agents/rules/` holds the conventions (accessibility, CSS and
tokens, templates, content, maintenance). `tools/managed-files.toml` lists what
hugo-base owns inside a site:

| In the site | Comes from |
|---|---|
| `.claude/rules/hugo-base/*.md` | `agents/rules/` |
| `.claude/skills/*` | `agents/skills/` |
| `.github/workflows/ci.yml` | `tools/templates/site-ci.yml`, with the version this site pins |
| `.github/pull_request_template.md`, `.editorconfig`, `hugo-base.sh` | `tools/templates/` |

A site refreshes them with `./hugo-base.sh sync`, and CI fails when they are
stale. So a Renovate bump of hugo-base carries that version's updated rules
into the same pull request, where the diff shows exactly what changed. The
copies are pinned to the version in the site's `go.mod`, so the instructions a
site follows always describe the code it actually has.

A site's own guidance goes in `.claude/rules/site/*.md`, which the sync tool
never touches. `CLAUDE.md`, `.claude/settings.json`, config, `mise.toml` and
`netlify.toml` stay site owned.

## CSS policy lint

```sh
bash tools/lint/run.sh --self-test . exampleSite
```

Enforces the CSS rules rather than trusting them: OKLCH only, spacing and color
from tokens, no `!important`, no removed focus rings, logical properties, and no
site copy of a foundation file. The config lives in the module, so a rule added
here reaches a site in the same pull request that bumps hugo-base. `--self-test`
lints a deliberately broken fixture and requires every rule to fire.

## Quality gate

```sh
bash tools/quality/run.sh exampleSite/public
```

This serves the built site, runs axe over every URL in its sitemap (WCAG 2.0,
2.1 and 2.2 A and AA) in both light and dark mode, checks every semantic color
pair in the token contract for contrast, runs Lighthouse CI against the
assertions in `tools/quality/lighthouserc.json`, and then self tests by
requiring axe to fail on a deliberately broken page. Chrome comes from the machine, so no
browser is downloaded. Consuming sites get the same gate through the reusable
workflow, which is where a site's own brand colors get checked for contrast.

## Theming a site

A site declares only the inputs it wants in `assets/css/tokens/theme.css`:

```css
:root {
  --accent-hue: 25;
  --accent-chroma: 0.15;
  --neutral-chroma: 0.006;
  --radius-scale: 0;
}
```

Ramps, hover and active states, dark mode and elevation are all derived from
those. Inputs left out keep their defaults, so a theme file cannot break a
token by omission. The base's own `tokens/theme.css` documents every input, and
`exampleSite` ships a theme that overrides it.

Fonts are inputs too: `--font-body`, `--font-heading` and `--font-mono`.

Everything else in `assets/css/` is foundation: a site must not copy it, and CI
fails if it does.

One piece of config is required for syntax highlighting, because Hugo otherwise
writes hardcoded hex colors that ignore the tokens and fail contrast:

```toml
[markup.highlight]
  noClasses = false
```

## Renovate

`renovate/hugo.json` is a shared preset. It keeps the Hugo and Go versions in
`mise.toml`, `netlify.toml` and any workflow `HUGO_VERSION` or `GO_VERSION`
identical, and opens one grouped PR per release. It also groups a site's
hugo-base module bump with its reusable CI workflow ref.

A site uses it by adding this to its `renovate.json`:

```json
{
  "extends": ["config:recommended", "github>bradryanbice/hugo-base//renovate/hugo"]
}
```

Extending by reference (recommended) means fixes to the preset reach every
site immediately. Copying `renovate/hugo.json` into a site also works, because
it contains nothing specific to this repo, but copies drift.

Never enable Renovate's `gomodTidy` option in a hugo-base site. There is no Go
code, so `go mod tidy` would remove the hugo-base requirement.

Consumer documentation (importing, overriding, theming, updating) arrives
before v0.1.0.
