# AI Design QA

For UI made or helped by AI (Figma Make, v0, Uizard, LLM HTML/React).
Use AI for structure; humans own subtraction, brand, states, rationale, code quality.

## 1. Generic look (AI signature)

| Signature | Fix |
| --- | --- |
| Bento grid / uniform cards everywhere | Editorial or asymmetric layout |
| Off-white + indigo/violet gradient, or dark + neon | Brand tokens; one purposeful accent |
| Gradient mesh / abstract blob hero | Real photo, brand illustration, crafted solid |
| Default icons + stock 3D | Brand imagery; real photos |
| Same spacing and radius in every section | Vary rhythm by context |
| Hero → logos → features → testimonials → CTA | Content-first; drop what users don't need |

Break it: give AI real brand assets + anti-template rules ("no bento, no gradient").
Flag screens that are very clean/template but low on brand.

## 2. UX defects
- Feature bloat: each screen must earn its content; cut.
- Happy-path only: check empty / loading / error / long content ([async-feedback.md](async-feedback.md)).
- Shallow flows: trace full journey, back nav, modal vs page, steps.

## 3. Execution mistakes
- Thai clipping, bad breaks, overflow → [thai-ui.md](thai-ui.md).
- Optical alignment (e.g. play icon), nested radius = inner + padding, 8-pt spacing.
- Text on image needs a scrim (4.5:1). Red ≠ primary; destructive ≠ primary.
- One icon set, one stroke weight. Targets ≥ 44 px.
- All control states: hover / focus / active / disabled / error.
- Charts must match real numbers.

## 4. Engineering & process
- Reusable components, tokens not hard-coded values, responsive by design.
- Clean code, not bloated output. Keep design rationale.
- Check image/icon licenses.
