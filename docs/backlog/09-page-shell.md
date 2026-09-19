Page shell: landmarks, skip link, header, nav shell, footer

## Summary

Build `baseof.html` with correct landmark structure and the shared shell partials, all overridable, with no navigation content in the base.

## Detailed scope

- `layouts/baseof.html`: `<html lang>` from the site language, `dir` attribute, head partial, skip link, header, `<main id="main" tabindex="-1">` wrapping the `main` block, footer, and `body-end` hook.
- `layouts/_partials/site/skip-link.html`: first focusable element, visually hidden until focused, text from i18n.
- `layouts/_partials/site/header.html`: banner landmark with a site title link (text from `site.Title`) and a `site/logo.html` seam that renders nothing by default.
- `layouts/_partials/site/nav.html`: renders `site.Menus.main` if present, as `<nav aria-label>` with a list, `aria-current="page"` on the active item, and nested children as nested lists. Renders nothing when no menu exists.
- `layouts/_partials/site/footer.html`: contentinfo landmark, copyright line from params, optional `footer` menu.
- Hook partials that render nothing by default: `hooks/head-end.html`, `hooks/body-start.html`, `hooks/body-end.html`, `hooks/header-end.html`, `hooks/footer-start.html`. Sites put analytics and extras here.
- `i18n/en.toml` holding all UI strings (skip link, nav labels, "page X of Y", "read more").
- Layout CSS in the `layout` layer: header and footer arrangement with container queries, nav that wraps without JS.
- exampleSite: a `main` and `footer` menu in its config, and an override of `hooks/body-end.html` to prove hooks work.

## Design or architecture considerations

- Navigation content is out of scope. The base only renders whatever menu the site defines.
- No JavaScript. The nav wraps on narrow viewports rather than collapsing behind a toggle. A `<details>` disclosure is possible without JS but has screen reader quirks when used as a menu. Recommend plain wrapping for v0.1.0.
- Hooks are empty partials with stable names. That is the extension API, and renaming them is a breaking change.
- `tabindex="-1"` on `<main>` ensures the skip link moves focus in all browsers, not only scroll position.
- `menus` config merges shallowly from modules, so the base must not define any menu entries or they would leak into every site.

## Task checklist

- [ ] `baseof.html` with landmarks
- [ ] Skip link
- [ ] Header, logo seam, nav, footer partials
- [ ] Hook partials
- [ ] `i18n/en.toml`
- [ ] Layout CSS with container queries
- [ ] exampleSite menus and a hook override

## Acceptance criteria

- axe landmark rules pass. Exactly one banner, main, and contentinfo per page.
- Pressing Tab once on any page focuses the skip link. Enter moves focus into `<main>`.
- Active menu item has `aria-current="page"`, including for section pages under a menu entry.
- With no menu defined, no empty `<nav>` is rendered.
- Every string a user can see comes from i18n.

## Open questions

- Should the nav partial treat section ancestors as active (`.IsMenuCurrent` versus `.HasMenuCurrent`) and mark them with `aria-current="true"` rather than `"page"`?
- Multilingual: any consumer planning more than English? If so, the header needs a language switcher seam now, and the new `sites` matrix (v0.153.0) may matter.
