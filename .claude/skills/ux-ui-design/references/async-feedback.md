# Async Feedback — Pending / Loading States

Rule: **every action that waits on the network, disk or computation must show, within
100 ms, that it was received and what is happening.** Silent waits make users click
twice, think it broke, or leave. (Heuristic: visibility of system status.)

## Anti-patterns this skill must catch and fix

| Anti-pattern | What the user sees | Fix |
| --- | --- | --- |
| **Silent login** | Press "Sign in" → nothing → page suddenly changes | Button → loading state ("Signing in…" + spinner, disabled); on success show brief transition / redirect message; on fail inline error, keep inputs |
| **Form closes before save finishes** | Press "Add" → modal closes → list empty for a moment → item pops in | Keep modal open with loading button until the server confirms, (optimistic close + pending row only for low-risk single-field adds: like, todo, chat; roll back with error on fail) |
| **Content pop-in** | Blank area, then data jumps in, layout shifts | Skeleton matching final layout; reserve space (no layout shift) |
| **Double submit** | Click twice → duplicate record | Disable trigger while pending; idempotent request |
| **Spinner forever** | No end, no error | Timeout → error with retry; long tasks show progress |
| **Global blocking overlay for a small action** | Whole screen frozen | Scope the loading to the element that triggered it |

## Timing ladder

| Wait | Feedback |
| --- | --- |
| < 100 ms | none needed (feels instant) |
| 100 ms – 1 s | pressed/disabled state on the trigger; spinner may appear after ~300 ms to avoid flicker |
| 1 – 3 s | inline spinner + verb label ("Saving…", "Signing in…"), skeleton for content |
| 3 – 10 s | progress text / steps ("Checking account… Loading dashboard…") |
| > 10 s | determinate progress bar, allow cancel / work in background, notify when done |

Once a spinner shows, keep it ≥ ~400 ms so it doesn't flash.

## Every async action = 4 states (design all of them)

1. **Idle** — normal control.
2. **Pending** — trigger disabled, spinner + present-tense verb, inputs locked (not cleared), `aria-busy="true"`.
3. **Success** — visible confirmation (toast, inline check, item highlighted, or the new page), then idle.
4. **Error** — human message + what to do + retry; user's input preserved.

Optimistic UI is allowed only when failure is rare and reversible; always show the
pending marker and roll back visibly on failure.

## Pattern by action

| Action | Recommended pattern |
| --- | --- |
| Sign in / sign up | Button loading → keep on page until auth resolves → route with skeleton of next page |
| Create / add (modal form) | Button loading in modal → close on success → new item highlighted + toast "Added" |
| Edit / save | Inline "Saving…" → "Saved" with time |
| Delete | Confirm → item fades as pending → removed + toast with Undo |
| Page / route change | Top progress bar + skeleton of target page |
| List / table fetch | Skeleton rows; empty state after load; error state with retry |
| Upload | Determinate progress per file, cancel |
| Search / filter | Keep old results dimmed + small spinner; don't blank the list |

## daisyUI implementation

```html
<!-- button pending -->
<button class="btn btn-primary" disabled aria-busy="true">
  <span class="loading loading-spinner loading-sm"></span> Signing in…
</button>

<!-- skeleton -->
<div class="skeleton h-4 w-3/4"></div>

<!-- pending row (optimistic) -->
<tr class="opacity-60"><td>New item</td><td><span class="loading loading-dots loading-xs"></span></td></tr>

<!-- success toast -->
<div class="toast"><div class="alert alert-success">Added</div></div>

<!-- long task -->
<progress class="progress progress-primary w-full" value="40" max="100"></progress>
```

Add `aria-live="polite"` on the status/toast region so screen readers hear "Saving…" / "Saved".

## React / shadcn projects: loading-ui

[loading-ui](https://www.loading-ui.com/) — free, open-source loaders (TurboStarter) for
React + Tailwind, installed as editable source through a shadcn registry. Use it when the
project is React/Next.js with shadcn; in plain HTML or daisyUI-only projects use daisyUI
`loading` / `skeleton` above. Check the repo's LICENSE before shipping (not stated on the site).

Setup:

```json
// components.json
"registries": { "@loading-ui": "https://loading-ui.com/r/{name}.json" }
```

```bash
npx shadcn@latest add @loading-ui/ring
```

```tsx
import { Ring } from "@/components/loading-ui/ring";
<button disabled={isSaving} aria-busy={isSaving}>
  {isSaving && <Ring className="size-4" />} {isSaving ? "Saving…" : "Save"}
</button>
```

Size via `size-*`, color via text color (`currentColor`), speed via `--duration`.

Pick by context (one loader style per product, never several in one view):

| Context | loading-ui component |
| --- | --- |
| Inside a button / inline | `ring`, `classic`, `spokes`, `arc` |
| Small inline status, chat "typing" | `dots`, `bouncing-dots`, `typing`, `pulse-dot` |
| Status text ("Generating…", AI answers) | `text-shimmer`, `text-shimmer-wave`, `text-dots` |
| Content area that keeps its layout | `skeleton` |
| Audio / processing | `wave`, `bars`, `symmetric-wave` |
| AI / image analysis | `analyzing-image` |
| Dev tools / CLI-style brand | `terminal`, `square-grid`, `square-snake` |
| Brand-led, playful (use sparingly) | `orbit-ring`, `morphing-infinity`, `wandering-eyes` |

Accessibility is **not** built in — always add it:

```tsx
<div role="status" aria-live="polite">
  <Ring className="size-4" aria-hidden="true" />
  <span className="sr-only">Loading…</span>
</div>
```

and respect reduced motion: `motion-reduce:animate-none` or swap to static text.

## Where this plugs into the design loop

- **Phase 3 Flows** — mark every step that calls the server; each gets the 4 states.
- **Phase 5 Hi-fi** — draw pending, success, error frames for each, not only idle.
- **Phase 6 Validation** — test on throttled network (Slow 3G / 2–3 s delay); no silent gap allowed.
- **Phase 7 Handoff** — spec lists, per action: pending label, loading component, timeout, success and error copy.
- **UI Audit** — dimension 4 fails (P1, or P0 if it causes duplicates or data loss) when any action waits silently.
