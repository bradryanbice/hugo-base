#!/usr/bin/env bash
# Fails when the Hugo or Go versions pinned in a site disagree.
#
# Sources checked, relative to the project root (first argument, default "."):
#   mise.toml                 required, the local toolchain
#   netlify.toml              required, HUGO_VERSION and GO_VERSION
#   .github/workflows/*.yml   optional, any HUGO_VERSION or GO_VERSION
# Also compares the installed `hugo version` against mise.toml, including the
# extended edition when mise.toml pins it.
#
# Runs in CI from the hugo-base version a site pins, and locally with
#   bash tools/ci/check-versions.sh [root]
# Written for bash 3.2 so it behaves the same on macOS.

set -euo pipefail

root="${1:-.}"
status=0

fail() {
  echo "::error::$*" >&2
  status=1
}

# Prints the first capture group of an extended regex match in a file.
extract() {
  sed -nE "s/$2/\\1/p" "$1" | head -n 1
}

mise_file="$root/mise.toml"
netlify_file="$root/netlify.toml"

[ -f "$mise_file" ] || { echo "::error::missing $mise_file" >&2; exit 1; }
[ -f "$netlify_file" ] || { echo "::error::missing $netlify_file" >&2; exit 1; }

# Accepts `hugo`, `hugo-extended`, or an explicit aqua backend key.
mise_hugo_re='^[[:space:]]*"?(aqua:gohugoio\/hugo[^"]*|hugo|hugo-extended)"?[[:space:]]*=[[:space:]]*"([^"]+)".*'
mise_hugo_key=$(sed -nE "s/$mise_hugo_re/\\1/p" "$mise_file" | head -n 1)
mise_hugo=$(sed -nE "s/$mise_hugo_re/\\2/p" "$mise_file" | head -n 1)
mise_go=$(extract "$mise_file" '^[[:space:]]*"?go"?[[:space:]]*=[[:space:]]*"([^"]+)".*')

netlify_hugo=$(extract "$netlify_file" '^[[:space:]]*HUGO_VERSION[[:space:]]*=[[:space:]]*"([^"]+)".*')
netlify_go=$(extract "$netlify_file" '^[[:space:]]*GO_VERSION[[:space:]]*=[[:space:]]*"([^"]+)".*')

[ -n "$mise_hugo" ] || fail "no Hugo version found in $mise_file"
[ -n "$netlify_hugo" ] || fail "no HUGO_VERSION found in $netlify_file"
[ "$status" -eq 0 ] || exit "$status"

echo "mise.toml       hugo $mise_hugo ($mise_hugo_key), go ${mise_go:-unset}"
echo "netlify.toml    hugo $netlify_hugo, go ${netlify_go:-unset}"

[ "$mise_hugo" = "$netlify_hugo" ] ||
  fail "Hugo drift: mise.toml has $mise_hugo, netlify.toml has $netlify_hugo"

if [ -n "$mise_go" ] || [ -n "$netlify_go" ]; then
  [ "$mise_go" = "$netlify_go" ] ||
    fail "Go drift: mise.toml has ${mise_go:-unset}, netlify.toml has ${netlify_go:-unset}"
fi

# Workflows are optional. Sites using the reusable workflow carry no version.
for wf in "$root"/.github/workflows/*.yml "$root"/.github/workflows/*.yaml; do
  [ -f "$wf" ] || continue
  wf_hugo=$(extract "$wf" '^[[:space:]]*HUGO_VERSION:[[:space:]]*"?([0-9][^"[:space:]]*)"?.*')
  wf_go=$(extract "$wf" '^[[:space:]]*GO_VERSION:[[:space:]]*"?([0-9][^"[:space:]]*)"?.*')
  if [ -n "$wf_hugo" ]; then
    echo "$(basename "$wf")    hugo $wf_hugo"
    [ "$wf_hugo" = "$mise_hugo" ] ||
      fail "Hugo drift: $wf has $wf_hugo, mise.toml has $mise_hugo"
  fi
  if [ -n "$wf_go" ] && [ -n "$mise_go" ]; then
    [ "$wf_go" = "$mise_go" ] ||
      fail "Go drift: $wf has $wf_go, mise.toml has $mise_go"
  fi
done

# The Hugo actually on PATH must be the pinned one.
if command -v hugo >/dev/null 2>&1; then
  installed=$(hugo version)
  echo "installed       $installed"
  # Official release builds print "v0.166.0-<commit>+extended", Homebrew
  # builds print "v0.166.0+extended". Accept either.
  case "$installed" in
    "hugo v$mise_hugo-"* | "hugo v$mise_hugo+"* | "hugo v$mise_hugo "*) ;;
    *) fail "installed Hugo is not v$mise_hugo: $installed" ;;
  esac
  case "$mise_hugo_key" in
    *extended*)
      case "$installed" in
        *+extended*) ;;
        *) fail "mise.toml pins the extended edition but the installed Hugo is not extended" ;;
      esac
      ;;
  esac
else
  fail "hugo is not on PATH"
fi

[ "$status" -eq 0 ] && echo "Versions agree."
exit "$status"
