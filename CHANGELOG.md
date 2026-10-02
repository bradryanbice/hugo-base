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
- Typography: element styles for headings, prose, links, lists, quotes, code, tables and inline semantics, driven by the type scale and the theme's font inputs, plus a `.prose` wrapper that sets the reading measure and vertical rhythm.
- Syntax highlighting themed from semantic tokens, so it works in both color schemes and meets contrast. Sites need `[markup.highlight] noClasses = false`.
- Config contract established by experiment on Hugo 0.166.0: a project level `_merge = "deep"` does pull `markup`, `imaging` and `services` values from an imported module, while `_merge` declared inside the module has no effect. The base now contributes defaults for those three categories and documents what every site must still set itself.
- Markup defaults: class based syntax highlighting, GitHub style heading anchors, a table of contents from h2 to h3, raw HTML left escaped, and typographer dash substitutions mapped to themselves so `--` and `---` survive as typed.
- Imaging defaults: CatmullRom resampling and per format quality. Feed limit of 50.
- `layouts/robots.txt`: allows everything on a production build, disallows everything otherwise, so deploy previews cannot be indexed.
- Document head built from replaceable partials: core meta with a description fallback chain, canonical and translation alternates, Open Graph and X cards via Hugo's embedded templates, feed discovery driven by the page's own output formats, an icons seam, and JSON-LD.
- JSON-LD structured data: `WebSite` on the home page, `Article` or `WebPage` on single pages, `CollectionPage` on lists, and a `BreadcrumbList` from the section ancestry. Publisher and author come from `params.base.schema`, with no invented defaults.
- Front matter `noindex` support, paired with `sitemap.disable`.
- `tools/quality/check-head.py` in the gate: one title, one canonical, a description, one `h1`, parseable JSON-LD, and no noindex page listed in the sitemap, on every built page.
- Lighthouse SEO and best practices thresholds raised to 1 now that descriptions and an icon are in place.
- Content layouts: `single.html`, `list.html` (home, section, taxonomy and term) and `404.html`, with `page/meta.html`, `page/card.html`, `page/terms.html` and a `page/search.html` seam. No `home.html`: the home kind falls back to `list.html`, so a site adds its own only if it wants something different.
- Accessible pagination: a labelled landmark, `aria-current="page"` on the current page, a hidden "Page" prefix on each number, text on previous and next, a windowed page list, and a status line. The current page and unavailable directions are text rather than focusable controls.
- Card and pagination components, both adjustable through component level custom properties.
- Page shell: `baseof.html` with one banner, main and contentinfo landmark per page, a skip link that moves focus into `<main>`, a header with a brand link and a logo seam, a recursive nav that renders only menus the site defines, and a footer with an optional menu and copyright line.
- Five hook partials (`head-end`, `body-start`, `header-end`, `footer-start`, `body-end`) as the shell's extension API, plus `i18n/en.toml` for every user visible string.
- `layout/shell.css`: skip link, header, nav and footer, arranged with a container query and no JavaScript.
- CSS policy lint in `tools/lint/`: OKLCH only, tokens for spacing and color, no `!important`, no focus removal, logical properties, no stray `@import`, no primitive ramp steps outside the token files, and no site copy of a foundation file. Runs in CI and through `./hugo-base.sh lint`, with a broken fixture that proves every rule still fires.
- The quality gate now runs axe in both light and dark mode, and checks every semantic color pair in the token contract for contrast and for tokens that fail to resolve.
