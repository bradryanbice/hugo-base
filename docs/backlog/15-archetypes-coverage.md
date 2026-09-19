Archetypes and full exampleSite coverage

## Summary

Add shared archetypes and make `exampleSite` a complete test harness that renders every template, partial, shortcode, hook, and override path in the base.

## Detailed scope

- `archetypes/default.md`: title from the file name, date, `draft: true`, `description`, `images` placeholder.
- Optional bundle archetype `archetypes/bundle/index.md` for page bundles with images.
- exampleSite additions:
  - A "kitchen sink" page for every shortcode and Markdown feature.
  - Override demonstrations: theme inputs, one partial, one hook, one section specific layout.
  - A multi page section, a taxonomy with terms, a page with `noindex`, a draft that must not publish.
- Enable `--printUnusedTemplates` (and `--printPathWarnings`) in CI under `--panicOnWarning`, so an untested template fails the build.

## Design or architecture considerations

- The harness is the test suite. If CI cannot see a template rendered, a Hugo bump can break it silently in consumers. Unused template warnings turn coverage into a build failure.
- Archetypes merge through the unified file system, so a site's `archetypes/default.md` replaces ours entirely.

## Task checklist

- [ ] Archetypes
- [ ] Kitchen sink and override demo pages
- [ ] Taxonomy, pagination, noindex, draft fixtures
- [ ] Turn on unused template and path warnings in CI
- [ ] Fix any coverage gaps revealed

## Acceptance criteria

- `hugo new content posts/test.md --source exampleSite` produces front matter from the base archetype.
- CI is green with `--printUnusedTemplates --panicOnWarning`.
- Each override demonstration is visibly in effect in the built output.

## Open questions

- Does `--printUnusedTemplates` report embedded templates or templates only meant to be overridden (empty hooks)? If so, exampleSite must call every hook, or we need a documented exception list.
