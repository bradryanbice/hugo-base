CSS policy lint and protected paths

## Summary

Enforce the CSS rules in CI for hugo-base and every consuming site: OKLCH only, tokens for spacing, no primitives outside the theme slot, no `!important`, no focus removal, logical properties, and no overrides of foundation files.

## Detailed scope

- `tools/lint/stylelint.config.mjs` and `tools/lint/package.json` with pinned Stylelint and plugins. Rules:
  - `color-no-hex`, `color-named: "never"`, and `function-disallowed-list` for `rgb`, `rgba`, `hsl`, `hsla`, `hwb`, `lab`, `lch` (only `oklch()` and relative `oklch(from ...)` allowed).
  - Strict values: color, background, border color, margin, padding, gap, and inset properties must use `var()` or a keyword (via a strict value plugin).
  - `declaration-no-important`.
  - Disallow `outline: none` and `outline: 0` unless the same rule sets a replacement.
  - Logical properties over physical ones (plugin).
  - Disallow `var(--neutral-*)` and other primitive references outside `tokens/`.
- `tools/check-protected.sh`: fails if a site contains any path that shadows a foundation file (`assets/css/main.css`, `assets/css/tokens/{scale,color,semantic}.css`, `assets/css/foundation/**`, `assets/css/layout/primitives.css`). The protected list lives in `tools/managed-files.toml` alongside the manifest.
- Reusable workflow: after the build, locate the hugo-base module directory (as in issue 05), copy `tools/lint` to a temp dir, install, and lint the site's `assets/**/*.css` plus the base's own CSS.
- A `hugo-base.sh lint` subcommand so the same check runs locally.

## Design or architecture considerations

- Lint config ships in the module, not in each site, so it moves with the pinned version. A rule added in hugo-base v0.4.0 reaches a site in the same PR that bumps it, alongside the migration note explaining how to comply.
- The Go module cache is read-only, so tools are copied out before `npm ci`.
- Node is CI and dev tooling only. It never touches the site's build output, which keeps the "Hugo Pipes only" rule intact.
- A new lint rule can turn every site red at once. Add rules together with a migration file (issue 16) and, where possible, an autofix.

## Task checklist

- [ ] Stylelint config and pinned dependencies
- [ ] Protected path check
- [ ] Reusable workflow step
- [ ] `hugo-base.sh lint`
- [ ] Fixture files proving each rule fires
- [ ] Add the enforced rules to `agents/rules/css.md`, marked as CI-enforced

## Acceptance criteria

- A fixture with `color: #333`, `margin: 12px`, `outline: none`, `!important`, and `margin-left` fails with one error per rule.
- A site file at `assets/css/foundation/reset.css` fails the protected path check.
- The base's own CSS passes.
- Renovate bumps the lint dependencies through the same preset.

## Open questions

- Should the lint allow hex or rgb inside SVG files and inline SVG in templates, or is OKLCH required there too? Recommend CSS files only for v0.1.0.
- The strict-value rule will flag legitimate values such as `0`, `auto`, `100%`, and `1px` hairlines. Agree on the allowlist before rolling out to existing sites.
- Should the protected path check be a hard failure or a warning that allows a documented exception (a file listing justified overrides)? Recommend hard failure, with exceptions handled by fixing the base.
