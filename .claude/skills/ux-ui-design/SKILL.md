---
name: ux-ui-design
description: >-
  UX/UI design with daisyUI 5 + Tailwind, Thai-first: websites, landing pages,
  apps (mobile web, PWA, LINE LIFF, iOS/Android), admin dashboards, nav, forms,
  login/OTP, cart/checkout/PromptPay, booking/queues, tables/charts, popups,
  loading states, themes, design systems. Triggers: "ออกแบบเว็บ", "ทำแอปมือถือ",
  "LINE LIFF", "ทำหน้าแอดมิน", "หลังบ้าน", "ทำเมนู", "sidebar", "ฟอร์ม",
  "เข้าสู่ระบบ", "OTP", "ตะกร้า", "ชำระเงิน", "จองคิว", "นัดหมาย", "ตาราง",
  "กราฟ", "ใบเสร็จ", "ใบกำกับภาษี", "PDF", "404", "ตั้งค่าบัญชี", "PDPA", "แจ้งเตือน", "popup", "loading", "เลือกธีม", "ฟอนต์ไทย", "wireframe",
  "ทำให้สวย"; audit ("ตรวจ UI", "เหมาะกับการใช้งานไหม", "UX audit"); website
  review ("ประเมินเว็บไซต์", "ต้องปรับปรุงอะไร"); feature plan ("วางแผนฟีเจอร์",
  "MVP"); page copy ("เขียนคำอธิบายเว็บ", "about us", "meta description"); QA of
  AI-made UI (v0, Figma Make); ultra mode ("อัลตร้า", "ultra"); "ใช้สกิลนี้ยังไง".
  Shows an ASCII wireframe for OK, then delivers HTML, tokens, copy or findings.
license: MIT
metadata:
  version: "1.0.0"
---

# ux-ui-design

Design requests → short, validated, handoff-ready work.

## Start

Vague request or "how do I use this?" → show [start-here](references/start-here.md).
Platform unknown → ask เว็บ / แอป / LINE ([platforms](references/platforms.md)).
"อัลตร้า" / "ultra" → run the chosen path in [ultra-mode](references/ultra-mode.md).

## Pick the path

| Request | Do | Read |
| --- | --- | --- |
| Plan / prioritize features, MVP | Goal → list → score → MoSCoW → phases | [feature-planning](references/feature-planning.md) |
| Write site description / page copy | Ask tone → formulas → 2 versions | [content-writing](references/content-writing.md) |
| New product / screen | Full design loop (wireframe OK at phase 4) | [ux-process](references/ux-process.md) |
| Redesign / UX fix | Quick ui-audit → fix flow → wireframe OK → hi-fi → re-test | [ux-process](references/ux-process.md) |
| Audit whole UI / fit for use? | Context → walk-through → 10 checks → score /20 + verdict | [ui-audit](references/ui-audit.md) |
| Review website: gaps / what to fix | UX, content, trust, a11y, perf, SEO, security hygiene → P0–P3 | [website-review](references/website-review.md) |
| Critique a screen | Heuristics + a11y → ranked findings | [design-principles](references/design-principles.md) |
| Landing page | Goal → structure → wireframe OK → hero → HTML | [landing-page](references/landing-page.md) |
| Build HTML / code | Starter or project stack → states → verify | [build-html](references/build-html.md) |
| Admin / dashboard / tables / charts | Roles → sidebar → wireframe OK → home KPIs → tables / charts | [admin-dashboard](references/admin-dashboard.md) |
| Navbar / sidebar / menu | Ask → 2 options inside the wireframe → pick → build | [navigation](references/navigation.md) |
| Mobile app / PWA / LINE LIFF / iOS / Android | Ask platform → pick → platform patterns → wireframe OK | [platforms](references/platforms.md) |
| Form | Fields → validation → wireframe OK → submit states | [forms](references/forms.md) |
| Login / signup / OTP / reset | Pick method → screen set → wireframe OK → 4 states each | [auth](references/auth.md) |
| Cart / checkout / payment / pricing | Cart → checkout → pay → order status; every payment state | [checkout-payment](references/checkout-payment.md) |
| Booking / queue / appointment | Pattern → service → slot → hold → confirm; admin calendar | [booking](references/booking.md) |
| Empty state / 404 / 500 / offline | Formula → each case → keep page frame | [empty-error-pages](references/empty-error-pages.md) |
| Account settings / privacy / PDPA / cookies | Groups → save per section → consent + banner | [account-settings](references/account-settings.md) |
| Receipt / tax invoice / print / email / LINE Flex | Pick doc → layout → print CSS / email / Flex | [receipts-print-email](references/receipts-print-email.md) |
| PDF (receipt, quote, report, certificate) | Ask size → HTML template → tool → Thai checks | [pdf-documents](references/pdf-documents.md) |
| Alert / popup / toast / push / sound | Pick type by situation | [notifications](references/notifications.md) |
| Loading / waiting | idle / pending / success / error per async action | [async-feedback](references/async-feedback.md) |
| Theme / colors | Analyse product → daisyUI theme pair → contrast → config | [theme-selection](references/theme-selection.md) |
| Design system | Tokens → components + states → docs | [design-system-handoff](references/design-system-handoff.md) |
| Make it beautiful | Visual craft inside a validated flow | [ui-visual-design](references/ui-visual-design.md) |
| AI-made UI | Generic look, defects, execution | [ai-design-qa](references/ai-design-qa.md) |
| Check / verify built work | Checklist → verify steps → footer | [ship-checklist](references/ship-checklist.md) |
| Feedback on delivered work | Restate → reproduce → change only that → re-verify | [ux-process](references/ux-process.md#iterate-on-feedback) |

Tie-break: one screen or image → Critique; whole app fit for use → UI audit; public site
incl. SEO/perf/security → Website review; AI-made → also ai-design-qa; redesign → quick ui-audit first.
Combined requests, in order: feature-planning → platform → nav → wireframe OK → theme → build → copy → verify.

## Design loop

0 Brief → 1 Research → 2 IA → 3 Flows → 4 Wireframe gate → 5 Hi-fi → 6 Validate → 7 Handoff

## Defaults

- **Short, concise, simple** — UI copy and deliverables. No emoji in UI; Lucide icons. [copy](references/copy.md)
- Mobile first: test 375 / 768 / 1024 / 1440 px. Targets 24 px AA floor, 44 px default, 48 px busy ([accessibility](references/accessibility.md)).
- Thai text rules; TH / EN switch. [thai-ui](references/thai-ui.md)
- Platform: web unless asked; app / LINE → [platforms](references/platforms.md).
- Code: one HTML file from [build-html](references/build-html.md) (Tailwind 4 + daisyUI 5 CDN pinned, Thai font, Lucide); existing project → its own stack.
- Before delivering: [ship-checklist](references/ship-checklist.md) incl. verify steps.

## Output

- Build (landing / admin / form / app): Decisions block → wireframe OK → file → footer.
- Critique: `| # | P0–P3 | Where | Issue | Rule | Fix |`, worst first, max 10; unseen states → not verified.
- Audit / review / theme / plan / copy: the format in that reference.
- Every delivery ends with: `ไฟล์: … · ตรวจแล้ว: … · ยังไม่ได้ตรวจ: … · ต่อไป: …`

## Guard rails

0. Wireframe gate: new screen, nav or major layout → ASCII wireframe (desktop + mobile) and an OK before code ([ux-process](references/ux-process.md#phase-4--wireframe-gate)).
1. Context first: who, what task, what goal. Mark guesses **[assumed]**.
2. Every screen: empty / loading / error / success.
3. Every click that waits: feedback < 100 ms, no double submit, forms stay open until saved (optimistic close only for low-risk single-field adds: like, todo, chat).
4. Accessibility blocks release.
5. Theme after analysis, never by taste.
6. Navigation: 2 sketched options inside the wireframe; get a pick before coding.
7. Never claim what wasn't seen — list it as *not verified*.
8. Feedback on delivered work → change only what was named; keep the Decisions block.
