Head, SEO, and structured data partials

## Summary

Build the `<head>` from small overridable partials: core meta, canonical, social cards, feed discovery, favicon slot, and JSON-LD structured data.

## Detailed scope

- `layouts/_partials/head.html` composing:
  - `head/meta.html`: charset, viewport, title pattern (page title, then site title), description (page description, then summary, then site description), `robots` meta honoring a front matter `noindex` flag, `theme-color` from a semantic token value param.
  - `head/canonical.html`: canonical link, alternate language links when multilingual.
  - `head/social.html`: calls embedded `opengraph.html` and `twitter_cards.html` as partials.
  - `head/feeds.html`: `<link rel="alternate">` for the RSS output of the current page, when present.
  - `head/icons.html`: empty seam for favicon and manifest (brand assets belong to sites).
  - `head/css.html` (from issue 06).
  - `head/schema.html`: JSON-LD for `WebSite` on home, `WebPage` or `Article` on single pages, `BreadcrumbList` from section ancestry. Publisher and author from `params.base.schema` with no defaults.
  - `hooks/head-end.html` (from issue 09).
- Param contract documented under `params.base.seo` and `params.base.schema`.

## Design or architecture considerations

- Embedded Hugo partials for Open Graph and Twitter cards save code and track platform changes. Sites can still override them by placing `layouts/_partials/opengraph.html`. The embedded `schema.html` emits microdata meta tags, not JSON-LD, so we write our own JSON-LD.
- JSON-LD must be built with `dict` and `jsonify`, never string concatenation, to avoid escaping bugs.
- Nothing site specific: no organization name, logo, or social handles in the base.

- Hugo injects `<meta name="generator">` as the first element in `<head>`, ahead of `<meta charset>` (seen in the issue 01 build). It is harmless while charset stays within the first 1024 bytes. Decide whether to set `disableHugoGeneratorInject = true` in the recommended config and emit `hugo.Generator` after charset instead.

## Task checklist

- [ ] `head.html` and the sub partials
- [ ] JSON-LD with `jsonify`
- [ ] `noindex` front matter support
- [ ] Param contract documented
- [ ] exampleSite pages covering home, section, single with and without images

## Acceptance criteria

- Every page has exactly one `<title>`, one canonical, and a description.
- JSON-LD validates (schema.org validator or a CI JSON parse check at minimum).
- Lighthouse SEO category passes the threshold from issue 04.
- A site can replace any sub partial without copying `head.html`.

## Open questions

- The embedded `opengraph.html` reads images from specific front matter and params conventions. Do those conventions match what our sites already use, or should we write our own to control image selection (for example, processing the image through the pipeline from issue 13 for a correctly sized OG image)?
- The political statistics site may want `Dataset` schema. That is content-type specific and belongs in that site, but should the base expose a `schema/extra.html` seam so it can append nodes?
