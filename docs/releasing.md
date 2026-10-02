# Releasing

A release is a git tag. Consumers fetch it by tag, so **a tag is permanent**:
Go module caches and proxies make a moved or deleted tag worse than a wrong
one. Fix forward with the next patch.

## Before tagging

1. `main` is green. Not "green on the pull request": green on `main`, since a
   rebase merge produces a commit CI has not run on until it does.
2. The local checks pass on a clean clone:

   ```sh
   bash tools/ci/check-versions.sh
   bash tools/ci/lint-dashes.sh
   bash tools/ci/build.sh exampleSite
   bash tools/ci/check-harness.sh exampleSite/public
   python3 tools/sync.py --base . --site exampleSite --check
   bash tools/lint/run.sh --self-test . exampleSite
   bash tools/quality/run.sh exampleSite/public
   ```

3. `module.hugoVersion.min` in `hugo.toml` equals the Hugo version CI actually
   tested. Never raise it hopefully.
4. `CHANGELOG.md` has a section for the version, dated, with anything that
   breaks a consumer listed first under **Breaking**.
5. A release needing work in a site has a note in `migrations/vX.Y.Z.md`, and
   the CHANGELOG links it.
6. Anything renamed or removed from the public API (the seam list in the
   README) is in that Breaking list.

## Tagging

```sh
git checkout main && git pull --ff-only
git tag -a v0.1.0 -m "hugo-base v0.1.0"
git push origin v0.1.0
gh release create v0.1.0 --title "v0.1.0" --notes-file <notes>
```

## After tagging

Prove a site outside this repo can consume the tag, because everything in this
repo uses the local checkout and would not catch a packaging mistake:

```sh
hugo mod init example.com/smoke
hugo mod get github.com/bradryanbice/hugo-base@v0.1.0
```

Then: the config from the README quick start, a `theme.css`, a menu, a page,
the managed file sync, a build, and the gate. A caller workflow referencing
`bradryanbice/hugo-base/.github/workflows/site-ci.yml@v0.1.0` proves the
workflow reference resolves, which cannot be tested from inside this repo.

## Version numbers

While the version is `0.x`:

- a minor bump may break consumers, and says so under Breaking
- a patch bump never does

At 1.0.0, semver applies normally. If the major ever reaches 2, the module path
has to change to `github.com/bradryanbice/hugo-base/v2`, which is a rename of
every import in every site: worth avoiding.

## If a tag is wrong

Do not move it. Tag the fix:

- wrong content, consumers unaffected yet: tag the next patch and note it
- a consumer already on the bad tag: tag the patch and write a migration note
  telling them to move
