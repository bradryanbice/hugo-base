# 0002: Instructions travel with the code, as committed copies

## Context

A shared foundation is more than code: it carries conventions (accessibility,
color, spacing, template structure, maintenance). Those need to reach the
people and agents working in each site, and stay in step with the version that
site actually uses.

## Decision

Conventions live in `agents/rules/` and are copied into each site by
`tools/sync.py`, pinned to the hugo-base version in that site's `go.mod`. CI
fails when a site's copies are stale.

## Consequences

- A Renovate bump carries the new conventions into the same pull request, where
  the diff shows exactly which guidance changed.
- The rules a site follows always describe the code that site has.
- Three path scoped rules load only when the matching files are touched, which
  keeps the always on set small.
- There is a sync step to run, and a check that fails when it has not been.

## Alternatives rejected

Pointing at the module cache: Claude Code treats files outside the repo as
external, prompting for approval, and path scoped rules from outside the repo
do not load at all.

A plugin marketplace: it delivers the latest rules regardless of the version a
site pins, so the rules could describe tokens or partials the site does not
have.

Generating the rules at session start with a hook: invisible in review, and
dependent on tooling being installed.
