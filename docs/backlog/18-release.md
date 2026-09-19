Release v0.1.0 and consumption smoke test

## Summary

Tag v0.1.0, publish the release, and prove that a site outside this repo can consume the module, the reusable workflow, and the Renovate preset by tag.

## Detailed scope

- Release checklist in `docs/releasing.md`: CHANGELOG finalized, `hugoVersion.min` matches the tested Hugo, CI green on `main`, annotated tag `v0.1.0`, GitHub release with notes from the CHANGELOG.
- Smoke test repo (private scratch repo or a branch of `hugo-starter`):
  - `hugo mod init`, `hugo mod get github.com/bradryanbice/hugo-base@v0.1.0`.
  - A caller workflow using `bradryanbice/hugo-base/.github/workflows/site-ci.yml@v0.1.0`.
  - A `renovate.json` extending the preset.
  - A `theme.css` override and a menu.
  - `./hugo-base.sh sync` run, managed files committed, and the upgrade skill exercised by bumping from a pre-release tag to v0.1.0.
  - A Netlify deploy.
- Record the result and anything that differed from the README.

## Design or architecture considerations

- Go module tags are effectively immutable once fetched through a proxy or cached by consumers. Never move or delete a tag. Fix forward with v0.1.1.
- `module.proxy` defaults to `direct` and `private` to `*.*`, so Hugo clones from GitHub directly rather than through the Go proxy. A private repo would then need `module.auth` or git credentials on Netlify and in Actions.
- If the major version ever reaches 2, the module path must change to `github.com/bradryanbice/hugo-base/v2`.

## Task checklist

- [ ] Release checklist doc
- [ ] Tag and GitHub release
- [ ] Smoke test repo covering module, workflow, preset, override, Netlify
- [ ] Fix and document any gaps (v0.1.1 if needed)
- [ ] Open the `hugo-starter` tracking issue with what was learned

## Acceptance criteria

- The smoke test site builds on Netlify and passes the reusable CI gate, consuming everything by tag with no local replacements.
- Renovate onboards the smoke test repo and reports the Hugo and hugo-base dependencies it detected.
- Release notes list every public seam.

## Open questions

- Public or private repo? A reusable workflow in a private repo can only be called from other repos if the Actions access setting allows it, and Hugo module fetches need credentials. Public avoids both and there is nothing secret in the base. Recommend public.
- Should consuming sites vendor the module (`hugo mod vendor`, commit `_vendor/`) so Netlify builds do not depend on GitHub availability or Go being installed? It trades reproducibility for noisier diffs on update.
