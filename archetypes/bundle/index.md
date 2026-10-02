---
title: '{{ replace .File.ContentBaseName "-" " " | title }}'
date: {{ .Date }}
draft: true
description: ''
---

A page bundle: this file plus its images in the same directory. Reference an
image by its file name, and the pipeline handles sizes, formats and dimensions.

![What the image shows](photo.jpg)
