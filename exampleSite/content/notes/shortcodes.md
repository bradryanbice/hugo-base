---
title: Shortcodes
description: "Every parameter of the figure, callout and table shortcodes, plus a plain Markdown table and one wide enough to scroll."
date: 2026-01-13
tags: ["tooling"]
---

## Callouts

Each type states itself in text, so the meaning does not depend on color.

{{< callout type="note" >}}
A note, with **Markdown** inside and a [link](/about/).
{{< /callout >}}

{{< callout type="tip" >}}
A tip. Body text renders as Markdown, including lists:

- first
- second
{{< /callout >}}

{{< callout type="warning" >}}
A warning, for something that will bite later.
{{< /callout >}}

{{< callout type="danger" title="Do not do this" >}}
A caution, with the label replaced by the `title` parameter.
{{< /callout >}}

## Tables

A plain Markdown table still gets the scrollable, keyboard reachable wrapper.

| Token | Value | Notes |
|---|---:|:---:|
| `--space-1` | 0.5rem | right aligned value, centred notes |
| `--space-2` | 1rem | |

With the shortcode it also gets a caption, which names the scroll region.

{{< table caption="Spacing tokens, with the **caption** rendered as Markdown" >}}
| Token | Value |
|---|---|
| `--space-0h` | 0.25rem |
| `--space-1` | 0.5rem |
{{< /table >}}

A table too wide for a phone, to prove the region scrolls rather than the page.

{{< table caption="A deliberately wide table" >}}
| Column one | Column two | Column three | Column four | Column five | Column six | Column seven |
|---|---|---|---|---|---|---|
| a value here | another value | and another one | more content | still going | nearly there | last column |
| second row | second row | second row | second row | second row | second row | second row |
{{< /table >}}

## Figures

{{< figure src="img/sample.jpg" alt="A diagonal gradient standing in for a photograph" caption="A caption, rendered as **Markdown**." >}}

The same shortcode accepts the parameters Hugo's embedded figure uses, so
content written before adopting hugo-base keeps working.

{{< figure src="img/sample.jpg" alt="A diagonal gradient standing in for a photograph" title="A titled figure" caption="Written with the embedded figure's parameters." attr="Photo by someone" attrlink="https://example.org/" link="/about/" >}}
