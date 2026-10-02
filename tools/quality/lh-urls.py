#!/usr/bin/env python3
"""Pick the pages Lighthouse should audit, and print them one per line.

Usage: python3 lh-urls.py <built site> <base url> [limit]

Lighthouse CI's own directory discovery picks an arbitrary handful of pages. On
this site it sampled six and missed the one with images entirely, so nothing was
gating image weight, responsive sources or layout shift. This chooses
deliberately instead:

  the home page and 404, which every site has
  one page per top level section, so each template is represented
  every page carrying an image, because that is where weight, layout shift and
  responsive sizing regress

Capped, because each page costs a full Lighthouse run. Images come first in the
cap, since they are the risk this exists to cover.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

HAS_IMAGE = re.compile(r"<(?:picture|img)[\s>]", re.I)
ALIAS = re.compile(r"""<meta[^>]+http-equiv=["']?refresh["']?""", re.I)


def main() -> int:
    if len(sys.argv) < 3:
        sys.exit("usage: lh-urls.py <built site> <base url> [limit]")
    root = Path(sys.argv[1]).resolve()
    base = sys.argv[2].rstrip("/")
    limit = int(sys.argv[3]) if len(sys.argv) > 3 else 8

    with_images: list[str] = []
    sections: dict[str, str] = {}
    always: list[str] = []

    for path in sorted(root.rglob("*.html")):
        html = path.read_text(encoding="utf-8", errors="replace")
        if ALIAS.search(html):
            continue
        rel = path.relative_to(root)
        if rel.name == "index.html":
            url = "/" + str(rel.parent).replace(".", "").strip("/")
            url = url if url.endswith("/") else url + "/"
            url = "/" if url == "//" else url
        else:
            url = "/" + str(rel)

        if url in ("/", "/404.html"):
            always.append(url)
            continue
        if HAS_IMAGE.search(html):
            with_images.append(url)
            continue
        top = url.strip("/").split("/")[0]
        sections.setdefault(top, url)

    ordered = always + with_images + list(sections.values())
    seen: list[str] = []
    for url in ordered:
        if url not in seen:
            seen.append(url)

    for url in seen[:limit]:
        print(base + url)
    return 0


if __name__ == "__main__":
    sys.exit(main())
