Scaffold the module and wire exampleSite

## Summary

Create the minimum viable Hugo Module and a test harness site that imports it from the local checkout, so `hugo build --source exampleSite` succeeds with zero warnings.

## Detailed scope

- `go.mod` declaring `module github.com/bradryanbice/hugo-base` (created with `hugo mod init`).
- Root `hugo.toml` holding module config only: `[module.hugoVersion] min = "0.166.0"`. No `module.mounts`.
- Placeholder templates just sufficient to render: `layouts/baseof.html`, `layouts/home.html`, `layouts/single.html`, `layouts/list.html`. Valid HTML with `lang`, `<title>`, and a `<main>`. No styling yet.
- `exampleSite/` with its own `go.mod`, `config/_default/hugo.toml` importing `github.com/bradryanbice/hugo-base`, and a module replacement pointing at the repo root so no network fetch is needed.
- `exampleSite/content/` with a home page and one regular page.
- `mise.toml` pinning Hugo 0.166.0 and Go 1.27.x.
- `netlify.toml` at repo root that builds `exampleSite` and publishes `exampleSite/public`, with `HUGO_VERSION = "0.166.0"` and `GO_VERSION`.
- `.gitignore` (`public/`, `resources/_gen/`, `.hugo_build.lock`, `node_modules/`).
- `CLAUDE.md` (already drafted), `LICENSE`, stub `README.md`, empty `CHANGELOG.md` with an Unreleased section.

## Design or architecture considerations

- The module uses a single root `hugo.toml` rather than a `config/` directory. Module config should stay small. `exampleSite` uses `config/_default/` because that is the layout `hugo-starter` will ship, so the harness mirrors real consumers.
- Using `module.replacements` (or `HUGO_MODULE_REPLACEMENTS` in CI) is preferred over `themesDir = "../.."`, because the themes-dir trick depends on the clone directory being named `hugo-base`.
- The Netlify site for this repo gives a deploy preview of `exampleSite` on every PR, which is useful for manual review of the base.

## Task checklist

- [ ] `hugo mod init github.com/bradryanbice/hugo-base`
- [ ] Root `hugo.toml` with `hugoVersion.min`
- [ ] Placeholder templates at the `layouts/` root (no `_default/`)
- [ ] `exampleSite` with go.mod, config, replacement, and two content pages
- [ ] `mise.toml`, `netlify.toml`, `.gitignore`
- [ ] `LICENSE`, `README.md` stub, `CHANGELOG.md`
- [ ] Confirm `hugo mod graph --source exampleSite` shows the replacement
- [ ] Create the GitHub repo and connect Netlify

## Acceptance criteria

- `hugo build --source exampleSite --gc --minify --panicOnWarning` exits 0 on a clean clone with no network access to GitHub for the base module.
- `hugo mod graph --source exampleSite` resolves `github.com/bradryanbice/hugo-base` to the local path.
- The three Hugo version strings (netlify.toml, mise.toml, and the version CI will use) read `0.166.0`.
- Netlify deploy preview builds successfully.
- No `layouts/_default/` directory exists.

## Open questions

- Resolved 2026-09-18: `replacements = "github.com/bradryanbice/hugo-base -> ../.."` in `exampleSite/config/_default/module.toml` resolves to the repo root (paths are relative to `exampleSite/themes`). `exampleSite/go.mod` needs no `require` line, and the build succeeds with `GOPROXY=off`. Because `exampleSite/` has its own `go.mod`, Go also leaves it out of the hugo-base module that consumers download.
- The docs say Go is required for Hugo Modules. Is Go present in the Netlify build image by default, or must `GO_VERSION` be set? Alternatively, should consumers vendor with `hugo mod vendor` so Netlify builds never need Go?
- Which Hugo edition does Netlify install when only `HUGO_VERSION` is set (standard or extended)? We should use the same edition in all three places. Standard appears to be enough for our feature set (WebP has been WASM based since v0.153.0, and we use no Sass), but parity matters more than minimalism. Confirm from a Netlify build log.
- Resolved 2026-09-18: the mise registry maps `hugo` to `aqua:gohugoio/hugo` (standard edition) and `hugo-extended` to `aqua:gohugoio/hugo/hugo-extended`. `mise.toml` uses the explicit aqua backend for the extended edition, so it does not depend on registry aliases.
