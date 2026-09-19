# CLAUDE.md

Guidance for working in `hugo-base`. Read this before changing anything.

## What this repo is

`hugo-base` is a Hugo Module (`github.com/bradryanbice/hugo-base`). It is theme-shaped, not a site. Consuming sites import it through `module.imports` and override any file by placing their own copy at the same path in their project. It is versioned with git tags and semver (`vMAJOR.MINOR.PATCH`). While the version is `0.x`, a MINOR bump may break consumers and must say so in `CHANGELOG.md`.

Consumers today: bradbice.com, royalrumblestats.com, playoffsbracket.com, headedapp.com, calaround.app, plus an upcoming political statistics site. The companion repo `hugo-starter` is a thin GitHub template for new sites. It is not this repo.

## The scope test

Before adding anything, ask: would this be true for every consuming site? If it would only be true for one site, it does not belong here.

In scope: design tokens (slots and neutral defaults), reset, typography, base layouts (`baseof`, `single`, `list`, `404`), head, SEO and schema partials, header, footer, nav shell, skip link, sitemap and feed output, image processing pipeline, the shared shortcodes (`figure`, `callout`, `table`), archetypes, the reusable CI workflow, the Renovate preset, and `exampleSite/`.

Out of scope, always: domain names, brand color values, navigation content, analytics IDs, any data schema, any content-type-specific layout, chart components (explicitly deferred).

## Non-negotiables

### Accessibility (WCAG 2.2 AA minimum)

- Every page has exactly one `<header>` banner, one `<nav>` per navigation region with an accessible name, one `<main id="main">`, and one `<footer>` contentinfo. Do not nest landmarks incorrectly.
- A skip link is the first focusable element and moves focus to `<main>`.
- Focus is always visible. Use `:focus-visible` with a focus ring that meets WCAG 2.2 focus appearance guidance (at least 2px, 3:1 contrast against adjacent colors). Never write `outline: none` without a replacement.
- No keyboard traps. Everything interactive is reachable and operable by keyboard in a logical order.
- Target size is at least 24 by 24 CSS pixels (WCAG 2.2 SC 2.5.8).
- Honor `prefers-reduced-motion: reduce`. Motion is opt-in inside `@media (prefers-reduced-motion: no-preference)`, not opt-out.
- Text contrast is at least 4.5:1 (3:1 for large text and UI components). Semantic token pairs are the unit of contrast checking.
- Images require an explicit `alt`. Decorative images use `alt=""` on purpose, never by omission. The image partial fails the build when `alt` is missing.
- Use `aria-current="page"` on the active nav link. Prefer native HTML semantics over ARIA.
- Headings are hierarchical with one `<h1>` per page.
- The CI gate (axe plus Lighthouse accessibility) must pass. Never lower a threshold to get a PR green.

### Color: OKLCH, layered tokens

- All color values are `oklch()`. No hex, rgb, or hsl literals in CSS except inside a comment explaining a conversion.
- Two token layers:
  1. Primitives: raw scales, for example `--neutral-0` through `--neutral-1000`, built from the theme's hue and chroma inputs.
  2. Semantic aliases that reference primitives only, for example `--color-text`, `--color-surface`, `--color-accent`, `--color-focus-ring`.
- Interaction states (hover, active, subtle) are derived with relative color syntax, `oklch(from var(--token) ...)`, never hand-written per theme.
- Components and layouts use semantic tokens only. They never reference primitives directly.
- The base ships theme inputs with neutral defaults. No brand color values live here. A consuming site themes itself by overriding `assets/css/tokens/theme.css` and nothing else.

### Foundation versus theme

- Foundation CSS (`main.css`, `tokens/scale.css`, `tokens/color.css`, `tokens/semantic.css`, `foundation/**`, `layout/primitives.css`) is owned by the base. Sites must not override these paths, and CI blocks it. Foundation files control how things are expressed (color format, scales, focus, motion, layout mechanics), never what brand they express.
- The theme slot (`tokens/theme.css`) and component-level custom properties are the supported ways for a site to change appearance. If a site needs something the slot cannot express, fix the base.

### Spacing: 8pt scale

- Spacing comes from tokens on an 8pt scale expressed in `rem` (1rem = 16px at default browser settings, so 8px = 0.5rem). Do not hard-code spacing lengths in component CSS.
- Use logical properties (`margin-block`, `padding-inline`) rather than physical ones.

### Writing style

- No em dashes and no en dashes in any prose: docs, comments, README, commit messages, issue text, i18n strings. Use commas, periods, or parentheses. CI lints for U+2013 and U+2014 and fails the build.

### CSS

- Modern CSS is encouraged: cascade layers, nesting, custom properties, container queries, `:has()`, logical properties.
- No CSS framework. No Sass. No PostCSS. No npm build step for site assets. The only pipeline is Hugo Pipes, using `css.Build` (Hugo v0.158.0 and later) to bundle `@import`, then `fingerprint` in production.
- Layer order is declared once in `assets/css/main.css`: `@layer reset, tokens, foundation, layout, components, utilities;`. Consuming site CSS is unlayered, so it wins over the base without specificity fights. Do not use `!important` in the base.

### Progressive enhancement

- Every page works with JavaScript disabled. Navigation, content, images, and forms all function without JS.
- The base ships no JavaScript in v0.1.0. If JS is added later, it enhances an already working HTML baseline and is loaded with `defer` or `type="module"`.

## Hugo conventions (target: Hugo v0.166.0)

Common examples online are often out of date. Follow these rules, not memory.

- Template layout uses the system introduced in v0.146.0:
  - No `layouts/_default/`. Templates live at the `layouts/` root: `baseof.html`, `home.html`, `single.html`, `list.html`, `404.html`.
  - Partials live in `layouts/_partials/`, shortcodes in `layouts/_shortcodes/`, render hooks in `layouts/_markup/`.
  - Embedded templates are called as partials, for example `{{ partial "opengraph.html" . }}`. The `_internal/` form is gone.
- `{{ return }}` is only valid inside a partial (hard error since v0.166.0).
- Do not define `module.mounts` in this repo. Defining any mount removes all default mounts for the module. If a mount becomes necessary, re-declare every default mount explicitly and use `files` (not the deprecated `includeFiles`, `excludeFiles`, or `lang`). Glob semantics changed in v0.166.0 (`**/x` no longer matches a bare `x`).
- Config from a module only merges into the site for `params` (deep), `menus`, `mediaTypes`, and `outputFormats` (shallow). `outputs`, `imaging`, `markup`, `sitemap`, `taxonomies`, and root keys do NOT merge by default. Do not assume a setting in this repo's `hugo.toml` reaches a consuming site. Document any config a consumer must copy or opt into with `_merge`.
- Site params contributed by the base are namespaced under `params.base` to avoid collisions.
- Imaging config uses per-format keys (`imaging.webp.quality`, `imaging.jpeg.quality`, `imaging.avif.*`). Top-level `imaging.quality`, `hint`, and `compression` are deprecated since v0.163.0.
- Use the `hugo build` command in scripts and docs.
- Language config keys were renamed in v0.158.0: `languageCode` is now `locale`, `languageDirection` is `direction`, `languageName` is `label`. In templates use `.Language.Locale`, `.Language.Direction`, `.Language.Label`.
- Keep `module.hugoVersion.min` equal to the lowest version CI has actually tested. Never set `hugoVersion.extended` (deprecated).
- Overridable seams are partials with stable names. Renaming or removing a partial, shortcode, token, or i18n key is a breaking change and must be listed in `CHANGELOG.md`.

## Shared rules for consuming sites

This repo is also the source of truth for how every site is built and maintained.

- Rules for sites live in `agents/rules/`. Skills live in `agents/skills/`. Files the base owns inside a site are listed in `tools/managed-files.toml`. `tools/sync.sh` copies them into a site at the site's pinned version, and CI fails when a site's copies are stale.
- This repo loads the same rules through the `.claude/rules/shared` symlink. When a rule there conflicts with this file, the rule wins, and this file must be corrected.
- A change to a convention ships as one PR containing: the rule edit, the CI enforcement for it (lint, check, or gate) where it can be automated, and a `migrations/vX.Y.Z.md` note telling sites how to comply. A rule with no enforcement and no migration is incomplete.
- Keep rules short and specific. They are context, not enforcement.

## Version management

The Hugo version lives in three places and they must always agree:

- `netlify.toml`: `[build.environment] HUGO_VERSION`
- `.github/workflows/*.yml`: the Hugo version used by CI
- `mise.toml`: the local toolchain

Rules:

- Never bump one without the others. Renovate opens a single grouped PR per Hugo release. Merge it only when CI is green.
- CI runs a drift check that fails if the three values differ.
- The Renovate preset in `renovate/` must stay copyable into consuming sites unchanged. Do not add paths or names specific to this repo.
- Do not run `go mod tidy` on this repo or on consumers. There is no Go code, so it would drop module requirements. Use `hugo mod tidy`.

## CI gate

CI builds `exampleSite` with `hugo build --gc --minify --panicOnWarning`, fails on deprecation notices, lints prose for dashes, checks version drift, then runs axe and Lighthouse CI against the built output. This gate is what makes automated Hugo bumps safe.

- A change that is not exercised by `exampleSite` is not tested. Every layout, partial, shortcode, and render hook must be rendered by at least one exampleSite page.
- The gate must be proven to fail. Keep the negative fixture that CI uses to confirm axe catches a known violation.

## Common commands

```sh
mise install                                   # install pinned Hugo and Go
hugo server --source exampleSite               # local dev against the base
hugo build --source exampleSite --gc --minify --panicOnWarning
hugo mod graph --source exampleSite            # confirm the module resolves
```

## Working agreements for Claude

- Read the current Hugo docs at gohugo.io before implementing anything Hugo-specific. Do not rely on training data for template names, config keys, or function signatures.
- Keep changes scoped to one issue. Update `exampleSite`, `CHANGELOG.md`, and the README override guide in the same change when behavior changes.
- When something is ambiguous in the Hugo docs, stop and raise it as a question rather than guessing.
- Run the build locally with `--panicOnWarning` before declaring work done.
