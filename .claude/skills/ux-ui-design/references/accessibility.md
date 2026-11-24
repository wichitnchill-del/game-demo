# Accessibility

Reference: WCAG 2.2 AA checklist applied during design (phase 6) and critique. Single source for target sizes and a11y severity.

## Four principles

1. **Perceivable** — info must be presentable to senses (text alternatives, captions, contrast, non-text contrast).
2. **Operable** — users can navigate & interact (keyboard, focus, timing, seizures, input).
3. **Understandable** — content & operation intelligible (language, predictability, errors, input assistance).
4. **Robust** — works with assistive tech / browsers (semantics, ARIA where needed).

## Concrete AA checks

### Perceivable
- Text contrast ≥ 4.5:1 (normal), ≥ 3:1 (large text ≥ 18.66px bold or 24px regular, and UI components).
- Non-text contrast ≥ 3:1 for UI boundaries/focus indicators.
- Alt text / text alternatives for images, icons, charts (data tables for charts).
- Captions + transcripts for audio/video; audio not alone.
- Sensory info not conveyed by single cue (e.g., color-only).
- 200 % text zoom without loss (1.4.4).
- Reflow at 320 CSS px with no horizontal scroll (1.4.10).
- 1.4.13 Tooltips/hover content: dismissible with Esc, hoverable, stays until moved away.

### Operable
- Full keyboard operation; visible focus indicator (≥ 2px, high contrast); logical focus order.
- No keyboard traps; skip link / landmark navigation.
- Targets: 24×24 CSS px = AA floor (2.5.8; or 24 px spacing; inline text links exempt). 44 px = skill default for touch. 48 px = busy places, tablets, older adults. daisyUI 5 default `btn`/`input` = 40 px -> override in [build-html](build-html.md).
- Timing: no auto-* that can't be paused/stopped; allow extend; avoid flashing > 3 Hz.

### Understandable
- Plain, readable language. `<html lang="th">`; `lang="en"` on English phrases inside Thai pages (3.1.2).
- Predictable: same action → same result; no unexpected context changes.
- Errors: identified (text), described, suggested fix, in text (not just color/icon).
- Input assistance: labels, instructions, help, defaults.

### Robust
- Semantic HTML / ARIA roles correct; screen-reader friendly reading order.
- 4.1.3 Status messages: `aria-live="polite"` on toast/saving region, `role="alert"` for errors ([async-feedback](async-feedback.md)).

### New in 2.2 (A/AA), triggered by this skill's patterns
- 2.4.11 Focus Not Obscured: sticky header, bottom bar or cookie banner must not cover the focused field -> `scroll-padding` on html / `scroll-margin` on fields.
- 2.5.7 Dragging: every drag or swipe has a click alternative (sheet has a close button, reorder has up/down buttons, calendar drag has [ย้ายเวลา]).
- 3.2.6 Consistent Help: help/contact (LINE OA, phone) in the same place on every page.
- 3.3.7 Redundant Entry: don't ask again for data already given (autofill, 'ใช้ที่อยู่จัดส่ง').
- 3.3.8 Accessible Authentication: allow paste and password managers, no cognitive puzzles; OTP field `autocomplete="one-time-code"` ([auth](auth.md)).

## Severity

Use P0–P3 from [ui-audit](ui-audit.md#step-3--rate-each-finding). AA fail on the core path = P0; AA fail elsewhere = P1.

| # | Sev | Where | Criterion (e.g. 2.4.11) | Issue | Fix |
| --- | --- | --- | --- | --- | --- |

## Methods

- Automated: axe DevTools, Lighthouse (they miss many issues).
- Manual: keyboard pass, screen reader (VoiceOver iOS/macOS, TalkBack, NVDA), 200 % zoom, 320 px reflow, colour-blind sim; steps in [ship-checklist](ship-checklist.md).
- Validate with users incl. disabled/assistive-tech users when possible.

Full process context: [ux-process](ux-process.md).
