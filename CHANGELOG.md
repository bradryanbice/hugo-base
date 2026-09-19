# Changelog

All notable changes to hugo-base are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[semantic versioning](https://semver.org/). While the version is 0.x, a minor
release may contain breaking changes, listed under a Breaking heading.

## Unreleased

### Added

- Module scaffold: `go.mod`, module config with `hugoVersion.min = "0.166.0"`, and placeholder `baseof`, `home`, `single` and `list` templates.
- `exampleSite` test harness importing the module from the local checkout.
- Hugo version pinned in `mise.toml` and `netlify.toml`.
- MIT license.
- Reusable CI gate `.github/workflows/site-ci.yml` for hugo-base and consuming sites: toolchain from `mise.toml`, Hugo and Go version drift check, optional dash lint, strict build that fails on warnings and deprecations, built site uploaded as an artifact.
- `tools/ci/` scripts behind the gate, runnable locally.
- Shared Renovate preset `renovate/hugo.json`: one grouped PR per Hugo release and per Go release across `mise.toml`, `netlify.toml` and workflows, and hugo-base module plus CI workflow bumps grouped together. Validated in CI.
- Node pinned in `mise.toml` for CI tooling.
