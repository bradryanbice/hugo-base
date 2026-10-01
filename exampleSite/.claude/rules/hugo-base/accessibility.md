---
description: Accessibility requirements for every hugo-base site (WCAG 2.2 AA minimum)
---

# Accessibility

This file is managed by hugo-base. Do not edit it inside a site.

WCAG 2.2 AA is the minimum, not a goal. A change that regresses accessibility
does not ship, and CI thresholds are never lowered to make a pull request pass.

## Structure

- One `<header>` banner, one `<main id="main">`, one `<footer>` contentinfo per
  page. Each navigation region is a `<nav>` with an accessible name.
- A skip link is the first focusable element and moves focus to `<main>`.
- Headings form a sensible outline with one `<h1>` per page. Do not skip levels.
- Prefer native HTML semantics over ARIA. Reach for ARIA only when HTML cannot
  express it.
- Mark the current navigation item with `aria-current="page"`.

## Interaction

- Focus is always visible. Use `:focus-visible`, never remove an outline
  without replacing it.
- Everything interactive works by keyboard, in a logical order, with no traps.
- Targets are at least 24 by 24 CSS pixels (SC 2.5.8).
- Motion only inside `@media (prefers-reduced-motion: no-preference)`.
- A scrollable region that can overflow needs `tabindex="0"` and an accessible
  name, so keyboard users can scroll it.

## Content and color

- Text contrast is at least 4.5:1, and 3:1 for large text and UI components.
  This is the site's responsibility when it supplies brand colors: the base
  cannot check values it does not have, so the CI gate checks the built site.
- Never convey meaning by color alone. Add text or an icon with a text label.
- Every image needs `alt`. Decorative images use `alt=""` deliberately. The
  image partial fails the build when `alt` is missing entirely.
- Keep link underlines in running text.
- Text must survive 400 percent zoom at 1280px wide with no horizontal
  scrolling (SC 1.4.10), and respond to user font size settings.

## Checking

Automated tools find roughly a third of real issues. The gate runs axe and
Lighthouse. You still check by hand: keyboard pass, visible focus, 400 percent
zoom, reduced motion. The pull request template lists these.
