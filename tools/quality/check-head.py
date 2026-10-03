#!/usr/bin/env python3
"""Check the document head contract on every built page.

Usage: python3 tools/quality/check-head.py <path to built site>

Static checks, so they are cheap and need no browser. For every HTML page:

  exactly one <title> in <head>, and it is not empty
  exactly one canonical link in <head>
  a meta description in <head>
  exactly one <h1> in the document
  every JSON-LD block parses as JSON and has @context and @type
  a page with noindex is not listed in sitemap.xml

Redirect stubs that Hugo writes for aliases are skipped.

A browser cannot catch most of these: Lighthouse samples one page, and axe does
not look at the head at all. Standard library only.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

TITLE = re.compile(r"<title[^>]*>(.*?)</title>", re.S | re.I)
CANONICAL = re.compile(r"""<link[^>]+rel=["']?canonical["']?[^>]*>""", re.I)
DESCRIPTION = re.compile(r"""<meta[^>]+name=["']?description["']?[^>]*>""", re.I)
H1 = re.compile(r"<h1[\s>]", re.I)
LD_JSON = re.compile(
    r"""<script[^>]+type=["']?application/ld\+json["']?[^>]*>(.*?)</script>""", re.S | re.I
)
NOINDEX = re.compile(r"""<meta[^>]+name=["']?robots["']?[^>]*noindex""", re.I)
# Hugo writes alias pages (a paginator's /page/1/, a moved URL) as redirect
# stubs. They have no head of their own and no content, so the contract does
# not apply to them.
ALIAS = re.compile(r"""<meta[^>]+http-equiv=["']?refresh["']?""", re.I)
HEAD_END = re.compile(r"</head>", re.I)


def main() -> int:
    if len(sys.argv) != 2:
        sys.exit("usage: check-head.py <path to built site>")
    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        sys.exit(f"error: no such directory: {root}")

    sitemap = (root / "sitemap.xml").read_text(encoding="utf-8") if (root / "sitemap.xml").is_file() else ""
    problems: list[str] = []
    checked = 0

    for path in sorted(root.rglob("*.html")):
        rel = path.relative_to(root)
        # 404 has no canonical URL of its own and is not in the sitemap.
        is_404 = rel.name == "404.html"
        html = path.read_text(encoding="utf-8", errors="replace")
        if ALIAS.search(html):
            continue
        checked += 1

        # Scope the head checks to the head. An inline SVG carries its own
        # <title> as its accessible name, which is correct practice, and
        # counting those reported a duplicate title on every page with a logo.
        end = HEAD_END.search(html)
        head = html[: end.start()] if end else html

        titles = [t.strip() for t in TITLE.findall(head)]
        if len(titles) != 1 or not titles[0]:
            problems.append(f"{rel}: expected one non-empty <title>, found {len(titles)}")

        if not is_404:
            canonicals = CANONICAL.findall(head)
            if len(canonicals) != 1:
                problems.append(f"{rel}: expected one canonical link, found {len(canonicals)}")

        if not DESCRIPTION.search(head):
            problems.append(f"{rel}: no meta description")

        h1s = H1.findall(html)
        if len(h1s) != 1:
            problems.append(f"{rel}: expected one <h1>, found {len(h1s)}")

        for block in LD_JSON.findall(html):
            try:
                data = json.loads(block)
            except json.JSONDecodeError as error:
                problems.append(f"{rel}: JSON-LD does not parse: {error}")
                continue
            if not isinstance(data, dict):
                problems.append(
                    f"{rel}: JSON-LD parsed as {type(data).__name__}, not an object. "
                    "In a <script> element the value needs safeJS, or the template "
                    "escaping emits it as a quoted string."
                )
                continue
            for key in ("@context", "@type"):
                if key not in data:
                    problems.append(f"{rel}: JSON-LD is missing {key}")

        # A page kept out of search results should not be advertised either.
        if NOINDEX.search(head) and sitemap:
            url_path = "/" + str(rel.parent).replace(".", "").strip("/")
            if url_path != "/":
                url_path += "/"
            if f"{url_path}</loc>" in sitemap:
                problems.append(
                    f"{rel}: has noindex but is listed in sitemap.xml. "
                    "Set sitemap.disable in front matter as well."
                )

    print(f"Checked the head contract on {checked} page(s).")
    if problems:
        print("", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        print(f"\n::error::{len(problems)} head contract problem(s)", file=sys.stderr)
        return 1
    print("Head contract holds.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
