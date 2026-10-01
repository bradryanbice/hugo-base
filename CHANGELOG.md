# Changelog

All notable changes to hugo-base are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[semantic versioning](https://semver.org/). While the version is 0.x, a minor
release may contain breaking changes, listed under a Breaking heading.

## Unreleased

### Added

- Module scaffold: `go.mod`, module config with `hugoVersion.min = "0.166.0"`, and placeholder `baseof`, `home`, `single` and `list` templates.
- `exampleSite` test harness importing the module from the local checkout.
- Hugo version pinned in `mise.toml` and `netlify.toml`.
- MIT license.
- Reusable CI gate `.github/workflows/site-ci.yml` for hugo-base and consuming sites: toolchain from `mise.toml`, Hugo and Go version drift check, optional dash lint, strict build that fails on warnings and deprecations, built site uploaded as an artifact.
- `tools/ci/` scripts behind the gate, runnable locally.
- Shared Renovate preset `renovate/hugo.json`: one grouped PR per Hugo release and per Go release across `mise.toml`, `netlify.toml` and workflows, and hugo-base module plus CI workflow bumps grouped together. Validated in CI.
- Node pinned in `mise.toml` for CI tooling.
- Accessibility and Lighthouse gate in `tools/quality/`: axe over every sitemap URL, Lighthouse CI assertions (accessibility must score 1, byte budgets are hard limits, performance is a warning), reports uploaded as an artifact, and a self test that proves axe still fails on a broken page.
- Pull request template with a manual accessibility checklist.
- Shared rules in `agents/rules/` (principles, accessibility, CSS, templates, content, maintenance), scoped by path where they apply to one part of a site, plus a placeholder `hugo-base-upgrade` skill.
- `tools/sync.py` and `tools/managed-files.toml`: copy the rules, skills, CI caller workflow, PR template, editorconfig and `hugo-base.sh` stub into a consuming site, pinned to the hugo-base version that site requires. `--check` fails on stale, missing or orphaned files and runs in CI.
- `tools/templates/hugo-base.sh`, the per site front end that locates the pinned module and runs its sync, lint and quality tooling.
- hugo-base loads the same rules it ships, through `.claude/rules/shared`.
- CSS foundation: cascade layer order, the 8pt spacing scale with one 4px half step, a fluid type scale, OKLCH color ramps derived from theme inputs, semantic color tokens with light and dark mode, reset, global defaults, accessibility primitives (focus ring, visually hidden, forced colors, increased contrast, 24px target size), reduced motion handling, print styles, and intrinsic layout primitives (stack, cluster, center, sidebar, switcher, grid-auto, container).
- `assets/css/tokens/theme.css`, the single file a site overrides to theme itself. Every input is read with a default fallback, so a partial override cannot invalidate a token, and the file is loaded last so a site can override one computed ramp step.
- `head/css.html` bundles the stylesheet with `css.Build` and fingerprints it with an integrity hash in production. `head/css-site.html` is an empty seam for a site's own stylesheet.
- The quality gate now runs axe in both light and dark mode, and checks every semantic color pair in the token contract for contrast and for tokens that fail to resolve.
