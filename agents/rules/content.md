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
- Do not hand write `<img>` tags in content. A Markdown image goes through the
  base's pipeline, which generates WebP alternatives and several widths, never
  upscales, and sets width and height so the page does not shift as images load.
- Alt text is the Markdown link text: `![What the image shows](photo.jpg)`.
  Leaving it empty says the image is decorative, which is a decision you make
  rather than a field you forget. Omitting alt entirely, when calling the image
  partial directly, fails the build.
- A Markdown title becomes a real caption: `![Alt](photo.jpg "The caption")`
  renders a `figure` with a `figcaption`, and the caption may contain Markdown.
- SVG and GIF pass through untouched. A remote image is not processed, because
  that would make the build depend on someone else's server.
- `params.base.images` sets `widths`, `sizes` and `formats`. WebP only by
  default; add `"avif"` to `formats` to opt in, at the cost of build time on
  every width.

## What is not supported

Task lists (`- [x] done`) are off. Hugo renders them as a checkbox with no
accessible name, which fails WCAG, and neither CSS nor a render hook can add
one. Write the state in words instead, or use a definition list.

## Shortcodes

The base ships `figure`, `callout` and `table`. Prefer them over raw HTML:
they carry the accessible structure (captions, a text label on each callout
type, a focusable scroll region for wide tables).

## Prose

Page content is the site author's voice, so the project wide ban on em and en
dashes does not apply to `content/`. Everything else about a page, including
front matter descriptions, follows the shared writing style.
