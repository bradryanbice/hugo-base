Migrations and the upgrade skill

## Summary

When hugo-base changes a convention, consuming sites must not just get new rules, they must change their code to comply. Ship versioned, instruction-style migration notes and a Claude Code skill that applies them during an upgrade.

## Detailed scope

- `migrations/` directory, one file per release that needs action in consuming sites: `migrations/v0.2.0.md`. Frontmatter: `version`, `breaking` (bool), `automatable` (bool). Sections: Why, What changed, Steps (imperative, specific file paths and search patterns), Verify (commands and what passing looks like).
- `agents/skills/hugo-base-upgrade/SKILL.md` (synced into sites by issue 05), `disable-model-invocation: true`:
  1. Read the current hugo-base version from `go.mod`.
  2. `hugo mod get github.com/bradryanbice/hugo-base@<target>` (or latest), then `hugo mod tidy`.
  3. `./hugo-base.sh sync`.
  4. Read every migration file after the old version, up to and including the target, from the module directory. Apply the steps in order.
  5. Run build, CSS lint, protected path check, and sync check. Fix what fails.
  6. Summarize what changed and anything that needs a human decision.
- `CHANGELOG.md` links each release to its migration file.
- Reusable workflow: when `go.mod` changes the hugo-base version and a migration in range is marked `breaking`, post a PR comment listing the migrations to run.
- Deferred (see the decision below): a workflow in each site that runs the skill automatically on Renovate PRs that bump hugo-base, using the Claude Code GitHub Action, and pushes the result to the PR branch.

## Design or architecture considerations

- The full loop for a convention change: edit the rule in `agents/rules/`, add or tighten the lint in `tools/lint/`, and write `migrations/vX.Y.Z.md`, all in one hugo-base PR. Release. Renovate opens a PR in each site. CI fails on the stale sync and on new lint violations. The upgrade skill (by hand or automated) brings the site into compliance in that same PR.
- Migration files are written for Claude and humans alike, so they should be concrete: exact paths, before and after snippets, and a verify step. Vague migrations produce inconsistent results across sites.
- A commit pushed by a workflow using the default `GITHUB_TOKEN` does not trigger new workflow runs. Automated fixes on Renovate PRs need a GitHub App token or a PAT so CI re-runs on the fixed commit.

- Known item for the adoption migration: existing sites probably set `languageCode` (and maybe `languageDirection` or `languageName`). These were deprecated in v0.158.0 in favour of `locale`, `direction` and `label`, and the strict build gate fails on them.

## Task checklist

- [ ] Migration file format and a template
- [ ] `migrations/v0.1.0.md` describing adoption for an existing site (the first real migration)
- [ ] Upgrade skill
- [ ] PR comment step in the reusable workflow
- [ ] Rehearse on exampleSite: fake a v0.0.x to v0.1.0 upgrade and let the skill run it

## Acceptance criteria

- On a branch pinned to an older hugo-base, running `/hugo-base-upgrade` leaves the site green with every managed file current and every migration applied.
- A migration marked `breaking` produces a PR comment on the bump PR.
- The adoption migration is detailed enough for another session to move one existing site (for example playoffsbracket) onto the base.

## Open questions

- Decided 2026-09-18: run the upgrade skill by hand for now. Revisit automation on Renovate PRs after the migration format has proved itself on two or three releases. The automation task in the checklist is deferred.
- Should `automatable: false` migrations block automated runs entirely and require a human?
- Where does adoption guidance for the existing five sites live: a single `migrations/v0.1.0.md`, or a separate adoption guide per site? Recommend one generic migration, with site-specific notes kept in each site's repo.
