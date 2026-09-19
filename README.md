# hugo-base

A shared Hugo Module holding the layouts, CSS foundation, partials and
conventions used by every site in this family. Sites import it, override
individual files by placing their own copy at the same path, and update it
with a version bump.

Status: pre-release, working toward v0.1.0. Not ready for use yet.

## Requirements

- Hugo 0.166.0 or later (extended edition, pinned in `mise.toml`)
- Go 1.27 or later (Hugo Modules use it to fetch modules)
- [mise](https://mise.jdx.dev/) to install the pinned toolchain

## Developing

```sh
mise install
hugo server --source exampleSite
hugo build --source exampleSite --gc --minify --panicOnWarning
```

`exampleSite/` is the test harness. It imports this module from the local
checkout, so changes show up immediately.

## Renovate

`renovate/hugo.json` is a shared preset. It keeps the Hugo and Go versions in
`mise.toml`, `netlify.toml` and any workflow `HUGO_VERSION` or `GO_VERSION`
identical, and opens one grouped PR per release. It also groups a site's
hugo-base module bump with its reusable CI workflow ref.

A site uses it by adding this to its `renovate.json`:

```json
{
  "extends": ["config:recommended", "github>bradryanbice/hugo-base//renovate/hugo"]
}
```

Extending by reference (recommended) means fixes to the preset reach every
site immediately. Copying `renovate/hugo.json` into a site also works, because
it contains nothing specific to this repo, but copies drift.

Never enable Renovate's `gomodTidy` option in a hugo-base site. There is no Go
code, so `go mod tidy` would remove the hugo-base requirement.

Consumer documentation (importing, overriding, theming, updating) arrives
before v0.1.0.
