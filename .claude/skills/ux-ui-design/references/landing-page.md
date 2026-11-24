# Landing Page

## 1. Ask first (max 3)
- Goal: sell / collect leads / app sign-up / event / portfolio
- Who + their main worry
- Brand assets (logo, colors, photos)

## 2. Structure by goal

| Goal | Sections |
| --- | --- |
| Sell product | Hero → problem → product → proof → price → FAQ → CTA |
| Leads | Hero + form → benefits → proof → form again |
| App / SaaS | Hero + screenshot → 3 features → how it works → proof → pricing → CTA |
| Event | Hero (date, place) → agenda → speakers → register |
| Portfolio | Hero (who + what) → work → about → contact |

Cut any section that doesn't help the goal.
Then show an ASCII wireframe (desktop + mobile) and get OK before building ([ux-process](ux-process.md#phase-4--wireframe-gate)).

## 3. Hero rules
- Headline: the value, ≤ 8 words. Subline ≤ 20 words.
- 1 primary CTA (verb, ≤ 3 words) + max 1 secondary.
- Real product/photo, not abstract blobs.
- Understandable in 5 seconds.

## 4. Convert
- Proof near CTAs: logos, numbers, real reviews (never invented).
- Answer the top worry (price, trust, time) on the page.
- Repeat CTA every 2–3 sections.
- No nav links that leak away from the goal.

## 5. Look (avoid the AI template)
- Theme from [theme-selection.md](theme-selection.md).
- Distinct type pairing; one accent color.
- Vary layout rhythm (full-bleed, split, editorial) — not card grids everywhere.
- Motion only for attention or feedback; respect reduced motion.

## 6. Ship
- Images: WebP/AVIF, sized, lazy below fold. LCP < 2.5 s.
- `<title>`, meta description, OG image.
- Mobile first: 375 px CTA visible without scroll.
- Output: one HTML file from [build-html](build-html.md); verify with [ship-checklist](ship-checklist.md).
