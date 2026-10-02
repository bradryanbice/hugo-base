---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: {{ .Date }}
draft: true
description: ''
# Add tags if this site uses them, and remove the ones it does not.
# tags: []
---

Write the page here. A few things the base expects:

- `description` is used for the meta description, social cards and the card on
  list pages, so write it for a reader.
- An image goes in a page bundle next to the page, and needs alt text. Use
  `![What the image shows](photo.jpg)` or the `figure` shortcode.
- Remove `draft: true` to publish. Drafts are excluded from builds, so CI does
  not check them.
