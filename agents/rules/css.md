---
description: CSS rules for hugo-base sites: OKLCH color, layered tokens, the 8pt scale, foundation versus theme
paths: "assets/css/**,**/*.css"
---

# CSS

This file is managed by hugo-base. Do not edit it inside a site.

## Color is OKLCH

- Every color value is `oklch()`. No hex, `rgb()`, `hsl()` or named colors.
  CI fails on them.
- Interaction states are derived, not hand written: `oklch(from var(--token)
  calc(l - 0.08) c h)`.
- Two token layers. Primitives hold raw scales. Semantic aliases
  (`--color-text`, `--color-surface`, `--color-accent`, `--color-focus-ring`)
  reference primitives. Components use semantic tokens only, never primitives.

## Spacing is an 8pt scale

- Use the spacing tokens, in `rem` (8px is 0.5rem). Do not hard code lengths.
- Use logical properties (`margin-block`, `padding-inline`), not physical ones.

## Foundation versus theme

Foundation files are owned by hugo-base and must not be shadowed by a site.
CI fails if a site has its own copy of any of these:

- `assets/css/main.css`
- `assets/css/tokens/scale.css`, `tokens/color.css`, `tokens/semantic.css`
- `assets/css/foundation/**`
- `assets/css/layout/primitives.css`

To change how the site looks, write `assets/css/tokens/theme.css`. It takes
inputs only: accent and neutral hue and chroma, font stacks, radius and shadow
choices. Component level custom properties (for example `--card-radius`) cover
finer adjustments. If the theme slot cannot express what a site needs, that is
a hugo-base issue, not a reason to copy a foundation file.

Site specific CSS is unlayered and loads after the base, so it wins without
specificity fights. Add it through the `head/css-site.html` partial.

## Modern CSS, no tooling

- Cascade layers, nesting, custom properties, container queries, `:has()` and
  relative color syntax are all expected to work natively. No fallbacks.
- Layer order is declared once in `main.css`:
  `@layer reset, tokens, foundation, layout, components, utilities;`
- No CSS framework, no Sass, no PostCSS, no npm step for site assets. The only
  pipeline is Hugo Pipes with `css.Build`, then `fingerprint` in production.
- No `!important` in shared CSS.
