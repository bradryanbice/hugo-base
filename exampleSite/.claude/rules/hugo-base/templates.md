---
description: Hugo template rules for hugo-base sites: the post v0.146 layout system, overrides and seams
paths: "layouts/**"
---

# Templates

This file is managed by hugo-base. Do not edit it inside a site.

## Hugo's current template system

Hugo overhauled templates in v0.146.0, so most examples online are wrong.

- There is no `layouts/_default/`. Templates live at the `layouts/` root:
  `baseof.html`, `home.html`, `single.html`, `list.html`, `404.html`.
- Partials live in `layouts/_partials/`, shortcodes in `layouts/_shortcodes/`,
  render hooks in `layouts/_markup/`. Any folder not starting with `_` is a
  page path.
- Call Hugo's embedded templates as partials:
  `{{ partial "opengraph.html" . }}`. The `_internal/` form is gone.
- `{{ return }}` is only valid inside a partial (an error since v0.166.0).
- Lookup ranks a page kind template (`home`, `section`, `taxonomy`, `term`,
  `page`) above the standard layouts (`list`, `single`, `all`). A site adding
  `layouts/section.html` therefore overrides the base's `list.html` for
  sections.

Other version facts worth remembering:

- Language config keys changed in v0.158.0: `languageCode` is now `locale`,
  `languageDirection` is `direction`, `languageName` is `label`. In templates
  use `.Language.Locale`, `.Language.Direction`, `.Language.Label`.
- Imaging config is per format (`imaging.webp.quality`, `imaging.jpeg.quality`,
  `imaging.avif.*`). The top level `imaging.quality` is deprecated.
- Verify anything else against the current docs at gohugo.io. Do not trust
  memory for template names, config keys or function signatures.

## What the base ships

| Template | Covers |
|---|---|
| `baseof.html` | the shell: landmarks, skip link, header, footer, hooks |
| `single.html` | any single page |
| `list.html` | every list kind: home, section, taxonomy, term |
| `404.html` | not found, with a search seam |

There is no `home.html`. Hugo falls back from the home kind to `list.html`, so
a site that wants a different home page adds its own `home.html`, and one that
wants a different section listing adds `section.html`. Same for `taxonomy.html`
and `term.html`.

Overridable pieces: `pagination.html`, `page/meta.html`, `page/card.html`
(takes a `headingLevel`, so a card fits the outline rather than hard coding
`h2`), `page/terms.html` and `page/search.html`.

`params.base.dateFormat` sets the date format, defaulting to `:date_long`.
Format dates with the `time.Format` function, not the `.Format` method: only
`time.Format` understands Hugo's layout tokens and localises the result.

## Overriding base templates

- Put site specific types at their own paths, for example
  `layouts/players/single.html`. Do not copy a shared template to make a small
  change.
- Extend the page shell through the empty hook partials in
  `layouts/_partials/hooks/`. These names are part of the base's public API:

  | Hook | Where it renders |
  |---|---|
  | `head-end.html` | end of `<head>` |
  | `body-start.html` | start of `<body>`, before the skip link. Keep it free of focusable elements, or they land ahead of the skip link |
  | `header-end.html` | end of the header, after the navigation |
  | `footer-start.html` | start of the footer |
  | `body-end.html` | end of `<body>`, for deferred scripts |

- The other seams in the shell: `site/logo.html` (renders inside the brand
  link, so give the image an empty alt), `head/css-site.html` for a site
  stylesheet, and any single `site/*` or `head/*` partial.
- Navigation is content, so it lives in the site's menu config. The base
  renders `main` and `footer` menus and renders nothing when they are absent.
  Define menu entries with `pageRef`, and use an entry without a URL only as a
  grouping label: the base renders those as text, never as an empty link.
- The current page's menu entry gets `aria-current="page"` and the entry for
  the section containing it gets `aria-current="true"`. Both are also marked
  visually, never by color alone.
- Every user visible string comes from `i18n/`, so a site can reword without
  touching a template.
- Replacing a single sub partial (for example `head/social.html`) is supported.
  Copying `head.html` to change one line is not.

## The document head

`head.html` composes small partials, each replaceable on its own: `head/meta.html`,
`head/canonical.html`, `head/social.html`, `head/feeds.html`, `head/icons.html`,
`head/schema.html`, `head/css.html`, `head/css-site.html`. Never copy
`head.html` to change one of them.

Every page must end up with exactly one title, one canonical link, a meta
description and one `h1`, and any JSON-LD must parse. The gate checks all of
that on every built page, so a template that drops a description fails CI.

What a site configures:

```toml
disableHugoGeneratorInject = true   # so <meta charset> stays first

[params]
  description = "..."               # fallback description
  [params.social]
    twitter = "handle"              # used by the X card tags
  [params.base]
    titleSeparator = "|"
    themeColor = "..."
  [params.base.schema]
    type = "Organization"           # or Person
    name = "..."                    # publisher
    logo = "/icon.svg"
    author = "..."                  # default author
```

The base ships no defaults for publisher or author: an invented organization
name would be worse than an absent field.

- Front matter `noindex: true` emits `noindex, follow`. Pair it with
  `sitemap.disable`, which the gate enforces.
- Ship at least one icon by overriding `head/icons.html`. Without one the
  browser requests `/favicon.ico`, logs a 404 and costs a Lighthouse point.
- Social tags come from Hugo's embedded templates, which read `params.social`
  and the page's `images`, `audio` and `videos` front matter.
- Inside a `<script>` element, JSON needs `jsonify | safeJS`. Without `safeJS`
  Go's template escaping emits it as a quoted string, which parses as a string
  rather than an object, and nothing visibly breaks.

## Migrating an older site

Hugo still honours the pre v0.146 paths, and it does so silently. A site that
keeps `layouts/_default/single.html` or `layouts/partials/` will have those win
over the base, with no warning, so the site looks like it adopted hugo-base
while still rendering its own templates. Before adopting, delete whatever the
base now provides and move anything genuinely site specific to the current
paths.

## Build discipline

- The build runs with `--panicOnWarning`, so a `warnf` fails CI. Fix the cause.
- Any template a site adds should be exercised by a page, or it is untested: an
  unrendered template is one a Hugo upgrade can break without anyone noticing.
  A site can enforce that by passing `template-coverage: true` to the shared
  workflow, but it is off by default, because a site legitimately does not use
  every template the base ships.
