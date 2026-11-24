# Design System & Handoff

Token, component and handoff reference.

## Design tokens

- **Primitives → semantics**: raw color/spacing/typography scales mapped to
  semantic roles (bg, surface, text, primary, success, warning, danger, border).
- Token categories: colour, typography (type scale + roles), spacing, radius,
  shadow, motion, breakpoints.
- Output formats: JSON / CSS custom properties / Tailwind tokens.

## Components

- Inventory: name, variants, sizes, states, props, anatomy.
- States: default / hover / focus / active / disabled / loading / error / success.
- Per-component accessibility requirements (focus order, labels, contrast, hit area).

## Handoff package

Deliverables the skill produces per design:

- [ ] Frames / prototype (Figma link or HTML/CSS prototype)
- [ ] Design tokens (JSON / CSS / Tailwind)
- [ ] Component specs + code snippets
- [ ] Copy / microcopy deck
- [ ] Asset list (icons, illustrations, photos with usage rights)
- [ ] Redlines / acceptance criteria with dev

## Dev-ready snippet types

- CSS / design-token values
- React/Vue component API sketch (variants, states, a11y props)

If implementation is in scope later, keep the token/component contract stable so
frontend work maps 1:1 to design decisions.
