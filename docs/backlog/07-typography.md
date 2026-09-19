Typography

## Summary

Add base typography on top of the foundation from issue 06: prose styles, heading rhythm, links, and code, all driven by scale tokens and the theme's font inputs.

## Detailed scope

- `assets/css/foundation/typography.css` in the `foundation` layer: body font from the theme's font token, fluid type scale from `tokens/scale.css`, line height, measure (`max-inline-size` around 65ch for prose), heading rhythm on the spacing scale, links (underlined in body text, distinct visited state), `code`, `pre`, `blockquote`, `hr`, lists, `abbr`, `mark`, tables at the element level.
- A `.prose` (or `.flow`) wrapper that applies vertical rhythm to Markdown output.
- Font loading: system font stack by default. The theme slot takes font stacks. Self-hosting and `font-display` belong to the site, documented in `agents/rules/css.md`.
- exampleSite "typography" page exercising every element.

## Design or architecture considerations

- Fluid type with `clamp()` must still respond to user font size settings and 200 percent zoom (SC 1.4.4). Use `rem` in the clamp bounds, never pure `vw`.
- Links distinguished by color alone fail SC 1.4.1. Keep underlines in running text.
- Typography is foundation, not theme: a site changes fonts through theme inputs, not by overriding this file.

## Task checklist

- [ ] Typography file on scale tokens
- [ ] Prose rhythm wrapper
- [ ] Font inputs wired from `theme.css`
- [ ] exampleSite typography page
- [ ] Update `agents/rules/css.md`

## Acceptance criteria

- Zooming to 400 percent at 1280px wide reflows with no horizontal scroll on the typography page (SC 1.4.10), checked manually and noted in the PR.
- Changing the font input in exampleSite's `theme.css` changes body and heading fonts with no other edits.
- axe and Lighthouse green. CSS policy lint green once issue 08 lands.

## Open questions

- Should the base set `text-wrap: pretty` and `hyphens: auto` for prose? Both are progressive, but hyphenation depends on `lang` being correct per page.
- Visited link color: keep it (useful on stats sites with many links) or leave to sites?
- Separate heading font input, or one font stack for everything by default?
