# 0005: No JavaScript in the base

## Context

The sites are content: articles, statistics, reference pages. A shared
foundation could ship JavaScript for a navigation toggle, a theme switch, or
progressive niceties.

## Decision

The base ships none. Every page works with JavaScript disabled, and the
navigation wraps on small screens rather than collapsing behind a toggle.

## Consequences

- Nothing to load, nothing to break, no hydration and no flash of unstyled
  content.
- The CI byte budget for scripts stays near zero, which keeps it meaningful.
- A disclosure based mobile menu is off the table for now. Wrapping is less
  fashionable and entirely usable.
- If JavaScript is added later it must enhance a page that already works, and
  load deferred.

## Alternatives considered

A `<details>` element can make a menu without JavaScript, but screen reader
behaviour for a disclosure used as navigation is inconsistent enough that a
wrapping list is the better default.
