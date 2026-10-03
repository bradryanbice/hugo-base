#!/usr/bin/env bash
# CSS policy checks for hugo-base and the sites that consume it.
#
# Usage: bash tools/lint/run.sh [--self-test] <dir> [more dirs...]
#   Each dir is a project root containing assets/css. In hugo-base CI those are
#   the repo root and exampleSite; in a site it is the site root.
#   --self-test also lints fixtures/violations.css and requires every rule to
#   fire, which proves the lint is doing something.
#
# Three checks per directory:
#   1. stylelint over the site's styles, CSS and Sass alike
#   2. no site file shadows a hugo-base foundation file
#   3. no file outside tokens/ reads a primitive ramp step directly
#
# A site may write its own styles in Sass. The policy still applies to them,
# which is why .scss is linted rather than ignored: colour is still OKLCH and
# spacing still comes from tokens, whatever compiles them.
#
# A site part way through adopting can exempt paths in .hugo-base-lint-ignore,
# one glob per line with a reason after a #. Exemptions are printed on every
# run, so an unchecked path stays visible rather than becoming the status quo.
#
# Node comes from mise. Hugo and Chrome are not needed.
# Written for bash 3.2 so it behaves the same on macOS.

set -euo pipefail

self_test="no"
dirs=""
for arg in "$@"; do
  case "$arg" in
    --self-test) self_test="yes" ;;
    -*) echo "::error::unknown option: $arg" >&2; exit 2 ;;
    *) dirs="$dirs $arg" ;;
  esac
done
[ -n "$dirs" ] || { echo "usage: run.sh [--self-test] <dir> [more dirs...]" >&2; exit 2; }

here=$(cd "$(dirname "$0")" && pwd)
base=$(cd "$here/../.." && pwd)
manifest="$base/tools/managed-files.toml"
status=0

# The module cache is read only, so install somewhere writable.
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
cp "$here"/package.json "$here"/package-lock.json "$here"/stylelint.config.mjs "$workdir"/
echo "Installing lint tooling"
(cd "$workdir" && npm ci --no-audit --no-fund --loglevel=error)

# Run stylelint from the directory being linted, with relative globs. The
# config's overrides match on path, and those patterns do not match absolute
# paths outside the config's own directory.
stylelint_in() {
  target_dir="$1"
  shift
  (cd "$target_dir" && "$workdir/node_modules/.bin/stylelint" --config "$workdir/stylelint.config.mjs" "$@")
}

# Paths a site must not shadow, read from the manifest so there is one list.
protected_paths=$(python3 - "$manifest" <<'PY'
import sys, tomllib
from pathlib import Path
data = tomllib.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
for path in data.get("protected", {}).get("paths", []):
    print(path)
PY
)

for dir in $dirs; do
  [ -d "$dir" ] || { echo "::error::no such directory: $dir" >&2; status=1; continue; }
  dir=$(cd "$dir" && pwd)
  name=$(basename "$dir")
  echo
  echo "== $name"

  # Exemptions, printed so they cannot quietly become permanent.
  ignore_file="$dir/.hugo-base-lint-ignore"
  ignore_args=""
  if [ -f "$ignore_file" ]; then
    echo "exemptions from .hugo-base-lint-ignore:"
    while IFS= read -r line; do
      case "$line" in
        ""|\#*) continue ;;
      esac
      pattern=${line%%#*}
      reason=${line#*#}
      pattern=$(echo "$pattern" | tr -d ' ')
      [ -n "$pattern" ] || continue
      echo "  $pattern  ($(echo "$reason" | sed 's/^ *//'))"
      ignore_args="$ignore_args --ignore-pattern $pattern"
    done < "$ignore_file"
  fi

  style_count=$(find "$dir/assets" \( -name '*.css' -o -name '*.scss' \) -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$style_count" = "0" ]; then
    echo "no styles to lint"
  else
    echo "stylelint: $style_count file(s), CSS and Sass"
    # shellcheck disable=SC2086
    # --allow-empty-input: a site that has exempted everything, or has no styles
    # of its own yet, is not an error. The exemptions are printed above either
    # way, which is the point.
    if ! stylelint_in "$dir" --allow-empty-input $ignore_args "assets/**/*.css" "assets/**/*.scss"; then
      echo "::error::stylelint failed in $name" >&2
      status=1
    fi
  fi

  # A site must not carry its own copy of a foundation file. Skip the base,
  # which is where those files legitimately live.
  if [ ! -f "$dir/tools/managed-files.toml" ]; then
    # Globbing off: a pattern like assets/css/foundation/** must stay literal.
    # With globbing on, the shell expands it against the current directory, so
    # the check would silently test nothing in a site that has no such files.
    set -f
    for path in $protected_paths; do
      case "$path" in
        */\*\*)
          if [ -d "$dir/${path%/**}" ]; then
            echo "::error::$name has its own $path, which hugo-base owns" >&2
            status=1
          fi
          ;;
        *)
          if [ -f "$dir/$path" ]; then
            echo "::error::$name has its own $path, which hugo-base owns" >&2
            status=1
          fi
          ;;
      esac
    done
    set +f
  fi

  # Primitive ramp steps belong to the token files. Everything else uses the
  # semantic names, so a theme change cannot miss a hard coded step.
  if [ -d "$dir/assets/css" ]; then
    offenders=$(grep -rlE 'var\(--(neutral|accent)-[0-9]+' "$dir/assets/css" 2>/dev/null | grep -v '/css/tokens/' || true)
    if [ -n "$offenders" ]; then
      echo "::error::these files use a primitive ramp step instead of a semantic token:" >&2
      echo "$offenders" >&2
      status=1
    fi
  fi
done

if [ "$self_test" = "yes" ]; then
  echo
  echo "== self test"
  cp -R "$here/fixtures" "$workdir"/
  # stylelint writes its report to stderr when the run errored, so both streams
  # are captured. Reading only stdout here would make this test always pass.
  report=$(stylelint_in "$workdir" --formatter json "fixtures/violations.css" "fixtures/violations.scss" 2>&1 || true)
  for rule in \
    color-no-hex \
    color-named \
    function-disallowed-list \
    scale-unlimited/declaration-strict-value \
    declaration-no-important \
    declaration-property-value-disallowed-list \
    csstools/use-logical
  do
    if printf '%s' "$report" | grep -q "\"$rule\""; then
      echo "ok   $rule fired on the fixtures"
    else
      echo "::error::$rule did not fire on the fixtures, so the lint is not enforcing it" >&2
      status=1
    fi
  done

  # And specifically that Sass is covered: a site writing .scss must not be
  # silently exempt from the policy.
  if printf '%s' "$report" | grep -q "violations.scss"; then
    echo "ok   the policy fires on .scss as well as .css"
  else
    echo "::error::no finding in fixtures/violations.scss: Sass is not being linted" >&2
    status=1
  fi
fi

echo
if [ "$status" -eq 0 ]; then
  echo "CSS policy checks passed."
else
  echo "CSS policy checks failed." >&2
fi
exit "$status"
