CSS foundation and token architecture

## Summary

Build the theme-independent CSS foundation that every site shares and none should override: the color system mechanics (OKLCH), token architecture, spacing and type scales, reset, global accessibility rules, and intrinsic layout primitives. Separate it clearly from the theme slot each site fills in.

## Detailed scope

Two ownership zones in `assets/css/`:

**Foundation (owned by hugo-base; overriding it is unsupported and CI blocks it, issue 08)**

- `main.css`: the entry point. Declares layer order once (`@layer reset, tokens, foundation, layout, components, utilities;`) and imports every file into its layer.
- `tokens/scale.css`: the 8pt spacing scale in rem, fluid type scale (`clamp()` with rem bounds), line heights, measure, radius scale steps, z-index scale, durations and easings.
- `tokens/color.css`: the OKLCH color mechanics. Neutral and accent lightness ramps built from the theme's hue and chroma inputs. Hover, active, and subtle states derived with relative color syntax (for example `oklch(from var(--color-accent) calc(l - 0.08) c h)`), so a theme sets inputs and never hand-writes states.
- `tokens/semantic.css`: the semantic contract (text, text-muted, surface, surface-raised, border, accent, on-accent, link, link-visited, focus-ring, status colors). Components use only these names.
- `foundation/reset.css`: modern minimal reset.
- `foundation/global.css`: `color-scheme`, `accent-color`, `::selection`, `text-size-adjust`, `scroll-padding-block-start` for anchors, `:target` scroll margin, `[hidden]` handling, media defaults.
- `foundation/a11y.css`: global `:focus-visible` ring, `.visually-hidden`, skip link base, `@media (forced-colors: active)` fixes (borders and focus stay visible in Windows High Contrast), `@media (prefers-contrast: more)` token adjustments.
- `foundation/motion.css`: every transition and animation defined only under `prefers-reduced-motion: no-preference`.
- `foundation/print.css`: readable print output (hide nav, show link URLs, no backgrounds).
- `layout/primitives.css`: intrinsic layout primitives that carry no visual theme: stack, cluster, center, sidebar, switcher, auto grid, and named `container-type` wrappers for container queries. All spacing comes from scale tokens.

**Theme slot (owned by each site)**

- `tokens/theme.css`: the only file a site overrides to theme itself. Inputs only: accent and neutral hue and chroma, optional per-step chroma overrides, font stacks, radius choice, shadow strength, optional dark mode inputs. Neutral defaults ship here.
- `components/*.css`: base component skins read component-level custom properties (for example `--card-radius`) that fall back to tokens, so a site can restyle a component without overriding the file.

Also:

- `layouts/_partials/head/css.html`: `css.Build`, then `fingerprint` and SRI in production.
- `layouts/_partials/head/css-site.html`: empty seam where a site links its own stylesheet (unlayered, so it wins).
- exampleSite: a `theme.css` override with a distinct hue, and a "foundation" reference page showing tokens, semantic pairs, and each layout primitive.

## Design or architecture considerations

- The foundation controls how color is expressed, not which colors are used. That is what lets it be shared across differently branded sites.
- CSS cannot reject a hex literal on its own. The OKLCH-only rule is enforced by the policy lint in issue 08. This issue provides the mechanics that make the rule easy to follow.
- Deriving states with relative color syntax means themes supply a handful of inputs. It also means semantic contrast can be tested once in the base, then re-tested per site by axe with that site's inputs.
- Hugo's unified file system lets a site override any path, including foundation files. The only protection is convention (the rules) plus the CI check. Component-level custom properties give sites a supported way to customize, so they have no reason to copy foundation files.
- Leaving `css.Build`'s `target` unset keeps nesting, `@layer`, relative color syntax, and `oklch()` as written.

## Task checklist

- [ ] `main.css` with layer order
- [ ] Scale, color, and semantic token files
- [ ] `theme.css` slot with neutral defaults and documented inputs
- [ ] Reset, global, a11y, motion, print
- [ ] Layout primitives and container conventions
- [ ] Head CSS partials with `css.Build`, fingerprint, SRI
- [ ] exampleSite theme override and foundation reference page
- [ ] Update `agents/rules/css.md` to describe the zones and the theme inputs

## Acceptance criteria

- Changing only the hue and chroma inputs in exampleSite's `theme.css` rethemes the whole site, including hover and focus states.
- Every semantic text and surface pair passes 4.5:1 with the default theme and the exampleSite theme (axe green).
- With forced colors emulated in DevTools, focus rings and component borders remain visible.
- With reduced motion emulated, no transitions run.
- Production CSS is one fingerprinted file with an `integrity` attribute.

## Open questions

- Decided 2026-09-18: the browser floor includes relative color syntax, nesting, `@layer`, and container queries. No fallback is built. `css.Build` `target` stays unset.
- Dark mode in v0.1.0 or deferred? The color mechanics make it mostly a second set of lightness inputs, but it doubles the contrast pairs to verify.
- Theme inputs versus explicit ramps: can a single chroma value produce in-gamut, usable colors across the whole lightness range for every hue? High-chroma hues often clip at the extremes. Per-step chroma overrides are the escape hatch, but test with each current site's brand color before settling the contract.
- Is a 4px half step allowed on the 8pt scale?
- Should layout primitives use classes (`.stack`) or custom elements or attributes? Classes are simplest and need no JS.
- `css.Build` (v0.158.0+) docs do not describe nesting or relative color handling. Verify minified output leaves both untouched.
