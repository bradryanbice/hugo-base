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

Consumer documentation (importing, overriding, theming, updating) arrives
before v0.1.0.
