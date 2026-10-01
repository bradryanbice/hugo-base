---
description: How hugo-base sites are built: shared ownership, overrides, and the writing rules
---

# Working on a hugo-base site

This file is managed by hugo-base. Do not edit it inside a site. Change it in
the hugo-base repo and run `./hugo-base.sh sync` after the next version bump.

## What comes from hugo-base

Layouts, partials, shortcodes, the CSS foundation, design tokens, archetypes,
the CI gate, the Renovate preset and these rules all come from the
`github.com/bradryanbice/hugo-base` module, pinned in the site's `go.mod`.

The site owns its content, its brand, its navigation, its configuration and
anything that is only true for that site.

## Upstream first

If a change would be true for every site, it belongs in hugo-base, not in one
site. Open an issue there instead of patching locally. A local fix that should
have been upstream is the main way this setup decays.

## How to override

Hugo's unified file system lets a site replace any file from the module by
placing its own file at the same path. Use this sparingly:

- Theme the site by writing `assets/css/tokens/theme.css`. That is the
  supported way to change appearance.
- Add site specific layouts at their own paths (for example
  `layouts/players/single.html`), rather than editing shared ones.
- Extend the page shell through the hook partials in `layouts/_partials/hooks/`.
- Never shadow a foundation file. The CI gate fails when a site does.

## Progressive enhancement

Every page must work with JavaScript disabled: navigation, content, images and
forms. JavaScript may only improve a page that already works.

## Writing style

No em dashes and no en dashes in anything written for the project: docs,
comments, commit messages, pull request text, issue text. Use commas, periods,
or parentheses. Page content is the site author's own voice, so this rule does
not police `content/`.

## Before you finish

Run the checks the CI gate runs. `maintenance.md` lists them.
