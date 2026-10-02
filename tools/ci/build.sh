#!/usr/bin/env bash
# Strict production build. Fails on any warning and on any deprecation notice.
#
# Usage: bash tools/ci/build.sh <source> [extra hugo flags...]
#
# Hugo reports a new deprecation at INFO level for several releases before it
# becomes a WARN, so --panicOnWarning alone would catch it late. This script
# builds at INFO level and fails if the log mentions a deprecation, which turns
# a future Hugo bump red as soon as a deprecation appears.
#
# It also fails on an unused template or a duplicate output path, both of which
# Hugo reports as warnings under the flags below.

set -euo pipefail

source_dir="${1:?usage: build.sh <source> [hugo flags...]}"
shift

log=$(mktemp)
trap 'rm -f "$log"' EXIT

set +e
# --printUnusedTemplates turns template coverage into a build failure: a
# template nothing renders is a template CI cannot vouch for, and a Hugo
# upgrade could break it silently in a consuming site. --printPathWarnings
# catches two pages claiming the same output path.
hugo build \
  --source "$source_dir" \
  --gc \
  --minify \
  --panicOnWarning \
  --printUnusedTemplates \
  --printPathWarnings \
  --logLevel info \
  "$@" 2>&1 | tee "$log"
build_status=${PIPESTATUS[0]}
set -e

if [ "$build_status" -ne 0 ]; then
  echo "::error::hugo build failed with status $build_status" >&2
  exit "$build_status"
fi

if grep -inw 'deprecated' "$log" >&2; then
  echo "::error::the build log reports a deprecation (lines above)" >&2
  exit 1
fi

echo "Build clean: no warnings, no deprecations."
