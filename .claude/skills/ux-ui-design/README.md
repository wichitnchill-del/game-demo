# ux-ui-design

Thai-first UX/UI skill on daisyUI 5 + Tailwind. Loop: 0 Brief → 1 Research → 2 IA →
3 Flows → 4 Wireframe (ASCII, get OK) → 5 Hi-fi → 6 Validate → 7 Handoff.

Use it for: new site / app / screen, landing, admin, nav, forms, login / OTP, checkout /
PromptPay, booking / queue, tables / charts, popups, loading, theme, design system,
redesign, critique, UI audit, website review, feature plan, page copy, AI-made UI QA,
mobile web / PWA / LINE LIFF / iOS / Android. Say "อัลตร้า" for full-depth mode.

Version 1.0.0 · MIT · see [CHANGELOG](CHANGELOG.md)

## Install

The folder must be named `ux-ui-design` and hold `SKILL.md` at its top.

**Claude Code, all projects:**
```bash
git clone https://github.com/wichitnchill-del/UxUi-GORRADA.git ~/.claude/skills/ux-ui-design
```

**Claude Code, one project** (run in the project folder):
```bash
git clone https://github.com/wichitnchill-del/UxUi-GORRADA.git .claude/skills/ux-ui-design
```

**Update:**
```bash
git -C ~/.claude/skills/ux-ui-design pull
```

**claude.ai / Claude Desktop:** GitHub → Code → Download ZIP → unzip → rename the folder
to `ux-ui-design` → zip it again → Settings → Capabilities → Skills → upload.

Check: start a new session and type `ใช้สกิลนี้ยังไง` — it should show the start-here guide.

## Layout

- [references/start-here.md](references/start-here.md) — how to ask, sample wireframe
- [SKILL.md](SKILL.md) — entry point: path table, defaults, output, guard rails
- [references/ultra-mode.md](references/ultra-mode.md) — full-depth mode: 3 directions, all states, verify loop
- [references/ux-process.md](references/ux-process.md) — phases, wireframe gate, iterate on feedback
- [references/feature-planning.md](references/feature-planning.md) — feature planning, MVP, priorities
- [references/platforms.md](references/platforms.md) — desktop, mobile web, PWA, LINE LIFF, iOS, Android
- [references/navigation.md](references/navigation.md) — navbar, sidebar, bottom nav
- [references/landing-page.md](references/landing-page.md) — landing pages
- [references/admin-dashboard.md](references/admin-dashboard.md) — admin sidebar, dashboard, tables, charts, KPIs
- [references/forms.md](references/forms.md) — forms, Thai data, validation
- [references/auth.md](references/auth.md) — login, signup, OTP, reset
- [references/checkout-payment.md](references/checkout-payment.md) — cart, checkout, PromptPay, order status
- [references/booking.md](references/booking.md) — booking, queue, slots, admin calendar
- [references/empty-error-pages.md](references/empty-error-pages.md) — empty states, 404 / 500 / offline
- [references/account-settings.md](references/account-settings.md) — settings, security, PDPA, cookie banner
- [references/receipts-print-email.md](references/receipts-print-email.md) — receipt, tax invoice, print, email, LINE Flex
- [references/pdf-documents.md](references/pdf-documents.md) — PDF: tools, Thai fonts, layout, download UX
- [references/notifications.md](references/notifications.md) — toast, modal, push, sound, badges
- [references/async-feedback.md](references/async-feedback.md) — loading / pending states
- [references/theme-selection.md](references/theme-selection.md) — daisyUI theme by product & mood
- [references/ui-visual-design.md](references/ui-visual-design.md) — visual craft
- [references/thai-ui.md](references/thai-ui.md) — Thai fonts, line breaks, copy, TH / EN switch
- [references/copy.md](references/copy.md) — microcopy
- [references/content-writing.md](references/content-writing.md) — site descriptions, page copy, meta
- [references/build-html.md](references/build-html.md) — pinned starter, icons, images, existing stack
- [references/design-system-handoff.md](references/design-system-handoff.md) — tokens, components, handoff
- [references/design-principles.md](references/design-principles.md) — heuristics & laws
- [references/accessibility.md](references/accessibility.md) — WCAG 2.2 AA
- [references/ui-audit.md](references/ui-audit.md) — full UI audit, scorecard, verdict
- [references/website-review.md](references/website-review.md) — UX, SEO, perf, security hygiene
- [references/ai-design-qa.md](references/ai-design-qa.md) — AI look, UX defects, execution mistakes
- [references/ship-checklist.md](references/ship-checklist.md) — pre-delivery checklist + verify steps

## Quick usage

```
ทำ landing page คาเฟ่ ลูกค้าวัยทำงาน ต้องมีเมนู แผนที่ ปุ่มจอง
ออกแบบหน้าแอดมินร้านคลินิก ใช้บนคอม
ตรวจ UI ทั้งหมดว่าเหมาะกับการใช้งานไหม <URL>
ทำหน้าจองคิวร้านทำเล็บใน LINE จ่ายมัดจำ PromptPay
อัลตร้า: ออกแบบแอปสั่งอาหารร้านเรา
```

## Notes

daisyUI 5 + Tailwind default · Thai UI first-class · no emoji, Lucide icons · WCAG 2.2 AA
blocks release · every async action shows loading · wireframe OK before build · verify
before delivery · personas are [assumed] until researched.
