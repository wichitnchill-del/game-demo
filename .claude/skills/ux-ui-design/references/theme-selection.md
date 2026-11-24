# Theme Selection (daisyUI)

Pick a theme from what the product **does** and who it's **for** — never from taste
alone. Default theme source: [daisyUI](https://daisyui.com/docs/themes/) (v5, 35 built-in
themes). Analyse first, recommend second, customise third.

## Step 1 — Analyse the request (ask or infer, mark assumptions)

| Signal | Question | Examples |
| --- | --- | --- |
| Product type | What is it? | SaaS dashboard, e-commerce, landing page, portfolio, blog, game, internal tool |
| Primary task | What does the user *do* most? | read long text, scan data, buy, fill forms, browse visuals, play |
| Audience | Who? | enterprise / B2B, consumers, kids, developers, creatives, older adults |
| Brand mood | How should it feel? | trustworthy, playful, premium, calm, energetic, retro, minimal |
| Usage context | When/where? | all-day work, night use, mobile on-the-go, presentation |
| Brand colors | Existing brand palette? | if yes → custom theme seeded from brand, not a preset |
| Mode need | Light, dark, or both? | data/ops tools often need both |

If 3+ signals are unknown, ask up to 3 short questions before recommending.

## Step 2 — Map to a theme family

| Use case / mood | Light pick | Dark pick | Why |
| --- | --- | --- | --- |
| Enterprise / B2B / finance / admin | `corporate`, `winter` | `business`, `dim` | neutral, high trust, low distraction |
| SaaS dashboard / data-heavy | `light`, `nord` | `dark`, `night` | clean surfaces, clear status colors |
| Developer tools / docs | `nord`, `lofi` | `dracula`, `night` | familiar to devs, long-session comfort |
| Premium / luxury / fashion | `silk`, `caramellatte` | `luxury`, `black` | restrained palette, elegance |
| E-commerce (general) | `light`, `emerald` | `dim` | product images stay the hero |
| Food / cafe / lifestyle | `autumn`, `caramellatte` | `coffee` | warm, appetising |
| Health / wellness / eco | `garden`, `emerald` | `forest` | calm, natural greens |
| Kids / education / playful | `cupcake`, `bumblebee`, `pastel` | `sunset` | friendly, soft or cheerful |
| Romantic / events / beauty | `valentine`, `pastel` | `sunset` | soft pinks, warmth |
| Creative / portfolio / agency | `fantasy`, `cmyk`, `lofi` | `black`, `abyss` | expressive or gallery-neutral |
| Gaming / web3 / nightlife | `cyberpunk`, `acid` | `synthwave`, `abyss` | high energy, neon |
| Retro / indie / nostalgic | `retro`, `lemonade` | `coffee` | vintage character |
| Seasonal / campaign | — | `halloween` | short-lived campaigns only |
| Wireframe / prototype stage | `wireframe`, `lofi` | — | keeps focus on structure (phase 4) |
| Water / travel / marine | `aqua`, `winter` | `night` | cool blues |

Rules:
- Expressive themes (`cyberpunk`, `acid`, `synthwave`, `halloween`) only for brand-led,
  short-task pages — not for all-day work tools.
- Data-heavy or long-reading products → neutral theme + one accent.
- Always pair a light and dark theme when users work long or at night.

## Step 3 — Validate before committing

- Contrast: check `base-content` on `base-100/200/300` and each `*-content` on its color
  meets WCAG AA (4.5:1 text, 3:1 UI). Some presets (`cupcake`, `lemonade`, `acid`,
  `cyberpunk`) need checking on muted text and `neutral`.
- Status colors (`success`/`warning`/`error`/`info`) must stay distinguishable
  for color-blind users — pair with icons/labels.
- Preview real screens (forms, tables, empty/error states), not just buttons.

## Step 4 — Implement (verified against daisyUI 5.8.2 docs)

### 4a. Enable only the themes you chose

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: corporate --default, business --prefersdark;
}
```

- `--default` = theme used without `data-theme`; `--prefersdark` = theme used when the OS is in dark mode.
- No config → `light` + `dark` only. `themes: all` ships all 35 (heavier CSS, avoid in production).
  `themes: false` disables all themes and daisyUI colors.

### 4b. Apply / scope

```html
<html data-theme="corporate">
  <section data-theme="business">…</section>  <!-- nesting works, no limit -->
</html>
```

- Theme switcher: `theme-controller` component, or the `theme-change` library (saves choice in localStorage).
- Nested themes are a design tool: a dark hero inside a light page, a "pro" panel, a preview area.

### 4c. Pick the customisation level (smallest change that works)

| Situation | Approach |
| --- | --- |
| Preset fits | use as is |
| Preset fits, brand color differs | **override the built-in** — only listed vars change, rest inherited |
| Brand defines full palette / shape | **new custom theme** — define every variable |
| No build step (CDN) | plain CSS rule `[data-theme="x"] { … }` |

Override a built-in (partial is fine):

```css
@plugin "daisyui/theme" {
  name: "corporate";
  default: true;
  --color-primary: oklch(55% 0.18 250);
  --color-primary-content: oklch(98% 0.01 250);
}
```

New custom theme (define all variables — a new name inherits nothing):

```css
@plugin "daisyui/theme" {
  name: "brand";
  default: true;
  prefersdark: false;
  color-scheme: light;        /* browser UI: scrollbars, inputs */
  themecontroller: true;

  --color-base-100: oklch(98% 0.02 240);
  --color-base-200: oklch(95% 0.03 240);
  --color-base-300: oklch(92% 0.04 240);
  --color-base-content: oklch(20% 0.05 240);
  --color-primary: oklch(55% 0.3 240);
  --color-primary-content: oklch(98% 0.01 240);
  --color-secondary: oklch(70% 0.25 200);
  --color-secondary-content: oklch(98% 0.01 200);
  --color-accent: oklch(65% 0.25 160);
  --color-accent-content: oklch(98% 0.01 160);
  --color-neutral: oklch(50% 0.05 240);
  --color-neutral-content: oklch(98% 0.01 240);
  --color-info: oklch(70% 0.2 220);
  --color-info-content: oklch(98% 0.01 220);
  --color-success: oklch(65% 0.25 140);
  --color-success-content: oklch(98% 0.01 140);
  --color-warning: oklch(80% 0.25 80);
  --color-warning-content: oklch(20% 0.05 80);
  --color-error: oklch(65% 0.3 30);
  --color-error-content: oklch(98% 0.01 30);

  --radius-selector: 1rem;    /* checkbox, toggle, badge */
  --radius-field: 0.25rem;    /* button, input, select */
  --radius-box: 0.5rem;       /* card, modal, alert */
  --size-selector: 0.25rem;
  --size-field: 0.25rem;
  --border: 1px;
  --depth: 1;                 /* 0 = flat, 1 = subtle 3D shadow */
  --noise: 0;                 /* 0 = off, 1 = grain texture */
}
```

Make a dark pair with the same hues: flip base lightness (base-100 ≈ 20–25%, base-content ≈ 90%+),
set `color-scheme: dark; prefersdark: true;`.

### 4d. Map mood → shape tokens (not just color)

| Mood | radius-field / box | border | depth | noise |
| --- | --- | --- | --- | --- |
| Enterprise / trustworthy | 0.25rem / 0.5rem | 1px | 0–1 | 0 |
| Friendly / playful / kids | 1rem+ / 1rem+ | 1–2px | 1 | 0 |
| Premium / luxury | 0–0.25rem / 0–0.25rem | 1px | 0 | 0 |
| Brutalist / retro / wireframe | 0 / 0 | 2px | 0 | 0–1 |
| Tactile / crafted / food | 0.5rem / 1rem | 1px | 1 | 1 |

### 4e. Theme-specific styles

```css
[data-theme="corporate"] { .hero-cta { letter-spacing: .01em; } }
/* make Tailwind dark: follow the daisyUI dark theme instead of OS */
@custom-variant dark (&:where([data-theme=business], [data-theme=business] *));
```

Prefer semantic daisyUI colors (`bg-base-200`, `text-base-content`, `btn-primary`) over raw
Tailwind colors (`bg-gray-100`) — raw colors do not change with the theme.

### Tools

- Theme generator (edit, preview components, copy CSS): https://daisyui.com/theme-generator/
- Docs: https://daisyui.com/docs/themes/

## Output format

Give the user:
1. **Analysis** — 1 line per signal (mark assumed ones).
2. **Recommendation** — primary theme + dark pair + 1 alternative, each with a one-line reason.
3. **Customisation level** — preset / override / custom, and shape tokens chosen for the mood.
4. **Watch-outs** — contrast or mood risks.
5. **Config snippet** — ready to paste (plugin config + theme block + `data-theme` usage).
