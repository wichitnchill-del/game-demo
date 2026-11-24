# Full UI Audit — "Is this UI fit for its use?"

Runs when the user asks to check / audit / review a UI as a whole (ตรวจ UI, ตรวจสอบ UI
ทั้งหมด, เช็คว่าเหมาะกับการใช้งานไหม, UX audit, design review). Judge **fitness for use**
(does it serve *these* users doing *this* task) — not personal taste.

## Step 0 — Establish context first (no context, no verdict)

| Need | Source |
| --- | --- |
| What the product does, primary task(s) | user, README, landing copy |
| Who uses it (age, expertise, device, environment) | user, analytics, brief |
| Business goal / success metric | user, stakeholders |
| Constraints (brand, platform, framework e.g. daisyUI/Tailwind) | code, config |

Ask max 3 questions if unknown; otherwise infer and label every inference **[assumed]**.

## Step 1 — Gather the UI (use what exists, in this order)

1. **Running app / URL** → open in the browser tool; screenshot each key screen at
   375 / 768 / 1024 / 1440 px; walk the main tasks by clicking, not just looking.
2. **Code** → list routes/pages, components, theme config (`data-theme`, `@plugin "daisyui"`),
   hard-coded colors, missing states.
3. **Figma / screenshots** → audit what is shown; flag unseen states as *not verified*.

Build an inventory: screens × states (default / empty / loading / error / success) ×
breakpoints. Gaps in this grid are findings.

## Step 2 — Audit 10 dimensions

| # | Dimension | Check | Reference |
| --- | --- | --- | --- |
| 1 | **Task fit** | Can the primary task be done in the fewest steps? Is the main action the most prominent thing? | ux-process.md |
| 2 | **Audience fit** | Type size, contrast, density, language match the users (e.g. older adults → larger text, higher contrast; experts → density, shortcuts) | design-principles.md |
| 3 | **IA & navigation** | Users know where they are, where to go, how to go back | ux-process.md |
| 4 | **Flows & states** | Empty / loading / error / success exist for every critical flow; every click that waits shows pending feedback (no silent login, no form closing before save, no data pop-in, no double submit) — test on throttled network; destructive actions confirm; undo exists | async-feedback.md |
| 5 | **Heuristics** | Krug/Nielsen heuristics; Fitts / Hick / Miller | design-principles.md |
| 6 | **Visual hierarchy & layout** | One focal point per screen, consistent grid, 8-pt spacing, type scale | ui-visual-design.md |
| 7 | **Theme & brand fit** | Theme mood matches product/audience; semantic tokens, not raw colors; light/dark pair where needed | theme-selection.md |
| 8 | **Accessibility (WCAG 2.2 AA)** | Contrast 4.5:1 / 3:1, focus visible, keyboard path, targets ≥ 44px (24px min), labels, alt text, not color-only | accessibility.md |
| 9 | **Responsive** | 375 → 1440 without horizontal scroll, broken layout or hidden actions | ui-visual-design.md |
| 10 | **Copy** | Short, plain, action verbs; errors say what happened + next step; no emoji in UI | copy.md |

If the UI is AI-generated, also run [ai-design-qa.md](ai-design-qa.md).

## Step 3 — Rate each finding

| Severity | Meaning |
| --- | --- |
| **P0 Blocker** | Users can't finish the core task, data loss, or AA failure on core path |
| **P1 Major** | Task possible but slow/confusing; frequent errors; wrong fit for audience |
| **P2 Minor** | Friction, inconsistency, polish |
| **P3 Idea** | Enhancement, not a defect |

Every finding = **where** (screen/component/file:line) · **what's wrong** · **why it matters
to these users** · **fix** · **evidence** (screenshot, measured contrast, or *[assumed]*).

## Step 4 — Report

```
## UI Audit: <product>
Context: <users> doing <primary task> on <devices>  ([assumed] items marked)
Verdict: Fit / Fit with fixes / Not fit — one-sentence reason

Scorecard (0–2 each, total /20)
| Dimension | Score | Top issue |

Findings (P0 first)
| # | Sev | Where | Issue | Why it matters | Fix |

Not verified: <states/screens/breakpoints not seen>
Quick wins (≤1 day): …
Next step: …
```

Scoring: 2 = no P0/P1, 1 = P1 present, 0 = any P0. Verdict: any P0 → **Not fit**;
total ≥ 16 with no P0 → **Fit**; otherwise **Fit with fixes**.

## Rules

- Test tasks, not pages: walk each primary task end to end.
- Measure, don't eyeball, where possible (contrast ratios, target sizes, step counts).
- Never claim something works that wasn't observed — list it under *Not verified*.
- Don't redesign during the audit; propose fixes, then offer to apply them.
