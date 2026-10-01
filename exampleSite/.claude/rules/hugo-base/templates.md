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

## Overriding base templates

- Put site specific types at their own paths, for example
  `layouts/players/single.html`. Do not copy a shared template to make a small
  change.
- Extend the page shell through the empty hook partials in
  `layouts/_partials/hooks/` (head end, body start, body end, header end,
  footer start). Analytics and third party snippets go there.
- Every user visible string comes from `i18n/`, so a site can reword without
  touching a template.
- Replacing a single sub partial (for example `head/social.html`) is supported.
  Copying `head.html` to change one line is not.

## Build discipline

- The build runs with `--panicOnWarning`, so a `warnf` fails CI. Fix the cause.
- Any template a site adds must be exercised by a page, or it is untested.
