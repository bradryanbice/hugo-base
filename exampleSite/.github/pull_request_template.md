<!-- Managed by hugo-base. Do not edit: change it in the hugo-base repo. -->

## What this changes

<!-- One or two sentences. -->

## Accessibility check

Automated tools catch roughly a third of WCAG issues, so a green build is not
enough. Tick what you checked, and say why if something does not apply.

- [ ] Keyboard only: every control reachable and operable, focus order logical, no traps
- [ ] Focus visible on every focusable element
- [ ] Zoom to 400 percent at 1280px wide: no horizontal scrolling, nothing clipped
- [ ] Reduced motion honored (emulate it in DevTools)
- [ ] Headings form a sensible outline, landmarks are correct
- [ ] Images have meaningful alt text, or an explicit empty alt when decorative

## Checks

- [ ] `hugo build --gc --minify --panicOnWarning` is clean
- [ ] `./hugo-base.sh sync --check` passes
- [ ] `./hugo-base.sh quality` passes against the built site
- [ ] No foundation file from hugo-base has been copied into this site
