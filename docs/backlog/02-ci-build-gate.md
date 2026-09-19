CI build gate: build, deprecations, dash lint, version drift

## Summary

Add the GitHub Actions build gate as a reusable workflow that this repo dogfoods against `exampleSite` and that consuming sites will call later. It must fail on warnings, deprecations, dash characters in prose, and Hugo version drift.

## Detailed scope

- `.github/workflows/site-ci.yml` with `on: workflow_call`. Inputs: `source` (default `.`), `hugo-flags` (optional extra flags).
- `.github/workflows/ci.yml` for this repo: runs on `push` to `main` and on `pull_request`, and calls `./.github/workflows/site-ci.yml` with `source: exampleSite`.
- Jobs and steps in `site-ci.yml`:
  1. Install the pinned toolchain from the caller's `mise.toml` (via `jdx/mise-action`), so the workflow itself does not carry a separate version.
  2. Version drift check: a script that reads Hugo from `mise.toml`, `netlify.toml`, and any `HUGO_VERSION` in `.github/workflows/*.yml`, and fails if they differ. Also compares `hugo version` output to the expected value.
  3. Build: `hugo build --source "$SOURCE" --gc --minify --panicOnWarning --logLevel info`, tee the log.
  4. Deprecation check: fail if the log contains `deprecated` (Hugo logs new deprecations at INFO level for several releases before they become WARN, so `--panicOnWarning` alone catches them late).
  5. Dash lint: fail if any tracked text file outside `exampleSite/content` fixtures contains U+2013 or U+2014.
  6. Upload `public/` as a workflow artifact for the quality gate in issue 04.
- Hugo cache directory cached between runs (`--cacheDir` under `runner.temp`).
- `scripts/check-versions.sh` and `scripts/lint-dashes.sh`, both runnable locally.

## Design or architecture considerations

- Reusable workflow over a copied workflow so every consumer gets the same gate, pinned by tag. See the distribution recommendation in the planning notes.
- A reusable workflow runs in the caller's repository context, so it cannot read this repo's files by relative path. Once Hugo has resolved modules, though, `hugo config mounts` prints each module's `dir` on disk (verified locally on v0.166.0). Scripts and configs under `tools/` can therefore be read from the hugo-base version the site pins in `go.mod`. That keeps checks in step with the site's base version rather than the workflow ref. Keep the drift check inline because it must run before Hugo resolves anything.
- Failing on INFO level deprecations is intentionally strict. It turns a future Hugo bump into a red PR at the moment a deprecation appears, which is what makes the Renovate PRs trustworthy.

## Task checklist

- [ ] `site-ci.yml` with `workflow_call` inputs
- [ ] `ci.yml` that calls it for `exampleSite`
- [ ] mise based toolchain install, with Go
- [ ] Drift check script plus inline equivalent
- [ ] Build with `--panicOnWarning --logLevel info`, log captured
- [ ] Deprecation grep
- [ ] Dash lint
- [ ] Hugo cache
- [ ] Artifact upload of the built site
- [ ] Branch protection on `main` requiring this check

## Acceptance criteria

- CI is green on `main` with the scaffold from issue 01.
- Each of these, done on a throwaway branch, turns CI red: a template calling `warnf`; a mismatched `HUGO_VERSION` in `netlify.toml`; an em dash in `README.md`; use of a deprecated config key (for example top-level `imaging.quality`).
- The workflow contains no hard-coded Hugo version.
- Scripts run locally with the same result as CI.

## Open questions

- If the site passes a mise tool name that installs a different edition from Netlify, the drift check cannot see it. Should the drift check also assert the edition (`+extended` in `hugo version` output)?
- Is failing on any INFO `deprecated` line too strict in practice (for example, a deprecation triggered by an embedded Hugo template we do not control)? If so, we need an allowlist file rather than disabling the check.
- Should `--printPathWarnings` and `--printUnusedTemplates` also run here? Unused template warnings with `--panicOnWarning` would force exampleSite coverage (desirable), but only once issue 15 is done. Candidate to enable at that point.
