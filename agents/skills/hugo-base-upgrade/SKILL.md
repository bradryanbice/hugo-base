---
name: hugo-base-upgrade
description: Upgrade this site's hugo-base version, refresh its managed files, and apply the migration notes for the versions being crossed. Use when a Renovate pull request bumps hugo-base, when the managed file check fails, or when adopting hugo-base for the first time.
disable-model-invocation: true
---

# Upgrade hugo-base

This skill is managed by hugo-base. Do not edit it inside a site.

Work in order. Each step tells you what to do when it fails, and the last
section lists the things you must not decide alone.

## 1. Find out where the site is

```sh
grep hugo-base go.mod
hugo version
git status --short
```

Stop and say so if the working tree is dirty: an upgrade mixed with unrelated
edits is impossible to review. Record the current version, call it OLD.

## 2. Move the module

For a Renovate pull request, the bump is already in `go.mod`, so skip to step 3.
Otherwise:

```sh
hugo mod get github.com/bradryanbice/hugo-base@latest
hugo mod tidy
```

Never run `go mod tidy` in a Hugo site. There is no Go code, so it would remove
the hugo-base requirement. If you have already run it, restore `go.mod` from
git and use `hugo mod tidy`.

Record the new version, call it NEW.

## 3. Refresh the managed files

```sh
./hugo-base.sh sync
```

This rewrites the shared rules, the CI caller workflow, the pull request
template, the editorconfig and the stub itself, from the version the site now
pins. Review the diff: it shows exactly which conventions changed in this
upgrade, and it is the reason the sync is part of the same pull request.

If the stub is missing (a first adoption), run the sync from the module
directory, as `migrations/v0.1.0.md` describes.

## 4. Read the migrations in range

Find the module on disk and list the notes between OLD and NEW:

```sh
base=$(./hugo-base.sh path)
ls "$base/migrations"
```

Read every `vX.Y.Z.md` greater than OLD and less than or equal to NEW, in
ascending order. Read all of them before changing anything: a later migration
sometimes supersedes an earlier one.

For each, apply the Steps section exactly. The steps name paths and give search
commands; run those rather than guessing which files are affected. Steps are
written to be safe to run twice, so a partially applied migration is fine to
re-run.

If a migration is marked `automatable: false`, it contains at least one
decision that is not yours to make. Do that migration's mechanical steps, then
stop and ask about the rest. Do not invent a brand color, delete a template
whose purpose is unclear, or decide that a site is an exception.

## 5. Verify, in this order

```sh
hugo build --gc --minify --panicOnWarning
./hugo-base.sh sync --check
./hugo-base.sh lint
./hugo-base.sh quality public
```

Each one has to pass before the next means anything: a failed build leaves a
stale `public/`, so the quality gate would be checking the previous output.

What failures usually mean:

| Failure | Cause |
|---|---|
| a deprecation in the build log | Hugo renamed something; the message names the replacement |
| `is unused` | a template nothing renders, often one the base now provides |
| `sync --check` still failing | step 3 was skipped, or a managed file was edited in the site |
| CSS policy lint | a new rule in this version; its migration note explains it |
| `has no alt text` | an image needs alt text, and the error names the page |
| `cannot find ... not in static/` | an image needs moving into the page bundle or `assets/` |
| contrast failure | this site's brand colors do not clear the threshold at these steps |

Fix the causes. Never silence a check or lower a threshold to get green: in
this project a passing gate is the only evidence anything works.

## 6. Report

Say plainly:

- OLD to NEW, and which migrations were in range
- what changed in the site, file by file
- which rule files changed text, since that is what will govern later work
- anything you skipped, and why
- anything that needs a human decision, as a specific question

If the upgrade is not finished, say that rather than describing it as done.

## What you must not decide alone

- A brand color, hue, chroma or font.
- Whether one of the site's templates is genuinely site specific or should be
  deleted in favour of the base's.
- Whether this site is an exception to a shared rule. If a rule does not fit,
  that is a hugo-base issue, not a local override.
- Anything a migration marks as needing a decision.
