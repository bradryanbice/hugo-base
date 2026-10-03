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
- Three token layers. `tokens/scale.css` holds sizes and timings.
  `tokens/color.css` builds ramps (`--neutral-500`, `--accent-700`) from the
  theme inputs. `tokens/semantic.css` names them for use (`--color-text`,
  `--color-surface`, `--color-accent`, `--color-focus-ring`). Layouts and
  components use semantic names only, never a ramp step and never a raw
  `oklch()`.
- Dark mode is the same semantic names pointing at different ramp steps, under
  `prefers-color-scheme: dark`. Anything you add must work in both schemes,
  which means taking your colors from semantic tokens rather than picking a
  light value directly.

## Spacing is an 8pt scale

- Use the spacing tokens, in `rem` (8px is 0.5rem). Do not hard code lengths.
- `--space-0h` (4px) is the only half step, for icon gaps and focus offsets.
  Everything else is a multiple of 8.
- Use logical properties (`margin-block`, `padding-inline`), not physical ones.
- Spacing between elements comes from the layout primitives (`stack`,
  `cluster`, `center`, `sidebar`, `switcher`, `grid-auto`), which take a per
  instance override such as `--stack-space`, so components rarely need their
  own layout rules.

## Foundation versus theme

Foundation files are owned by hugo-base and must not be shadowed by a site.
CI fails if a site has its own copy of any of these:

- `assets/css/main.css`
- `assets/css/tokens/scale.css`, `tokens/color.css`, `tokens/semantic.css`
- `assets/css/foundation/**` (reset, global, typography, highlight, a11y,
  motion, print)
- `assets/css/layout/primitives.css`

To change how a site looks, write `assets/css/tokens/theme.css`. It is the one
file a site overrides, and it is loaded last in the tokens layer so it has the
final word. Declare only the inputs you want to change: every input is read
with its default as a `var()` fallback, so leaving one out keeps the default
rather than breaking the token.

The inputs are `--accent-hue`, `--accent-chroma`, `--neutral-hue`,
`--neutral-chroma`, `--status-chroma`, the four status hues, `--font-body`,
`--font-heading`, `--font-mono`, `--radius-scale` and `--shadow-strength`. The
base's own `tokens/theme.css` documents each one with its default.

High chroma cannot hold at the light and dark ends of a ramp. If one step looks
wrong for your hue, override that single step (for example `--accent-700`) in
your `theme.css`. Component level custom properties such as `--card-radius`
cover finer adjustments. If the theme slot cannot express what a site needs,
that is a hugo-base issue, not a reason to copy a foundation file.

Site specific CSS is unlayered and loads after the base, so it wins without
specificity fights. Add it through the `head/css-site.html` partial.

## Typography

- Element styles come from the foundation: a site sets `--font-body`,
  `--font-heading` or `--font-mono` in `theme.css` and nothing else changes.
  Self hosting a font and setting `font-display` belong to the site.
- Wrap a run of Markdown output in `.prose`. It sets the reading measure and
  the vertical rhythm, including the tighter spacing between a heading and the
  text it introduces. Do not put `.stack` on the same element: both add
  spacing. Override the width per instance with `--prose-measure`.
- Code blocks wrap instead of scrolling sideways, because a horizontal scroller
  breaks reflow at 400 percent zoom and needs a focusable region for keyboard
  users.
- Syntax highlighting needs `[markup.highlight] noClasses = false` in the
  site's config. Hugo otherwise writes hardcoded hex colors inline, which
  ignore the tokens, fail contrast and cannot follow dark mode. The base styles
  Chroma's classes from semantic tokens.
- Text must reflow at 320px (400 percent zoom at 1280px) with no horizontal
  scrolling. Long words, URLs and identifiers need `overflow-wrap`, or the
  `.wrap-anywhere` utility.

## What CI enforces

These are not style suggestions. `./hugo-base.sh lint` runs them locally and
the gate runs them on every pull request:

- no hex, named, `rgb()`, `hsl()`, `hwb()`, `lab()`, `lch()` or `color-mix()`
  values, so every color is `oklch()`
- color, background, margin, padding, gap, inset, border radius and z-index
  must come from a token, a keyword, or an `em` value (which is relative to the
  element's own text)
- no `!important`
- no `outline: none` or `outline: 0`
- logical properties instead of physical ones
- no `@import` outside `main.css`
- no primitive ramp step (`var(--neutral-700)`, `var(--accent-500)`) outside
  the token files
- no site copy of a foundation file

A genuine exception is taken with a `stylelint-disable-next-line` comment
directly above the declaration, naming the rule, with a reason. The base has
four, each explained in place.

## Contrast is checked, in both schemes

The quality gate runs axe over every page and separately checks every semantic
pair in the token contract, in light and in dark mode. A pair that falls below
4.5:1 for text or 3:1 for borders and focus rings fails the build, as does a
token that does not resolve. So a brand color that breaks contrast cannot ship,
and neither can a theme that leaves a token invalid.

## Modern CSS, and what a site may use

- Cascade layers, nesting, custom properties, container queries, `:has()` and
  relative color syntax are all expected to work natively. No fallbacks.
- Layer order is declared once in `main.css`:
  `@layer reset, tokens, foundation, layout, components, utilities;`
- No `!important` in shared CSS. The one exception in the base is `[hidden]`,
  which must always win.
- No CSS framework.

**The foundation is plain CSS.** hugo-base uses no Sass, no PostCSS and no npm
step: Hugo Pipes with `css.Build`, then `fingerprint` in production. That is not
negotiable for the base, because its colour system depends on values the browser
resolves (`oklch(from var(--token) ...)`), and a preprocessor variable is gone
before the browser sees it.

**A site may write its own styles in Sass.** Plenty of sites have years of it,
and the rest of the base is worth adopting long before that gets converted. Two
things follow:

- The policy still applies. Colour is still `oklch()`, spacing still comes from
  tokens, and the lint checks `.scss` as well as `.css`. A Sass variable counts
  as a variable, so `$space-m` passes and a raw `12px` does not.
- A Sass variable cannot hold a value the token system derives from. Anything
  the base computes (ramps, hover and active states, dark mode) has to stay a
  custom property. Mixing is fine: keep layout and components in Sass, move
  colour to the tokens.

A site part way through this can exempt paths in `.hugo-base-lint-ignore`, one
glob per line with a reason after a `#`:

```
assets/scss/**   # legacy Sass predating hugo-base, conversion tracked in #12
```

Exemptions are printed on every lint run. That is deliberate: an unchecked path
should stay visible rather than quietly becoming the way things are.
