---
description: Maintaining a hugo-base site: toolchain pins, managed files, Renovate PRs, local checks
---

# Maintenance

This file is managed by hugo-base. Do not edit it inside a site.

## Toolchain pins must agree

The Hugo version appears in `mise.toml` and `netlify.toml`, and in a workflow
only if that site pins one. They must always match, and CI fails when they do
not. Go is pinned the same way. Never change one by hand without the others:
Renovate opens a single grouped pull request per release.

```sh
mise install     # get the pinned toolchain
```

## Managed files

These paths are owned by hugo-base and overwritten by the sync tool. Do not
edit them in a site:

- `.claude/rules/hugo-base/*`
- `.claude/skills/*` that came from hugo-base
- `.github/workflows/ci.yml`
- `.github/pull_request_template.md`
- `.editorconfig`
- `hugo-base.sh`
- `.hugo-base-managed` (the record of what is managed)

Site specific guidance goes in `.claude/rules/site/*.md`, which the sync tool
never touches. A rule you want to change for every site is a hugo-base change.

```sh
./hugo-base.sh sync           # refresh managed files from the pinned version
./hugo-base.sh sync --check   # what CI runs: fails if anything is stale
```

## Configuration

Hugo does not merge most config categories from a module into a site, so the
base's defaults only apply where the site opts in. These three files, each
containing one line, are part of a hugo-base site:

```toml
# config/_default/markup.toml, imaging.toml, services.toml
_merge = "deep"
```

Add a key to one of them only to differ from the base. Anything else belongs
upstream.

Root keys never merge: `baseURL`, `title`, `locale`, `copyright`,
`enableRobotsTXT` and `disableHugoGeneratorInject` are always the site's own.
`outputs`, `sitemap`, `taxonomies` and `pagination` are the site's too, because
the base contributes nothing there.

Pair `noindex: true` in front matter with `sitemap.disable: true`. The gate
fails when a noindex page is still listed in the sitemap.

## Updating hugo-base

```sh
hugo mod get github.com/bradryanbice/hugo-base@latest
hugo mod tidy
./hugo-base.sh sync
```

Never run `go mod tidy` in a Hugo site. There is no Go code, so it would drop
the hugo-base requirement. Use `hugo mod tidy`.

Read the hugo-base `CHANGELOG.md` for the versions you are crossing. A release
with a migration note needs those steps applied: run the `hugo-base-upgrade`
skill, or follow the notes by hand.

## A Renovate pull request

1. Let CI run. The gate builds the site, checks the toolchain pins, runs axe
   and Lighthouse, and verifies the managed files are current.
2. If the sync check fails, run `./hugo-base.sh sync` and commit the result in
   that same pull request. That is how new conventions arrive.
3. If a new lint fails, read the migration note for the version being crossed.
4. Merge only when it is green. Never lower a CI threshold to get there.

## Local checks before pushing

```sh
hugo build --gc --minify --panicOnWarning      # the build CI runs
./hugo-base.sh lint                            # CSS policy and protected paths
./hugo-base.sh quality                         # axe and Lighthouse on public/
```
