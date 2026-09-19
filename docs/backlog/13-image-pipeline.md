Image processing pipeline

## Summary

Provide one responsive image partial and a Markdown image render hook that together produce correctly sized, modern format, accessible images with no layout shift.

## Detailed scope

- `layouts/_partials/image.html` accepting a dict: `src` (page resource, global resource, or path), `alt` (required, may be empty string for decorative), `widths` (default from `params.base.images.widths`), `sizes`, `loading` (default `lazy`), `fetchpriority`, `class`.
  - Resolves the resource: page bundle first, then `assets/`, then fails.
  - Emits `<picture>` with a WebP `<source>` `srcset` and a fallback `<img>` in the original format, with `width` and `height` always set.
  - SVG and GIF pass through unprocessed.
  - `errorf` if `alt` is not provided at all (distinct from `alt: ""`).
- `layouts/_markup/render-image.html`: Markdown images go through the partial. Title becomes nothing (or a figure caption, per decision). Remote and `static/` images pass through with a warning.
- Imaging defaults documented in the recommended config fragment using per-format keys (`imaging.webp.quality`, `imaging.jpeg.quality`), not the deprecated top-level `quality`.
- Params contract: `params.base.images.widths`, `params.base.images.formats`.
- exampleSite page bundle with a large JPEG, a PNG with transparency, an SVG, and a decorative image.

## Design or architecture considerations

- Image processing is cached in `resources/_gen`. Netlify builds should keep the cache between builds (Hugo docs recommend setting `cacheDir`). Worth documenting for consumers because stats sites may have many images.
- A missing `alt` is a build error rather than a warning because accessibility is a hard requirement and an error is impossible to ignore.
- `width` and `height` attributes prevent CLS and are required by the Lighthouse budget.
- AVIF encoding became available in v0.162.0. It is slower to encode. Adding it multiplies build time by the number of widths.

## Task checklist

- [ ] Image partial
- [ ] Render hook for Markdown images
- [ ] Params contract and imaging config fragment
- [ ] Cache guidance for Netlify
- [ ] exampleSite fixtures
- [ ] Verify build output sizes and formats

## Acceptance criteria

- Every raster image on exampleSite has `srcset`, `sizes`, `width`, `height`, and `alt`.
- An image with no `alt` fails the build with a clear message naming the page.
- Lighthouse reports no CLS from images and no "properly size images" failure.
- No deprecated imaging keys appear anywhere (deprecation check from issue 02 stays green).

## Open questions

- Ship AVIF in v0.1.0 or WebP only? AVIF saves bytes but costs build time (`encoderSpeed` tradeoff). Recommend WebP only by default with AVIF as a param opt-in.
- Should the Markdown title attribute become a `<figcaption>`, or should captions require the `figure` shortcode only?
- `imaging` does not merge from modules by default. If the issue 12 experiment shows `_merge` cannot pull it, the defaults must live in each site's config. The partial should therefore not depend on imaging config for correctness.
- Should the base read image metadata (the `Meta` method, new in v0.155.0, which replaced `Exif`) for anything, such as orientation or alt fallbacks? Recommend no.
