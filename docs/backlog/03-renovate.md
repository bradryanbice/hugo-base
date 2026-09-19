Renovate preset: one grouped PR per Hugo release

## Summary

Configure Renovate so each Hugo release produces exactly one PR that updates `netlify.toml`, the workflow files, and `mise.toml` together. Ship it as a preset that consuming sites extend (or copy) unchanged.

## Detailed scope

- `renovate/hugo.json`: a shareable preset containing:
  - `customManagers` of `customType: "regex"` with `managerFilePatterns` covering `netlify.toml`, `.github/workflows/*.yml`, and `mise.toml`.
  - Each match uses `datasourceTemplate: "github-releases"`, `depNameTemplate: "gohugoio/hugo"`, and `extractVersionTemplate: "^v(?<version>.+)$"`.
  - A `packageRules` entry grouping `gohugoio/hugo` under `groupName: "Hugo"` so all three files land in one PR.
  - A rule that disables Renovate's built-in `mise` manager for the Hugo entry, so it does not open a second competing PR.
  - The same pattern for `GO_VERSION` and the mise Go entry, grouped as "Go".
- `renovate.json` at the root: `extends` `config:recommended` plus `local>bradryanbice/hugo-base//renovate/hugo` (or the `github>` form).
- A CI step that runs `renovate-config-validator` on both files.
- Documentation of the two consumption modes: extend the preset by reference (recommended), or copy `renovate/hugo.json` verbatim.

## Design or architecture considerations

- Regex managers for all three files, rather than the regex manager for netlify.toml plus the native mise manager, give one identical depName and datasource everywhere. That makes grouping deterministic.
- Hugo is `0.x`. Under semver versioning Renovate treats `0.166 to 0.167` as a major change, which affects labels and any automerge rules. Decide deliberately rather than inheriting defaults.
- Consumers also depend on `github.com/bradryanbice/hugo-base` in `go.mod`. Renovate's `gomod` manager will propose those bumps. Do NOT enable the `gomodTidy` post-update option. There is no Go code, so `go mod tidy` would remove the requirement.
- Extending by reference means a preset fix reaches every site immediately. Copying means drift. Recommend extending.

## Task checklist

- [ ] Write `renovate/hugo.json`
- [ ] Root `renovate.json` extending it
- [ ] Validator step in CI
- [ ] Install the Renovate GitHub App on this repo
- [ ] Dry run (`LOG_LEVEL=debug`, `--dry-run=full`) against a branch pinned to an older Hugo (for example 0.165.0) and capture the output
- [ ] Document both consumption modes in the README

## Acceptance criteria

- On a test branch with all three files set to 0.165.0, Renovate proposes a single PR titled for Hugo that changes all three files to the latest release.
- No separate PR is opened by the mise manager.
- The preset contains no reference to this repo's paths or names, and validates.
- CI on the Renovate PR runs the full gate from issues 02 and 04.

## Open questions

- Can Renovate's regex manager match a `HUGO_VERSION` inside workflow YAML without also matching our own `site-ci.yml` (which should have no version at all)? Verify the patterns do not produce false matches.
- The mise manager may map Hugo to a different datasource or depName (for example an aqua package). Confirm what it emits so the disable rule targets it precisely.
- Automerge for patch releases of Hugo once the gate has a track record? Recommend no automerge for v0.1.0.
- Should the preset also pin and bump the reusable workflow ref (`bradryanbice/hugo-base/.github/workflows/site-ci.yml@vX.Y.Z`) in consumers? The `github-actions` manager should handle reusable workflow refs, but confirm, and consider grouping it with the `go.mod` bump of `hugo-base` so base and CI move together.
