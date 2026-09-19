Shortcodes: figure, callout, table

## Summary

Ship the three shared shortcodes, each accessible by default, with stable parameter names.

## Detailed scope

- `layouts/_shortcodes/figure.html`: `<figure>` with the image partial from issue 13 and an optional `<figcaption>` (Markdown allowed). Params: `src`, `alt`, `caption`, `sizes`, `class`.
- `layouts/_shortcodes/callout.html`: an aside for notes and warnings. Params: `type` (`note`, `tip`, `warning`, `danger`), optional `title`. Renders `<aside>` or `<div role="note">` with a visible text label for the type (never color or icon alone). Inner content rendered as Markdown.
- `layouts/_shortcodes/table.html`: wraps a Markdown table (inner content) with a `<caption>`, a scrollable region that is keyboard focusable and labelled when it overflows, and optional `data` source (CSV from page resources) rendered with `<th scope>`.
- `layouts/_markup/render-table.html`: optional, so plain Markdown tables also get the scroll wrapper.
- Component CSS for each in the `components` layer, using semantic tokens only.
- exampleSite page demonstrating every parameter.

## Design or architecture considerations

- Hugo ships an embedded `figure` shortcode. Ours shadows it with the same name. Existing content using the embedded parameters (`src`, `alt`, `caption`, `link`, `title`) should keep working, so match those names where they overlap.
- A scrollable table container needs `tabindex="0"`, a role, and an accessible name so keyboard users can scroll it (axe `scrollable-region-focusable`).
- Callout type must be conveyed in text, not only by color (SC 1.4.1).

## Task checklist

- [ ] figure
- [ ] callout
- [ ] table shortcode and table render hook
- [ ] Component CSS
- [ ] exampleSite demo page

## Acceptance criteria

- axe green on the demo page, including a table wide enough to overflow at 320px.
- Existing content written for Hugo's embedded `figure` renders correctly with ours.
- Each shortcode's parameters are documented in the README.

## Open questions

- Should `table` accept CSV data now, or is that a data schema concern that belongs in sites (the stats sites in particular)? Recommend Markdown tables only for v0.1.0, with CSV deferred.
- Use `<aside>` for callouts? `<aside>` is a complementary landmark when not nested in `<article>`, which can clutter landmark navigation. Recommend `<div role="note">` or scoped `<aside>` only inside `<article>`.
