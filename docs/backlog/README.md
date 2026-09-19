# v0.1.0 backlog

One file per issue. The file name is the order. The first line of each file is the issue title. Everything after the first blank line is the body.

Order principle: get a green build and a real gate first (01 to 04), put the propagation mechanism in place before there is much to propagate (05), then add features under the gates so the repo stays green.

| # | Title | Depends on |
|---|-------|------------|
| 01 | Scaffold the module and wire exampleSite | none |
| 02 | CI build gate: build, deprecations, dash lint, version drift | 01 |
| 03 | Renovate preset: one grouped PR per Hugo release | 02 |
| 04 | Quality gate: axe and Lighthouse CI, proven to fail | 02 |
| 05 | Shared rules and managed file sync | 02 |
| 06 | CSS foundation and token architecture | 04, 05 |
| 07 | Typography | 06 |
| 08 | CSS policy lint and protected paths | 06 |
| 09 | Page shell: landmarks, skip link, header, nav shell, footer | 07 |
| 10 | Content layouts: home, single, list, taxonomy, term, 404 | 09 |
| 11 | Head, SEO, and structured data partials | 10 |
| 12 | Config defaults, markup, sitemap, RSS, robots | 10 |
| 13 | Image processing pipeline | 10 |
| 14 | Shortcodes: figure, callout, table | 13 |
| 15 | Archetypes and full exampleSite coverage | 14 |
| 16 | Migrations and the upgrade skill | 05, 08 |
| 17 | Consumer documentation and CHANGELOG | 15, 16 |
| 18 | Release v0.1.0 and consumption smoke test | 03, 17 |

Every feature issue from 06 onward also updates the matching file in `agents/rules/`, so the shared instructions grow with the code.

Suggested labels: `infra`, `ci`, `a11y`, `css`, `templates`, `seo`, `docs`, `agents`, `release`. Suggested milestone: `v0.1.0`.

To create them once the GitHub repo exists (run from this directory):

```sh
for f in [0-9][0-9]-*.md; do
  gh issue create --repo bradryanbice/hugo-base \
    --title "$(head -n 1 "$f")" \
    --body "$(tail -n +3 "$f")" \
    --milestone v0.1.0
done
```
