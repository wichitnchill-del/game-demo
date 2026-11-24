# UI / Visual Design

Deep reference for visual craft: typography, color, spacing, components, layout,
motion.

## Typography

- Type scale (suggest: 12 / 14 / 16 / 20 / 24 / 30 / 36 / 48 or similar), ratio ~1.25–1.33.
- Body text ≥ 16px (12px minimum for dense data UI), line-height 1.5–1.6.
- Headline / body / caption roles explicit; one type family or pairing with clear roles.
- Line length ~45–75 characters for readability.

## Color

- Primitive palette → semantic tokens (bg, surface, text, text-muted, primary,
  success, warning, danger, border, overlay).
- Contrast: 4.5:1 normal text, 3:1 large text / UI components (WCAG AA).
- Brand accent usage rules (1 primary accent, semantic colors for states).

## Spacing

- 8-point grid; spacing scale e.g. 4 / 8 / 12 / 16 / 24 / 32 / 48 / 64.
- Whitespace is a hierarchy tool; don't arbitrarily mix pixel values.

## Components & states

- Buttons: primary / secondary / ghost / danger; sizes sm/md/lg; states
  default / hover / focus / active / disabled / loading / error / success.
- Form inputs: label, hint, error, success; validation timing (on blur/on submit).
- Feedback: toast / inline / modal per urgency; auto-dismiss timing.
- Data display: empty / loading / error / success states for lists, tables, dashboards.

## Layout & responsive

- Mobile-first breakpoints: 375, 768, 1024, 1440 CSS px.
- Grid: 12-col or product-specific; consistent gutters.
- Touch targets ≥ 44 px (skill default; AA floor 24 px, see [accessibility](accessibility.md)); visible focus indicators.

## Motion

- Purpose: feedback, hierarchy, continuity — not decoration.
- Duration ~150–300ms for UI; easing ease-out; respect `prefers-reduced-motion`.

See [accessibility.md](accessibility.md) and [design-system-handoff.md](design-system-handoff.md).
