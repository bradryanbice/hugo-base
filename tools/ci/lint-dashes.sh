#!/usr/bin/env bash
# Fails if any tracked text file contains an en dash (U+2013) or an em dash
# (U+2014). Use commas, periods, or parentheses instead.
#
# Usage: bash tools/ci/lint-dashes.sh [pathspec...]   (default: whole repo)
# Must run inside a git work tree. Binary files are skipped.

set -euo pipefail

# Byte sequences, because bash 3.2 (macOS) does not understand \u escapes.
en_dash=$(printf '\342\200\223')
em_dash=$(printf '\342\200\224')

if [ "$#" -eq 0 ]; then
  set -- .
fi

if git grep -n -I -F -e "$en_dash" -e "$em_dash" -- "$@"; then
  echo "::error::en or em dashes found (lines above). Use commas, periods, or parentheses." >&2
  exit 1
fi

echo "No en or em dashes found."
