## What this changes

<!-- One or two sentences. Link the issue: Closes #N -->

## Accessibility check

Automated tools catch roughly a third of WCAG issues, so CI passing is not
enough. Tick what you checked, and say why if something does not apply.

- [ ] Keyboard only: every control reachable and operable, focus order logical, no traps
- [ ] Focus visible on every focusable element
- [ ] Zoom to 400 percent at 1280px wide: no horizontal scrolling, nothing clipped
- [ ] Reduced motion honored (emulate it in DevTools)
- [ ] Headings form a sensible outline, landmarks are correct
- [ ] Images have meaningful alt text, or an explicit empty alt when decorative

## Checks

- [ ] `bash tools/ci/build.sh exampleSite` is clean
- [ ] `bash tools/quality/run.sh exampleSite/public` passes
- [ ] exampleSite exercises whatever this change adds
- [ ] `CHANGELOG.md` updated, and `CLAUDE.md` or the shared rules if a convention changed
- [ ] No en or em dashes in prose
