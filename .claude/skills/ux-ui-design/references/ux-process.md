# UX Process

Phase-by-phase workflow: design request → deliverable.

## Phase 0 — Frame the brief

- **Problem + metric**: which user/business outcome moves, measured how (conversion, task success, time-on-task, retention).
- **Users**: real or researched; guesses **[assumed]**. **Scope**: in / out (screen, flow, product).
- **Constraints**: platform, stack, brand assets, timeline.
- Ask <= 3 questions, else infer and mark **[assumed]**. Vague -> [start-here](start-here.md). Platform unknown -> ask เว็บ / แอป / LINE ([platforms](platforms.md)).
- Output: one-paragraph problem statement + metric.

## Phase 1 — Research

- Analytics / funnel (drop-offs, usage), support tickets / crash logs (real failures), interviews / surveys (needs, mental models), competitive audit (patterns, gaps).
- Output: prioritized insights feeding IA / flows.

## Phase 2 — Information architecture

- Sitemap / nav model for scope. Card sort / tree test if taxonomy is unclear.
- Nav: 2 ASCII options inside the wireframe -> user picks ([navigation](navigation.md)).

## Phase 3 — User flows

- Happy path + critical flows: empty, error, loading, offline, permission, success. Notation: entry, steps, decisions, exit.
- Mark every server call: idle / pending / success / error ([async-feedback](async-feedback.md)). Pick toast / inline / modal ([notifications](notifications.md)). Domain flows: [auth](auth.md), [checkout-payment](checkout-payment.md), [booking](booking.md).

## Phase 4 — Wireframe gate

- **When**: new page or screen, nav, major layout change.
- **Skip**: copy-only change, a single CSS fix from Iterate, or user says "ทำเลย ไม่ต้องร่าง" (still list [assumed] items in one line).
- **Format**: desktop <= 64 cols, mobile <= 22 cols; box drawing `┌ ─ ┐ │ └ ┘ ├ ┤`; `[ปุ่ม]` = button, `▸` = link, `← note` = annotation; platform chrome (status bar, tab bar, LINE header) per [platforms](platforms.md).
- **Thai**: combining vowels/tone marks are zero-width in monospace, so right borders drift: leave the right border open on lines with Thai text; pad inner dividers by visible width (marks = 0).
- Under each sketch: `สถานะ: ว่าง / กำลังโหลด / ผิดพลาด` + <= 3 [assumed] items.
- End with one question: "ใช้แบบนี้ไหม หรือแก้ตรงไหน". <= 3 screens per message; nav as options A/B.
- **OK** = user says ใช่ / OK / ใช้ได้ / ไปต่อ, or picks an option. Silence or a question is not OK.
- Record a Decisions block; repeat it in each delivery:

```
Decisions
- Wireframe: v1 approved (desktop + mobile)
- Platform: mobile web
- Nav: option B (sidebar)
- Theme: corporate / business
- Font: IBM Plex Sans Thai
```

Samples (each <= 10 lines):
```
(a) admin desktop
┌──────────────┬──────────────────────────────────────────────┐
│ Logo         │ ออเดอร์                            [+ เพิ่ม]
│ ▸ ภาพรวม     │ [ค้นหา                    ]
│ ▸ ออเดอร์     │ เลขที่    ลูกค้า     ยอด     สถานะ
│ ▸ เมนู        │ #101    สมชาย    ฿250    รอ
│ ▸ ตั้งค่า       │ #102    วิไล      ฿480    เสร็จ
└──────────────┴──────────────────────────────────────────────┘
(b) mobile form
┌────────────────────┐
│ ← เพิ่มลูกค้า
│ ชื่อ-นามสกุล
│ [                ] │
│ เบอร์มือถือ
│ [                ] │
│ อีเมล
│ [                ] │
│ [      บันทึก      ]  ← sticky bottom
└────────────────────┘
(c) mobile confirm
┌────────────────────┐
│ (หน้าเดิม จางลง)
├────────────────────┤
│        ───         │ ← bottom sheet
│ ลบ "โต๊ะ 5"?
│ [ยกเลิก]     [ลบ]
└────────────────────┘
```

Review: is the structure right before pixels? Then stop: no hi-fi or code before OK.

## Phase 5 — High-fidelity design

- Hierarchy, components, states, responsive behavior; clickable prototype if needed.
- daisyUI 5 + Tailwind from [build-html](build-html.md); theme via [theme-selection](theme-selection.md); Lucide icons; [thai-ui](thai-ui.md); platform rules [platforms](platforms.md).

## Phase 6 — System, accessibility, validation

- Tokens / components match the existing system (or define new). WCAG 2.2 AA: [accessibility](accessibility.md).
- Usability test: tasks, success criteria, metrics (task success, errors, time-on-task).
- Run [ship-checklist](ship-checklist.md) incl. Verify steps; throttle to a 2–3 s delay: no silent wait.

## Phase 7 — Handoff

- Frames / prototype, tokens, component specs, copy, assets; dev-ready specs per [design-system-handoff](design-system-handoff.md).

## Iterate on feedback

1. Restate as what + where + width ("เมนูตกบรรทัด ที่ 1024 px").
2. Reproduce: screenshot at that width.
3. Find the cause (table).
4. Change only what was named; keep the Decisions block (no redesign, no new theme/nav unless asked).
5. Two or more readings -> show 2 tiny options before editing.
6. Re-verify at that width + quick 375 / 1440 regression.
7. Reply: before/after screenshot + <= 3 change bullets + updated Decisions if changed.

| ผู้ใช้พูด | เช็ค | แก้ |
|---|---|---|
| เมนูตกบรรทัด | nav link `offsetTop` at 768 / 1024 | shorter labels, `whitespace-nowrap`, drawer until `lg:` not `md:`, rare links into "เพิ่มเติม" dropdown |
| สีจืด | primary/accent use | override `--color-primary`, one accent block, no raw colors |
| ปุ่มเล็ก | height < 44 px | 44 px override ([build-html](build-html.md)), `btn-lg` for main CTA |
| ตัวเล็ก / อ่านยาก | < 16 px, contrast | `text-base`+, fix contrast |
| สระโดนตัด | line-height, fixed height | `leading-relaxed`, `min-h-*` not `h-*` |
| รก / แน่น | section count, spacing | cut sections, more spacing |
| ดูเหมือน AI | [ai-design-qa](ai-design-qa.md) | apply its fixes |
| กดแล้วเงียบ | async states | add the 4 states |
| ไม่เหมือนแบรนด์ | tokens | brand theme ([theme-selection](theme-selection.md)) |

Test -> learn -> refine; never freeze user-facing design before the first validation.
