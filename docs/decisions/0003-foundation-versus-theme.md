# 0003: Foundation versus theme, and one file of inputs

## Context

Several sites share a design system but need different brands. The question is
where the line sits between what is shared and what each site decides.

## Decision

The foundation controls **how** things are expressed: the color space, the
ramps, the scales, focus, motion, layout mechanics. A theme controls **which
brand** they express, through one file of inputs
(`assets/css/tokens/theme.css`): hues, chromas, fonts, radius and shadow
strength. Everything else is derived, including interaction states and dark
mode.

Color is OKLCH throughout, and states are computed with relative color syntax
rather than hand written per theme.

## Consequences

- Theming a site is a handful of values, and hard to get wrong.
- A site cannot drift from the system by editing a reset or a scale: the lint
  blocks copies of foundation files.
- Every input is read with its default as a fallback, so a partial theme cannot
  invalidate a token. That was learned the hard way: the example site's theme
  omitted one input and silently broke all four status colors while axe still
  passed.
- The theme file loads last in the tokens layer, so a site can override one
  computed ramp step when a hue clips. That was also learned the hard way: the
  documented escape hatch did not work until the import order changed.
- Contrast becomes the site's responsibility, which is why the gate checks the
  built site rather than the base's defaults.
