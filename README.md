# hugo-base

A shared Hugo Module holding the layouts, CSS foundation, partials, tooling and
conventions behind several sites. A site imports it, supplies a brand and its
content, and gets accessible markup, a design token system, responsive images,
SEO and a CI gate that checks all of it.

Status: working toward v0.1.0. Usable from a tag once that is released.

## What belongs here, and what does not

The test is simple: **would this be true for every site?** If it would only be
true for one, it belongs in that site.

In the base: design tokens and the CSS foundation, base layouts, the head and
structured data, the page shell, pagination, the image pipeline, the shared
shortcodes, archetypes, the shared rules, the CI gate, and the Renovate preset.

Never in the base: domain names, brand colors, navigation content, analytics
IDs, data schemas, and layouts for one site's content types.

## Quick start

For a site that already exists, follow
[`migrations/v0.1.0.md`](migrations/v0.1.0.md) instead: it covers the parts that
fail quietly, like old layout paths that shadow the base.

For a new site, start from
[hugo-starter](https://github.com/bradryanbice/hugo-starter): use that
template, change four values and set a hue. The rest of this section is what
the template already does, for anyone assembling a site by hand.

```sh
hugo mod init github.com/<owner>/<repo>
hugo mod get github.com/bradryanbice/hugo-base@v0.1.0
```

```toml
# config/_default/module.toml
[[imports]]
  path = "github.com/bradryanbice/hugo-base"
```

```toml
# config/_default/markup.toml, imaging.toml, services.toml
# One line each, so the site inherits the base's defaults for these.
_merge = "deep"
```

```toml
# config/_default/hugo.toml
baseURL = "https://example.com/"
title = "Example"
locale = "en-US"
enableRobotsTXT = true
disableHugoGeneratorInject = true
```

Then take the shared CI workflow, rules and tooling:

```sh
# First time, from the module (the stub is itself one of these files):
hugo config mounts | grep -B2 hugo-base | grep '"dir"'
python3 <module dir>/tools/sync.py --base <module dir> --site .

# From then on:
./hugo-base.sh sync
```

And point Renovate at the shared preset:

```json
{
  "extends": ["config:recommended", "github>bradryanbice/hugo-base//renovate/hugo"]
}
```

Ship real icons when you have them, by overriding `head/icons.html`. Until
then the base emits an empty icon link, so the browser does not request a
favicon that does not exist.

Never run `go mod tidy` in a Hugo site. There is no Go code, so it would drop
the hugo-base requirement. Use `hugo mod tidy`.

## Theming

One file, holding inputs only:

```css
/* assets/css/tokens/theme.css */
:root {
  --accent-hue: 25;        /* OKLCH hue, 0 to 360 */
  --accent-chroma: 0.15;   /* 0 is grey, 0.12 to 0.2 is saturated */
  --neutral-chroma: 0.006; /* tints greys toward the brand */
  --font-heading: "Your Font", system-ui, sans-serif;
  --radius-scale: 1;       /* 0 square, 1 default, 2 softer */
}
```

Ramps, hover and active states, dark mode and elevation are all derived from
those. Every input is read with its default as a fallback, so setting one value
cannot break another, and the file is loaded last in the tokens layer so a site
can also override a single computed step (`--accent-700`) when a hue clips.

The inputs: `--accent-hue`, `--accent-chroma`, `--neutral-hue`,
`--neutral-chroma`, `--status-chroma`, `--info-hue`, `--success-hue`,
`--warning-hue`, `--danger-hue`, `--font-body`, `--font-heading`, `--font-mono`,
`--radius-scale`, `--shadow-strength`. The base's own
`assets/css/tokens/theme.css` documents each with its default.

**Contrast becomes the site's responsibility** once it sets a brand color. The
gate checks every semantic pair in both light and dark mode against the built
site, so a brand that fails contrast fails CI rather than shipping.

## The public API

These names are stable. Anything not listed is internal and may change in a
minor release while the version is `0.x`.

**Layouts.** Hugo prefers a page kind template over a standard one, so a site
adds `home.html`, `section.html`, `taxonomy.html` or `term.html` to replace the
base's `list.html` for that kind, and `layouts/<section>/single.html` for a
content type. The base ships `baseof.html`, `single.html`, `list.html` and
`404.html`.

**Hooks**, which render nothing by default:

| Hook | Where |
|---|---|
| `_partials/hooks/head-end.html` | end of `<head>` |
| `_partials/hooks/body-start.html` | start of `<body>`, before the skip link |
| `_partials/hooks/header-end.html` | after the navigation |
| `_partials/hooks/footer-start.html` | start of the footer |
| `_partials/hooks/body-end.html` | end of `<body>`, for deferred scripts |

**Seams**, meant to be replaced:

| Partial | Purpose |
|---|---|
| `_partials/site/logo.html` | a mark inside the brand link |
| `_partials/head/icons.html` | favicons and manifest (ships an empty icon link, so a site with no icons yet does not 404) |
| `_partials/head/css-site.html` | a site's own stylesheet |
| `_partials/page/search.html` | a search form on the 404 page |

**Replaceable pieces**: `head/meta.html`, `head/canonical.html`,
`head/social.html`, `head/feeds.html`, `head/schema.html`, `site/header.html`,
`site/footer.html`, `site/nav.html`, `site/menu-items.html`,
`site/skip-link.html`, `pagination.html`, `page/meta.html`, `page/card.html`,
`page/terms.html`, `image.html`.

Replace one of those rather than copying `head.html` or `baseof.html`. If you
need to copy a composing file to change one line, the piece you need is
missing, and that is an issue here.

**Shortcodes**: `figure`, `callout`, `table`. **Render hooks**: images and
tables. **i18n keys**: every user visible string, in `i18n/en.toml`.

Foundation CSS is **not** replaceable: `main.css`, `tokens/scale.css`,
`tokens/color.css`, `tokens/semantic.css`, `foundation/**` and
`layout/primitives.css` must not be copied into a site, and the lint fails if
they are. Theme through `tokens/theme.css` and through component level custom
properties (`--card-radius`, `--callout-padding`).

## Params

Everything the base reads lives under `params.base`, so it cannot collide with
a site's own params.

| Param | Default | Purpose |
|---|---|---|
| `base.titleSeparator` | a pipe | between page title and site title |
| `base.themeColor` | unset | `theme-color` meta |
| `base.dateFormat` | `:date_long` | date display, via `time.Format` |
| `base.images.widths` | 320 to 1600 | widths to generate |
| `base.images.sizes` | `100vw` | the `sizes` attribute |
| `base.images.formats` | `["webp"]` | add `"avif"` to opt in |
| `base.schema.type` | unset | `Organization` or `Person` |
| `base.schema.name` | unset | publisher name |
| `base.schema.logo` | unset | publisher logo |
| `base.schema.author` | unset | default author |

Hugo's own social tags read `params.description`, `params.images` and
`params.social.twitter`.

## Config contract

Most Hugo configuration categories do not merge from a module into a site.
Tested on Hugo 0.166.0: a **project level** `_merge = "deep"` does pull a
category from an imported module, and `_merge` inside the module has no effect.

| Category | Reaches a site | A site should |
|---|---|---|
| `params`, `menus`, `mediaTypes`, `outputFormats` | automatically | nothing |
| `markup`, `imaging`, `services` | with an opt in | add `_merge = "deep"` |
| `outputs`, `sitemap`, `taxonomies`, `pagination` | with an opt in | set its own; the base contributes nothing |
| root keys (`baseURL`, `title`, `locale`, `copyright`, `enableRobotsTXT`, `disableHugoGeneratorInject`) | never | always set them |

What the base contributes, each because Hugo's default is wrong for us:

- **markup**: class based syntax highlighting (Chroma's inline hex ignores the
  tokens and fails contrast), GitHub style heading anchors, a table of contents
  from h2 to h3, raw HTML left escaped, and typographer dash substitutions
  mapped to themselves so `--` and `---` stay as typed. Task lists are off:
  Hugo renders them as a checkbox with no accessible name.
- **imaging**: CatmullRom resampling and per format quality.
- **services**: a feed limit of 50, where Hugo's default is unlimited.

## Content

```markdown
![What the image shows](photo.jpg)
![What the image shows](photo.jpg "A caption, which may contain Markdown.")

{{< callout type="warning" >}}
Body text, rendered as **Markdown**.
{{< /callout >}}

{{< figure src="photo.jpg" alt="What it shows" caption="A caption" >}}
```

- **Images** live in the page bundle or `assets/`, never `static/`: the pipeline
  cannot process a `static/` path, and the build says so. They get WebP
  alternatives, several widths, and width and height so pages do not shift.
- **Alt text is required.** The build fails and names the page. `alt=""` marks
  an image decorative, deliberately.
- **Every table** is wrapped in a focusable, named scroll region, so a table too
  wide for the screen can still be read by keyboard.
- **A callout always states its type as text**, so meaning never rests on color.
- Pair `noindex: true` with `sitemap.disable: true`. The gate enforces it.
- `figure` accepts Hugo's embedded figure parameters, so older content works.

## Updating

```sh
hugo mod get -u github.com/bradryanbice/hugo-base
hugo mod tidy
./hugo-base.sh sync
```

Read [`CHANGELOG.md`](CHANGELOG.md) for the versions you cross. A release that
needs work in a site links a note in [`migrations/`](migrations/). Apply it with
the `hugo-base-upgrade` skill, which the sync puts in the site, or follow the
note by hand.

Renovate opens one grouped pull request per Hugo release covering `mise.toml`,
`netlify.toml` and any workflow, and a separate one for hugo-base itself
grouped with the CI workflow reference. CI on that pull request fails until the
managed files are synced, which is how a new convention arrives.

While the version is `0.x`, a minor release may break a consumer, and the
CHANGELOG says so under a Breaking heading.

## Working on the base itself

```sh
mise install
hugo server --source exampleSite
```

`exampleSite/` is the harness, and it is also the first consumer: it imports
the module from the local checkout, so changes appear immediately. Point a real
site at a local checkout the same way:

```toml
[module]
replacements = "github.com/bradryanbice/hugo-base -> ../hugo-base"
```

The checks, all runnable locally and all run by CI:

```sh
bash tools/ci/check-versions.sh                # toolchain pins agree
bash tools/ci/lint-dashes.sh                   # no en or em dashes
bash tools/ci/build.sh exampleSite             # strict build: fails on warnings,
                                               # deprecations and unused templates
bash tools/ci/check-harness.sh exampleSite/public
python3 tools/sync.py --base . --site exampleSite --check
bash tools/lint/run.sh --self-test . exampleSite   # CSS policy, protected paths
bash tools/quality/run.sh exampleSite/public       # head, axe, contrast, Lighthouse
```

The gate checks the head contract on every page, runs axe over every sitemap
URL in both color schemes, checks all 33 semantic color pairs for contrast and
for tokens that fail to resolve, runs Lighthouse on a chosen set of pages
including every page with an image, and then **proves itself** by requiring axe
to fail on a deliberately broken fixture.

Decisions behind all of this are in [`docs/decisions/`](docs/decisions/). The
conventions that travel to every site are in [`agents/rules/`](agents/rules/),
and this repo follows them through `.claude/rules/shared`.
