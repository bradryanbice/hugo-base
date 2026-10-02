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

## Shortcodes

| Shortcode | Parameters |
|---|---|
| `figure` | `src`, `alt` (required), `caption`, `title`, `link`, `attr`, `attrlink`, plus `sizes`, `loading`, `fetchpriority`, `class` |
| `callout` | `type` (`note`, `tip`, `warning`, `danger`), `title` to replace the label |
| `table` | `caption`, which also names the scroll region |

```markdown
{{< callout type="warning" >}}
Body text, rendered as **Markdown**.
{{< /callout >}}

{{< table caption="Spacing tokens" >}}
| Token | Value |
|---|---|
| `--space-1` | 0.5rem |
{{< /table >}}
```

`figure` accepts the parameters of Hugo's embedded figure, so content written
before adopting hugo-base keeps working. One difference: images must be page
resources or under `assets/`, because the pipeline cannot process a path in
`static/`.

Every Markdown table, with or without the shortcode, is wrapped in a focusable
region with an accessible name, so a table too wide for the screen can still be
scrolled by keyboard.

A callout always states its type as text, so the meaning never depends on color.

## Images

A Markdown image goes through the pipeline:

```markdown
![What the image shows](photo.jpg)
![What the image shows](photo.jpg "A caption, which may contain Markdown.")
```

It generates WebP alternatives and several widths, never upscales, and always
sets width and height so the page does not shift while loading. A title becomes
a `figcaption`. Call `partial "image.html"` directly for finer control
(`loading`, `fetchpriority`, `class`).

Omitting alt text **fails the build**, naming the image and the page.
`alt=""` is how you mark an image decorative, deliberately.

Tune with `params.base.images`: `widths`, `sizes`, and `formats` (WebP only by
default; add `"avif"` to opt in, at a build time cost on every width).

Keep the image cache between deploys. `netlify.toml` sets `HUGO_CACHEDIR` to a
path Netlify persists, which matters once a site has many images.

## Config contract

Most Hugo configuration categories do not merge from a module into a site, so
the base cannot simply set them. Tested on Hugo 0.166.0:

- A **project level** `_merge = "deep"`, either at the root or on a category,
  does pull that category's values from an imported module.
- `_merge` declared **inside the module** has no effect. Only the project's own
  config counts, which is why each site carries the opt in.

What that means in practice:

| Category | Reaches a site | A site should |
|---|---|---|
| `params`, `menus`, `mediaTypes`, `outputFormats` | automatically | nothing |
| `markup`, `imaging`, `services` | only with an opt in | add `_merge = "deep"` to inherit the base's defaults |
| `outputs`, `sitemap`, `taxonomies`, `pagination` | only with an opt in | set its own: the base contributes nothing here, because Hugo's defaults already match |
| root keys (`baseURL`, `title`, `locale`, `enableRobotsTXT`, `disableHugoGeneratorInject`) | never | always set them itself |

So a consuming site's config needs these three files, each one line:

```toml
# config/_default/markup.toml
_merge = "deep"
# config/_default/imaging.toml
_merge = "deep"
# config/_default/services.toml
_merge = "deep"
```

The opt in is enumerated per category rather than a single root `_merge`, so a
later base release cannot start contributing to a category (`security`,
`build`, `privacy`) without that showing up as a deliberate change.

What the base contributes, and why each default is worth changing:

- **markup**: class based syntax highlighting (Chroma's inline hex ignores the
  tokens and fails contrast), GitHub style heading anchors, a table of contents
  from h2 to h3, raw HTML left escaped, and typographer dash substitutions
  mapped to themselves so `--` and `---` stay as the author typed them.
- **imaging**: CatmullRom resampling (sharper downscaling than Hugo's default
  box) and per format quality.
- **services**: a feed limit of 50, where Hugo's default is unlimited.

## Feeds, sitemap and robots

- RSS and the sitemap use Hugo's embedded templates. The feed carries full page
  content and is limited to 50 items.
- A page with `noindex: true` in front matter should also set
  `sitemap.disable: true`. The gate fails when it does not.
- `layouts/robots.txt` allows everything on a production build and disallows
  everything otherwise, so Netlify deploy previews cannot be indexed. It needs
  `enableRobotsTXT = true` in the site config, because root keys cannot come
  from a module.

## Quality gate

```sh
bash tools/quality/run.sh exampleSite/public
```

This checks the head contract on every page (one title, one canonical, a
description, one `h1`, parseable JSON-LD), serves the built site, runs axe over
every URL in its sitemap (WCAG 2.0,
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
