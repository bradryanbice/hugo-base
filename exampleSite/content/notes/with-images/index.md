---
title: Images
description: "Page bundle fixtures for the image pipeline: a photograph, a transparent PNG, an SVG and a decorative image."
date: 2026-01-12
tags: ["tooling"]
---

A Markdown image goes through the pipeline, so it gets responsive sizes, a WebP
alternative, and width and height attributes that stop the page shifting as it
loads.

![A diagonal gradient standing in for a photograph](photo.jpg)

With a title, the same image becomes a figure with a real caption rather than a
title attribute that touch users never see.

![A diagonal gradient standing in for a photograph](photo.jpg "The caption is rendered as Markdown, so it can contain a [link](/about/).")

Transparency survives: this PNG is a circle on nothing, not a circle on white.

![A teal circle on a transparent background](transparent.png)

An SVG passes through untouched, because resizing a vector is pointless and
Hugo cannot process it anyway.

![The hugo-base mark](mark.svg)
