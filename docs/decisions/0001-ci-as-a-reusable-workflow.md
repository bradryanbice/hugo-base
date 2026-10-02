# 0001: CI reaches sites as a reusable workflow

## Context

Hugo Modules distribute content, layouts and assets. They do not distribute
`.github/`, so the CI gate cannot ride along with the module. Options were:
copy the workflow into each site through the starter template, call a reusable
workflow, use composite actions, run a template sync bot, or keep CI in a
separate repository.

## Decision

A reusable workflow in this repo, which each site calls with a short file. The
toolchain comes from the calling site's `mise.toml`, and the checks themselves
are read from the hugo-base version that site pins in `go.mod`, located with
`hugo config mounts`.

## Consequences

- A fix to a check reaches a site when it bumps hugo-base, in step with the code
  that check tests.
- The workflow carries no Hugo version, so there is one less place to drift.
- A reusable workflow runs in the caller's context, so it cannot read this
  repo's files by relative path. Reading them from the located module solved
  that, and turned out better: the checks match the site's pinned version.
- Config for the checks lives in the module too, rather than being inlined.

## Alternatives rejected

Copying the workflow drifts, which is the problem being solved. A separate CI
repository adds a second version to track for no gain yet, and remains an
option if CI changes start outpacing base releases.
