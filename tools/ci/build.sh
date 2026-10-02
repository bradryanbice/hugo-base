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
# It also fails on a duplicate output path, and, when
# HUGO_BASE_TEMPLATE_COVERAGE=1, on a template nothing renders.

set -euo pipefail

source_dir="${1:?usage: build.sh <source> [hugo flags...]}"
shift

log=$(mktemp)
trap 'rm -f "$log"' EXIT

set +e
# Template coverage is only meaningful for hugo-base's own harness, where every
# template the module ships must be exercised or CI cannot vouch for it. In a
# consuming site an unused base template is normal: a site with no images does
# not render the image hook, and failing its build for that would be absurd.
# So it is opt in, via HUGO_BASE_TEMPLATE_COVERAGE=1.
#
# --printPathWarnings stays on everywhere: two pages claiming one output path
# is a real error in any site.
coverage_flags=""
if [ "${HUGO_BASE_TEMPLATE_COVERAGE:-0}" = "1" ]; then
  coverage_flags="--printUnusedTemplates"
fi

# shellcheck disable=SC2086
hugo build \
  --source "$source_dir" \
  --gc \
  --minify \
  --panicOnWarning \
  $coverage_flags \
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
