---
name: hugo-base-upgrade
description: Upgrade this site's hugo-base version, refresh its managed files, and apply the migration notes for the versions being crossed. Use when a Renovate pull request bumps hugo-base, or when the sync check fails.
disable-model-invocation: true
---

# Upgrade hugo-base

This skill is managed by hugo-base. Do not edit it inside a site.

Note: the full procedure arrives with hugo-base issue #16, which adds the
`migrations/` notes this skill applies. Until then, do the following and tell
the user that migration notes are not yet available.

1. Read the current version: `grep hugo-base go.mod`.
2. Update it:

   ```sh
   hugo mod get github.com/bradryanbice/hugo-base@latest
   hugo mod tidy
   ```

   Never run `go mod tidy` here.
3. Refresh the managed files: `./hugo-base.sh sync`.
4. Run the checks and fix what fails:

   ```sh
   hugo build --gc --minify --panicOnWarning
   ./hugo-base.sh sync --check
   ```
5. Summarize what changed, including any rule file whose text changed, and
   flag anything that needs a human decision.
