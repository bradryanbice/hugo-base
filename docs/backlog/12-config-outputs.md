Config defaults, markup, sitemap, RSS, robots

## Summary

Decide and implement how shared configuration (outputs, markup, imaging, sitemap, robots) reaches consuming sites, given that most config categories do not merge from modules.

## Detailed scope

- Establish the config contract. Per the current docs, module config merges into the site only for `params` (deep), `menus`, `mediaTypes`, and `outputFormats` (shallow). `outputs`, `markup`, `imaging`, `sitemap`, `taxonomies`, `pagination`, and root keys such as `enableRobotsTXT` default to `none`.
- Write the recommended site config fragment in `exampleSite/config/_default/` that `hugo-starter` will copy: `outputs`, `markup`, `sitemap`, `enableRobotsTXT`, `pagination`.
- Sitemap: use Hugo's embedded sitemap template. Exclude pages with `noindex` via front matter `sitemap.disable`.
- RSS: embedded template unless a change is needed. Decide full content versus summary and the item limit (`services.rss.limit`).
- `layouts/robots.txt`: allows all, references the sitemap, and disallows everything when `hugo.Environment` is not `production` (so Netlify deploy previews are not indexed).
- Markup defaults in the fragment: Goldmark settings, heading ids, and the typographer decision below.

## Design or architecture considerations

- If config cannot flow from the module, the starter owns config and the base owns templates. That is a clean split, but it means config changes in later base releases require manual changes in each site. The docs show that a project can opt in with `_merge = "deep"` per category. If that works for module provided config, sites can inherit markup and imaging defaults from the base.
- Hugo's Goldmark typographer converts `--` to an en dash and `---` to an em dash by default. That conflicts with the no dash rule for anything the base or its docs render.
- The robots template branching on environment keeps deploy previews out of search results without per-site config.

## Task checklist

- [ ] Experiment: in exampleSite, set `_merge = "deep"` on `markup`, `imaging`, and `outputs` and confirm whether values from the base's `hugo.toml` apply
- [ ] Record the result in the README config contract
- [ ] Recommended config fragment in exampleSite
- [ ] `robots.txt` template with environment branching
- [ ] Sitemap and RSS verified in built output
- [ ] Typographer decision implemented

## Acceptance criteria

- `public/sitemap.xml`, `public/index.xml`, and `public/robots.txt` exist and are valid.
- Building with `--environment staging` produces a robots.txt that disallows all.
- The README documents exactly which config a consuming site must carry itself.
- The experiment result is recorded, with the Hugo version tested.

## Open questions

- Does `_merge = "deep"` set in the project config actually pull `markup`, `imaging`, and `outputs` values from an imported module, or only from themes? The docs describe it for "themes and modules" but give only a project level example. Needs a test, not a guess.
- Can the module declare `_merge` in its own config for its own categories, or is `_merge` honored only in the project? If only in the project, the starter must carry it.
- Typographer: disable `ndash` and `mdash` substitutions in the recommended markup config (so `--` stays literal), or leave content rendering to each site? Recommend disabling in the base's recommended fragment.
- The docs mark "omitting category names in component files" as new in v0.162.0. Confirm how `config/_default/params.toml` and similar files should be written for v0.166.0 so the starter template is correct.
