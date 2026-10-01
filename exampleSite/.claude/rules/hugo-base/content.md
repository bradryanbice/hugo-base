---
description: Content and front matter conventions for hugo-base sites
paths: "content/**,archetypes/**"
---

# Content

This file is managed by hugo-base. Do not edit it inside a site.

## Front matter

- `title` and `description` on every page. The description feeds the meta
  description and social cards, so write it for a reader, not for a crawler.
- `date` on anything dated. Hugo renders it with the site's format.
- `draft: true` while a page is unfinished. Drafts are excluded from builds, so
  CI does not check them.
- Set `sitemap.disable` and the `noindex` flag together when a page should stay
  out of search results.
- Start new pages with `hugo new content <section>/<name>.md` so the archetype
  supplies this shape.

## Images

- Put images in a page bundle next to the page (`index.md` plus the image), so
  Hugo can process them and the base can produce responsive sizes.
- Every image needs alt text. Write what a reader would miss if the image did
  not load. If the image is purely decorative, pass an empty alt deliberately.
- Do not hand write `<img>` tags in content. Use a Markdown image or the
  `figure` shortcode, both of which go through the base's image pipeline and
  set width and height to avoid layout shift.

## Shortcodes

The base ships `figure`, `callout` and `table`. Prefer them over raw HTML:
they carry the accessible structure (captions, a text label on each callout
type, a focusable scroll region for wide tables).

## Prose

Page content is the site author's voice, so the project wide ban on em and en
dashes does not apply to `content/`. Everything else about a page, including
front matter descriptions, follows the shared writing style.
