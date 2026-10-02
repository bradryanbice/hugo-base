---
title: A page kept out of search results
description: Carries noindex and sitemap.disable together, so the head contract check has something to verify.
noindex: true
sitemap:
  disable: true
---

Pages like this exist on most sites: a thank you page, a preview, an internal
reference. The base emits `noindex, follow` for them, and the gate checks that
such a page is not advertised in the sitemap either.
