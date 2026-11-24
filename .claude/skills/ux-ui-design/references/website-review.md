# Website Review — gaps & what to improve

Trigger: "ประเมินเว็บไซต์", "เว็บมีช่องโหว่อะไร", "ต้องปรับปรุงอะไร", "website review".
Covers UX + content + performance + SEO + basic security hygiene.
Only for sites the user owns or is allowed to review. **Passive checks only** — read pages,
headers, source; no attacks, scans, login attempts or form spam.

## 1. Context (max 3 questions)
Site goal (sell / leads / info / booking), main users, key pages.

## 2. Check 6 areas

| Area | Check |
| --- | --- |
| **UX** | Goal clear in 5 s, main CTA visible, nav works ([navigation](navigation.md)), loading feedback ([async-feedback](async-feedback.md)), mobile 375 px. Deep: [ui-audit](ui-audit.md) |
| **Content** | Real info: price, contact, hours, address; no lorem/placeholder; broken links/images; typos; Thai text ([thai-ui](thai-ui.md)) |
| **Trust** | Real reviews, contact page, privacy policy, cookie notice (PDPA), clear refund/terms if selling |
| **Accessibility** | Contrast, alt text, labels, keyboard, focus ([accessibility](accessibility.md)) |
| **Performance** | LCP < 2.5 s, CLS < 0.1, INP < 200 ms; image size/format; unused JS; lazy images |
| **SEO** | `<title>`, meta description, one `<h1>`, OG image, sitemap.xml, robots.txt, clean URLs, structured data where useful |
| **Security hygiene** | HTTPS everywhere, no mixed content; headers (HSTS, CSP, X-Content-Type-Options, frame protection); forms have CAPTCHA/rate-limit sign; no secrets/API keys in page source; no exposed `.env`/backup/admin listing found by normal links; outdated libraries (version in source); error pages don't leak stack traces |

Tools (if available): browser walk-through, Lighthouse / PageSpeed, `curl -I` for headers,
view-source. Security findings = *signals* to hand to a developer/security team, not a pentest.

## 3. Rate
P0 broken / unsafe (site down, checkout fails, secret exposed, no HTTPS) ·
P1 hurts goal · P2 friction · P3 idea.

## 4. Report (short)
```
## Website Review: <site>
Goal: … | Users: … | Pages checked: …
Health: UX ●●○ Content ●●● Trust ●○○ A11y ●●○ Perf ●○○ SEO ●●○ Security ●●○

Top fixes (P0 first)
| # | Sev | Area | Where | Issue | Fix |

Quick wins (≤ 1 day): …
Not verified: …
```
