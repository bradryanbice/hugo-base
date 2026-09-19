Consumer documentation and CHANGELOG

## Summary

Write the documentation a consuming site needs: how to import, what to override, what config to carry, how updates flow, and what counts as a breaking change.

## Detailed scope

- `README.md`:
  - What the base is and is not (the scope test).
  - Quick start: import via `module.imports`, `hugo mod get github.com/bradryanbice/hugo-base@vX.Y.Z`, add the CI caller workflow, extend the Renovate preset.
  - Config contract: what merges from the base and what each site must carry (from issue 12).
  - Override guide: the list of stable seams (partials, hooks, token files, i18n keys, shortcodes) with their paths, and the template lookup rules that matter (page kind templates beat `list.html` and `single.html`).
  - Branding: how to write `assets/css/tokens/theme.css` (the theme inputs), and the contrast responsibility that comes with it.
  - Params reference under `params.base`.
  - Updating: `hugo mod get -u github.com/bradryanbice/hugo-base`, `hugo mod tidy` (never `go mod tidy`), reading the CHANGELOG.
  - Local development against an unreleased base: `HUGO_MODULE_REPLACEMENTS` or `module.replacements`.
- `CHANGELOG.md` in Keep a Changelog format, with a "Breaking" subsection convention.
- `docs/decisions/` with short ADRs for: CI distribution, token layering, config contract, no JS.
- Dash lint must pass across all docs.

## Design or architecture considerations

- The seam list is the public API. Anything not listed is internal and may change in a minor release. Stating that explicitly keeps future refactors cheap.

## Task checklist

- [ ] README sections above
- [ ] CHANGELOG with Unreleased entries for everything in v0.1.0
- [ ] ADRs
- [ ] Review against CLAUDE.md for consistency

## Acceptance criteria

- A reader can add the base to a new empty Hugo site using only the README and get a green CI run.
- Every seam in the README exists in the repo, and every overridable file in the repo appears in the README (checked manually at release).
- No em or en dashes (CI).

## Open questions

- Should the seam list be machine checked (for example a manifest file that CI compares against the tree) so it cannot drift? Probably worth it after v0.1.0.
