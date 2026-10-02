---
title: Typography specimen
description: Every Markdown construct the base styles, so the gate checks heading order, contrast and reflow on real prose.
layout: typography
---

This page is the typography fixture. It exercises every element the foundation
styles, in the order a reader would meet them, so a change to the type scale or
the prose rhythm shows up here first.

## A second level heading

Body text sits on a measure of about 65 characters, which is where lines stay
easy to track. This paragraph exists to run past one line so the leading and the
ragged edge are both visible. It also carries [a link in running text](/about/),
which keeps its underline because color alone would fail SC 1.4.1, and
[a visited link](https://example.org/visited-probe) for comparison.

### A third level heading

Short paragraph after a third level heading.

#### A fourth level heading

Text under a fourth level heading, with **bold**, *italic*, `inline code`, and
a longer run of `code_with_an_extremely_long_identifier_that_must_wrap_rather_than_scroll`.

## Punctuation

Hugo's typographer would normally turn two hyphens into an en dash and three
into an em dash. The base maps both back to themselves, so dash handling leaves
what an author typed alone: ranges like 10--20 stay as typed, and so does a
parenthetical --- like this one. Smart quotes still apply, as does an
ellipsis...

## Lists

An unordered list:

- First item
- Second item, long enough to wrap onto a second line so the hanging indent is
  visible against the marker
- Third item with a nested list:
  - Nested first
  - Nested second

An ordered list:

1. Install the toolchain
2. Build the site
3. Run the gate

## Quotes

> A blockquote, set off by a border rather than by italics, because long runs of
> italic text are harder to read.
>
> It can hold more than one paragraph.

## Code

A fenced block, which wraps rather than scrolling sideways:

```sh
hugo build --source exampleSite --gc --minify --panicOnWarning
bash tools/quality/run.sh exampleSite/public
```

```css
/* Long lines wrap, so the page still reflows at 400 percent zoom. */
.example { background-image: linear-gradient(to right, var(--color-accent-subtle), var(--color-surface-raised)); }
```

## A table

| Token | Value | Notes |
|---|---|---|
| `--space-1` | 0.5rem | 8px, the base step |
| `--space-0h` | 0.25rem | the only half step |
| `--text-base` | clamp | fluid between two rem bounds |

## A horizontal rule

---

And a final paragraph after the rule, to show the spacing on both sides.
