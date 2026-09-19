Content layouts: home, single, list, taxonomy, term, 404

## Summary

Implement the base content templates under the v0.146.0 template system, generic enough for any content type, with accessible pagination.

## Detailed scope

- `layouts/single.html`: article with `<h1>`, date (`<time datetime>`), optional lastmod, summary or description, content, and taxonomy term links.
- `layouts/list.html`: section heading, optional section content, list of pages as a semantic list of cards (heading level correct), pagination.
- `layouts/home.html`: falls back to list behavior unless the site overrides it. Decide whether a separate `home.html` is needed at all.
- Taxonomy and term pages: rely on `list.html` fallback unless a specific need appears.
- `layouts/404.html`: helpful message, link home, search seam (empty).
- `layouts/_partials/pagination.html`: our own accessible pagination (`<nav aria-label>`, current page with `aria-current="page"`, text for previous and next) rather than the embedded one.
- `layouts/_partials/page/meta.html`, `page/terms.html`, `page/card.html` as small overridable pieces.
- Components CSS for cards and pagination in the `components` layer.

## Design or architecture considerations

- No `_default/`. Templates sit at the `layouts/` root. The lookup now ranks page kind (`home`, `section`, `taxonomy`, `term`, `page`) above standard layouts (`list`, `single`, `all`). A site that adds `section.html` will override our `list.html` for sections. Document this in the override guide.
- No content type specific layouts in the base. A site adds `layouts/<section>/single.html` for its own types.
- The card partial's heading level depends on context (h2 on list pages). Pass it in rather than hard-coding.

## Task checklist

- [ ] `single.html`, `list.html`, `404.html`, and `home.html` if needed
- [ ] Pagination partial
- [ ] Page meta, terms, card partials
- [ ] Components CSS
- [ ] exampleSite: a section with enough pages to paginate, tags taxonomy, a 404 check

## Acceptance criteria

- exampleSite renders home, section, taxonomy, term, page, and 404 without warnings.
- Heading hierarchy is valid on every template (axe `heading-order` and a manual check).
- Pagination is keyboard operable and announces the current page.
- A test override in exampleSite (`layouts/section.html` or a section specific `single.html`) takes precedence over the base, proving the documented override behavior.

## Open questions

- The v0.146.0 docs say Hugo maps old names to new "as much as possible" but some breakages were reported. Do any consumer sites still ship `layouts/_default/` or `layouts/partials/`, and how will those interact with base templates at the new paths? This affects migration of the existing five sites and should be tested before v0.1.0.
- Does a module's `404.html` still get rendered for the site automatically, and does Netlify pick up `/404.html` without extra config? Verify.
- Titles containing "/" no longer create nested URL segments as of v0.166.0. Do any existing sites rely on the old behavior?
