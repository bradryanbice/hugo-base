# 0004: Config reaches sites through an opt in

## Context

Hugo merges only some configuration categories from a module into a site. The
docs describe `_merge`, but only with a project level example, so it was unclear
whether a module could contribute `markup` or `imaging` at all. If it could not,
every site would carry its own copy of the same defaults.

## Decision

Tested on Hugo 0.166.0 rather than assumed:

- A project level `_merge = "deep"`, at the root or on a category, does pull
  that category from an imported module.
- `_merge` declared inside the module has no effect.

So the base contributes `markup`, `imaging` and `services` defaults, and a site
opts in with one line per category. Root keys are always the site's own.

## Consequences

- Shared defaults live in one place and move with a version bump.
- Three one line files are part of being a hugo-base site.
- The opt in is per category rather than a single root `_merge`, so a later
  release cannot quietly start contributing to `security`, `build` or `privacy`.
- The base contributes nothing for `outputs` and `sitemap`, where Hugo's
  defaults already match, so there is nothing to opt into.

## Note on method

The first probe reported that `imaging` did not merge. That was a bad probe: it
grepped for a pattern anchored to the start of a line while `hugo config`
indents nested tables. Comparing the actual value settled it. Assert on values,
not on the absence of a pattern.
