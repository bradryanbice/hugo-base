#!/usr/bin/env bash
# Checks that hugo-base's test harness still exercises the override paths.
#
# Usage: bash tools/ci/check-harness.sh <path to built exampleSite>
#
# Everything a consuming site is allowed to override has a demonstration in
# exampleSite. Those are easy to delete by accident, and nothing else would
# notice: the build would stay green while the override mechanism went
# untested. Each one leaves a marker in the output, and this asserts they are
# all there.
#
# Written for bash 3.2 so it behaves the same on macOS.

set -euo pipefail

public="${1:?usage: check-harness.sh <path to built exampleSite>}"
[ -d "$public" ] || { echo "::error::no such directory: $public" >&2; exit 2; }
status=0

check() {
  # check <description> <file> <extended regex>
  # Patterns must tolerate both quoted and unquoted attributes: the production
  # build minifies, which strips quotes where it can.
  if grep -qE "$3" "$public/$2" 2>/dev/null; then
    echo "ok   $1"
  else
    echo "::error::$1: expected $3 in $2" >&2
    status=1
  fi
}

# A site themes itself by overriding tokens/theme.css. exampleSite sets a teal
# accent, so the built CSS must carry its hue rather than the base's default.
css=$(ls "$public"/css/main*.css 2>/dev/null | head -1 || true)
if [ -n "$css" ] && grep -q "accent-hue: 195" "$css"; then
  echo "ok   theme inputs override (tokens/theme.css)"
else
  echo "::error::theme inputs override: expected the site's accent hue in the built CSS" >&2
  status=1
fi

check "hook override (hooks/body-end.html)" "index.html" 'data-hugo-base-hook="?body-end'
check "partial override (head/icons.html)" "index.html" 'rel="?icon'
check "section layout override (layouts/notes/single.html)" "notes/third/index.html" 'data-site-override="?notes-single'

# And the fixtures that cover behaviour rather than overrides.
check "noindex fixture" "private-note/index.html" 'name="?robots'
check "image pipeline fixture" "notes/with-images/index.html" '<picture>'
check "shortcode fixtures" "notes/shortcodes/index.html" 'class="?table-wrap'
check "pagination fixture" "notes/index.html" 'class="?pagination'

if [ -d "$public/notes/a-draft" ]; then
  echo "::error::draft fixture was published: draft handling has regressed" >&2
  status=1
else
  echo "ok   draft fixture stayed unpublished"
fi

echo
if [ "$status" -eq 0 ]; then
  echo "Harness coverage intact."
else
  echo "Harness coverage check failed." >&2
fi
exit "$status"
