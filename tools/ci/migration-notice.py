#!/usr/bin/env python3
"""List the hugo-base migrations a version change crosses.

Usage: python3 migration-notice.py <module dir> <old version> <new version>

Prints a Markdown notice on stdout, or nothing when there is nothing to say.
Exits 0 either way: this informs a pull request, it does not gate it. The gate
is the build, the lint and the sync check, which fail on their own when a
migration has not been applied.

Reads the frontmatter of each migrations/vX.Y.Z.md to decide what to say, so
the notice cannot drift from the notes themselves.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

FRONTMATTER = re.compile(r"^---\s*\n(.*?)\n---", re.S)
HEADING = re.compile(r"^#\s+(.+)$", re.M)


def parse_version(text: str) -> tuple[int, ...] | None:
    found = re.match(r"v?(\d+)\.(\d+)\.(\d+)", text.strip())
    return tuple(int(part) for part in found.groups()) if found else None


def flag(frontmatter: str, key: str) -> bool:
    found = re.search(rf"^{key}:\s*(\S+)", frontmatter, re.M)
    return bool(found) and found.group(1).lower() in ("true", "yes")


def main() -> int:
    if len(sys.argv) != 4:
        sys.exit("usage: migration-notice.py <module dir> <old version> <new version>")
    base, old_raw, new_raw = sys.argv[1], sys.argv[2], sys.argv[3]

    old = parse_version(old_raw)
    new = parse_version(new_raw)
    if not old or not new or new <= old:
        return 0

    directory = Path(base) / "migrations"
    if not directory.is_dir():
        return 0

    crossed = []
    for path in sorted(directory.glob("v*.md")):
        version = parse_version(path.stem)
        if not version or not (old < version <= new):
            continue
        text = path.read_text(encoding="utf-8")
        frontmatter = FRONTMATTER.search(text)
        frontmatter = frontmatter.group(1) if frontmatter else ""
        title = HEADING.search(text)
        crossed.append(
            {
                "file": path.name,
                "version": path.stem,
                "title": title.group(1) if title else path.stem,
                "breaking": flag(frontmatter, "breaking"),
                "automatable": flag(frontmatter, "automatable"),
            }
        )

    if not crossed:
        return 0

    breaking = [m for m in crossed if m["breaking"]]
    lines = [
        f"## hugo-base {old_raw} to {new_raw} crosses "
        f"{len(crossed)} migration{'s' if len(crossed) > 1 else ''}",
        "",
    ]
    if breaking:
        lines += [
            "This bump needs work in this site, not just a version change. "
            "The build, lint and managed file checks will fail until it is done.",
            "",
        ]
    for migration in crossed:
        marks = []
        if migration["breaking"]:
            marks.append("breaking")
        if not migration["automatable"]:
            marks.append("needs a decision")
        suffix = f" ({', '.join(marks)})" if marks else ""
        lines.append(f"- **{migration['version']}**: {migration['title']}{suffix}")
    lines += [
        "",
        "Apply them with the `hugo-base-upgrade` skill, or read them directly:",
        "",
        "```",
        *[f"{m['file']}" for m in crossed],
        "```",
        "",
        "Each note carries its own steps and a verify section.",
    ]
    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    sys.exit(main())
