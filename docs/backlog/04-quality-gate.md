Quality gate: axe and Lighthouse CI, proven to fail

## Summary

Run axe and Lighthouse CI against every page of the built site, and prove the gate fails when an accessibility regression is introduced.

## Detailed scope

- A `quality` job in `site-ci.yml` that downloads the built `public/` artifact and serves it statically.
- axe: run against every URL in the generated `sitemap.xml` (tags `wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa`). Any violation fails the job.
- Lighthouse CI (`@lhci/cli`) with `staticDistDir`, a URL list covering one page per template, and assertions:
  - `categories:accessibility` minScore 1 (error)
  - `categories:best-practices` and `categories:seo` minScore 0.95 (error)
  - `categories:performance` as a warning only, with resource budgets (CSS and HTML bytes) as errors
- `package.json` and `package-lock.json` holding only CI dev dependencies (`@lhci/cli`, the axe runner). These are test tooling, not a site build step.
- A negative fixture: `exampleSite/content/_ci/axe-fixture.md` built only when an environment variable is set, containing a known violation (image with no alt text, bypassing the partial). A CI step builds with the fixture enabled and asserts that axe exits non-zero.
- Reports uploaded as artifacts.

## Design or architecture considerations

- Lighthouse performance scores are noisy on shared runners. Gating on byte budgets is deterministic; gating on scores would cause flaky red builds on Hugo bump PRs and erode trust in the gate.
- Lighthouse accessibility runs a subset of axe. Running axe directly on every sitemap URL is the real a11y gate. Lighthouse adds SEO and best practices.
- Automated tools find roughly a third of WCAG issues. Keyboard and screen reader checks remain manual and are listed in the PR template.
- Consumers get this job automatically via the reusable workflow. It will fail a consumer whose brand colors break contrast, which is the intended enforcement point for brand values the base cannot see.

## Task checklist

- [ ] `package.json` with pinned CI tools, lockfile committed
- [ ] Static server step
- [ ] axe over all sitemap URLs
- [ ] `lighthouserc` with assertions and budgets
- [ ] Negative fixture and the step that asserts failure
- [ ] Report artifacts
- [ ] `.github/pull_request_template.md` with a manual a11y checklist (keyboard pass, focus visible, zoom to 400 percent, reduced motion)

## Acceptance criteria

- The job is green on `main`.
- The negative fixture step proves axe fails on a known violation (the step passes only if axe fails).
- Removing the focus ring, or setting a semantic text token to a low contrast value, turns CI red.
- Performance score variance does not fail the build.

## Open questions

- Which axe runner: `@axe-core/cli` (needs a browser driver), `pa11y-ci` with the axe runner (reads sitemaps natively), or Playwright plus `@axe-core/playwright`? Recommend `pa11y-ci` for sitemap support unless it lags axe-core versions.
- Where the Lighthouse and axe configs live: recommend `tools/quality/` in the module, read from the module directory located with `hugo config mounts` (see issue 02), with an optional override file in the consuming site. Confirm this works when the module comes from the remote cache and not a local replacement.
- Sitemap URLs use `baseURL`. The CI build must use a local `baseURL` (for example `http://localhost:8080/`) so the URLs point at the static server. Confirm this does not alter anything else the gate checks.
