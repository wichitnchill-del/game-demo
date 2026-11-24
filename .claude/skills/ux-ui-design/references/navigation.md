# Navigation (navbar / sidebar / menu bar)

## 1. Confirm before building
Nav is easy to get wrong. Before code, show 2 options as ASCII sketches + 1-line reason
each, and ask the user to pick. Ask (if unknown):
- How many top-level items? Any sub-menus?
- Who uses it, on what device (phone, tablet, desktop)?
- Must-have items (logo, search, cart, profile, language, CTA)?
- Reference site they like?

## 2. Pick the pattern

| Situation | Desktop | Mobile |
| --- | --- | --- |
| Website, ≤ 5 links | Top navbar | Hamburger → drawer, or bottom CTA |
| Website, 6–10 links | Top navbar + dropdown / mega menu | Drawer with groups |
| Shop | Top navbar + search + cart | Top bar (search, cart) + drawer |
| App, 3–5 main sections | Sidebar or top tabs | **Bottom nav** (icon + label) |
| Admin, many sections | **Sidebar**, grouped, collapsible | Drawer from top-left button |
| Docs / settings | Sidebar tree + page TOC | Drawer + dropdown section picker |
| Desktop tool | Menu bar (File, Edit…) + toolbar | n/a |

Rules: ≤ 7 top-level items; > 7 → group. Never hide nav behind hamburger on desktop.

## 3. Navbar (top)
- Left: logo (→ home). Center/left: links. Right: search, account, 1 CTA.
- Height 56–64 px; sticky only if pages are long; shrink on scroll is optional.
- Active link: underline/bg + `aria-current="page"`.
- Dropdown opens on click (hover optional on desktop), closes on Esc / outside click.

## 4. Sidebar
- Width 240–280 px; collapsed 64–72 px icons + tooltip.
- Groups with small headings; most-used first; ≤ ~4 per group.
- Active: bg + left bar. Sub-items: one level only, expand/collapse.
- Footer: settings, help, user, sign out. See [admin-dashboard.md](admin-dashboard.md).

## 5. Mobile
- Bottom nav: 3–5 items, icon + label always, thumb zone, safe-area padding.
- Drawer: full height, close (Lucide `x`) + backdrop + swipe; lock page scroll; focus trapped.
- Hamburger only for secondary links when bottom nav exists.
- Targets ≥ 44 px.

## 6. Must work
- Same nav, same place, every page.
- Keyboard: Tab order, Enter/Space open, Esc close, visible focus.
- `<nav aria-label="Main">`; toggle button has `aria-expanded`.
- Route change shows loading ([async-feedback.md](async-feedback.md)).
- Test at 375 / 768 / 1024 / 1440: no wrapping links, no overflow.

## 7. Common mistakes
| Mistake | Fix |
| --- | --- |
| Links wrap to 2 lines at 1024 px | Switch to drawer earlier, or shorten labels |
| Hamburger on desktop | Show links |
| Icon-only nav, no labels | Add labels (tooltips only when collapsed) |
| Too many items | Group, move rare ones to footer/settings |
| Active page not shown | Add active style + `aria-current` |
| Drawer doesn't close / page scrolls behind | Backdrop + Esc + scroll lock |
| Mega menu for 5 links | Plain links |

## 8. daisyUI
`navbar`, `menu` (+ `menu-horizontal`), `dropdown`, `drawer` (+ `lg:drawer-open` for
sidebar that becomes drawer on mobile), `dock` (bottom nav).

```html
<div class="drawer lg:drawer-open">
  <input id="nav" type="checkbox" class="drawer-toggle" />
  <div class="drawer-content">
    <label for="nav" class="btn btn-ghost lg:hidden" aria-label="Open menu"><i data-lucide="menu"></i></label>
    <!-- page -->
  </div>
  <div class="drawer-side">
    <label for="nav" class="drawer-overlay" aria-label="Close menu"></label>
    <nav aria-label="Main"><ul class="menu bg-base-200 w-64 min-h-full p-4">
      <li><a aria-current="page" class="menu-active">ภาพรวม</a></li>
      <li><a>ออเดอร์</a></li>
    </ul></nav>
  </div>
</div>
```
