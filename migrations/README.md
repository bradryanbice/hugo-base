# Migrations

One file per release that needs work in a consuming site. A release that needs
nothing has no file.

A migration is read by a person or by the `hugo-base-upgrade` skill, so it has
to be concrete: exact paths, exact search patterns, before and after, and a way
to tell when it is done. A vague migration produces a different result in every
site, which is worse than none.

## Format

File name: `vX.Y.Z.md`, matching the release tag.

```markdown
---
version: v0.2.0
breaking: true      # does a site break if this is not applied
automatable: true   # can the steps be applied without a human decision
---

# One line saying what changed

## Why

The reason, briefly. A migration nobody understands gets skipped.

## What changed

The actual change, with before and after.

## Steps

1. Imperative, specific, with the command or search pattern to run.

## Verify

What to run, and what passing looks like.

## If something does not fit

What to do when a site is a genuine exception.
```

## Rules

- Write steps in the order they must happen. If step 3 fails because step 2 was
  skipped, say so in step 3.
- Give a search command (`grep -rn ...`) rather than "find all uses".
- Prefer steps that are safe to run twice: a site may have applied some by hand.
- Say what a step cannot decide. "Choose a hue for your brand" is a human
  decision, and the skill must stop and ask rather than invent one.
- `breaking: true` means the site fails to build, or renders incorrectly,
  without the migration. The CI gate posts a notice on a pull request that
  crosses a breaking migration.
- Every release with a migration is linked from `CHANGELOG.md`.
