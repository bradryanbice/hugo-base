#!/usr/bin/env bash
# Accessibility and Lighthouse gate for a built Hugo site.
#
# Usage: bash tools/quality/run.sh <path to built site> [--skip-self-test]
#   REPORT_DIR  where to write reports (default: a temp directory)
#
# Steps:
#   1. install the pinned tooling (copied out of the module, which is read only)
#   2. serve the built site locally
#   3. run axe over every URL in the site's sitemap, and check the semantic
#      color token contract, in both light and dark mode
#   4. run Lighthouse CI with the assertions in lighthouserc.json
#   5. self test: serve a deliberately broken page and require axe to fail on it
#
# Chrome comes from the machine. No browser is downloaded.
# Written for bash 3.2 so it behaves the same on macOS.

set -euo pipefail

public="${1:?usage: run.sh <path to built site> [--skip-self-test]}"
shift || true
skip_self_test="no"
for arg in "$@"; do
  case "$arg" in
    --skip-self-test) skip_self_test="yes" ;;
    *) echo "::error::unknown argument: $arg" >&2; exit 2 ;;
  esac
done

[ -d "$public" ] || { echo "::error::no such directory: $public" >&2; exit 2; }
public=$(cd "$public" && pwd)
[ -f "$public/sitemap.xml" ] || { echo "::error::no sitemap.xml in $public" >&2; exit 2; }

here=$(cd "$(dirname "$0")" && pwd)
report_dir="${REPORT_DIR:-$(mktemp -d)}"
mkdir -p "$report_dir"

# The module directory may be read only (the Go module cache), so work on a copy.
workdir=$(mktemp -d)
cp -R "$here"/. "$workdir"/

pids=""
cleanup() {
  for pid in $pids; do
    kill "$pid" 2>/dev/null || true
    # Reap the job so the shell does not print a "Terminated" notice.
    wait "$pid" 2>/dev/null || true
  done
  rm -rf "$workdir"
}
trap cleanup EXIT

free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
}

serve() {
  # serve <directory> <port>
  python3 -m http.server "$2" --bind 127.0.0.1 --directory "$1" >/dev/null 2>&1 &
  pids="$pids $!"
  curl --silent --show-error --fail --retry 30 --retry-delay 1 --retry-connrefused \
    --output /dev/null "http://127.0.0.1:$2/" || {
    echo "::error::local server for $1 did not start" >&2
    exit 1
  }
}

echo "Installing quality tooling"
(cd "$workdir" && npm ci --no-audit --no-fund --loglevel=error)

site_port=$(free_port)
serve "$public" "$site_port"

# Both color schemes, because the semantic tokens differ between them and a
# dark mode contrast regression would otherwise ship unnoticed.
for scheme in light dark; do
  echo
  echo "Running axe over the sitemap ($scheme mode)"
  node "$workdir/axe.mjs" \
    --base "http://127.0.0.1:$site_port" \
    --sitemap "$public/sitemap.xml" \
    --color-scheme "$scheme" \
    --report "$report_dir/axe-$scheme.json"

  echo
  echo "Checking the semantic color contract ($scheme mode)"
  node "$workdir/contrast.mjs" \
    --url "http://127.0.0.1:$site_port/" \
    --color-scheme "$scheme" \
    --report "$report_dir/contrast-$scheme.json"
done

echo
echo "Running Lighthouse CI"
"$workdir/node_modules/.bin/lhci" autorun \
  --config="$workdir/lighthouserc.json" \
  --collect.staticDistDir="$public" \
  --upload.outputDir="$report_dir/lighthouse"

if [ "$skip_self_test" = "no" ]; then
  echo
  echo "Self test: axe must fail on a deliberately broken page"
  fixture_port=$(free_port)
  serve "$workdir/fixtures" "$fixture_port"
  node "$workdir/axe.mjs" \
    --base "http://127.0.0.1:$fixture_port" \
    --url /violation.html \
    --expect-violations
fi

echo
echo "Quality gate passed. Reports in $report_dir"
