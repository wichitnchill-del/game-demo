# PDF Documents

Receipts, tax invoices, quotes, reports, certificates, tickets.
Rule: design it as an HTML page with print CSS, then turn it into PDF. One template → screen, print, PDF.

## 1. Ask first (max 3)
- Which document + who reads it (customer, accountant, government)?
- Size: A4 / A5 / 80 mm slip / card? Portrait or landscape?
- Made where: in the browser, or on the server (auto, emailed, archived)?

## 2. Pick the tool

| Need | Use | Thai |
| --- | --- | --- |
| User prints / saves now | `window.print()` + print CSS ([receipts](receipts-print-email.md#3-print-css)) | Good |
| Server makes PDF (email, archive, bulk) | Headless Chrome: Puppeteer / Playwright `page.pdf()`, or Gotenberg | **Best** — real text shaping |
| Python server | WeasyPrint | Good (embed a Thai font) |
| React app | `@react-pdf/renderer` | Register a Thai font; test tone marks |
| Pure client JS | pdfmake (custom Thai font vfs) | OK after testing |
| Avoid for Thai | jsPDF text, html2canvas → image PDF | Tone marks float / text not selectable |

Default: HTML template + headless Chrome.

## 3. Thai checks (most common failure)
- Embed a Thai font (Sarabun, Noto Sans Thai, IBM Plex Sans Thai) — never rely on system fonts.
- Vowels / tone marks sit right (่ ้ ิ ี ึ ื ั ็), no boxes (□), no overlap.
- Text is selectable and copy-pastes as real Thai (not an image).
- Line breaks don't split words; long item names wrap, never cut.

## 4. Layout
- `@page { size: A4; margin: 15mm; }`; content inside margins; light theme only.
- Header: logo, doc name, no., date. Footer: page "1 / 2", contact.
  Puppeteer: `displayHeaderFooter` + `headerTemplate` / `footerTemplate` (`pageNumber`, `totalPages`).
- Tables: repeat `thead` each page; `break-inside: avoid` on rows and totals block.
- Totals block never alone on a new page; signature box stays with it.
- Colors: `print-color-adjust: exact`; black text on white; ≥ 10 pt body.
- QR (PromptPay / verify link) ≥ 2 cm, quiet zone around it.

```js
await page.goto(url, { waitUntil: 'networkidle0' });
await page.evaluate(() => document.fonts.ready);
await page.pdf({ format: 'A4', printBackground: true, preferCSSPageSize: true,
  displayHeaderFooter: true, headerTemplate: '<span></span>',
  footerTemplate: '<div style="font-size:8pt;width:100%;text-align:center"><span class="pageNumber"></span> / <span class="totalPages"></span></div>',
  margin: { top: '15mm', bottom: '18mm', left: '15mm', right: '15mm' } });
```
Wait for fonts before `pdf()`, or Thai falls back to boxes.

## 5. File
- Name: `ใบเสร็จ-A1024-2569-11-24.pdf` or ASCII `receipt-A1024-2026-11-24.pdf` (safer for email / LINE).
- Metadata: `<title>` becomes PDF title; set lang `th`.
- Size: < 1 MB typical; compress images, subset fonts.
- Archive / e-Tax: PDF/A (e-Tax invoice adds XML + digital signature per ETDA rules — confirm with accountant / provider).
- Private docs: signed short-lived URL, not a public link.

## 6. UX around the PDF
- Button says the result: "ดาวน์โหลด PDF" / "พิมพ์".
- Pending: spinner + "กำลังสร้าง PDF…"; > 5 s or bulk → background job + notify "PDF พร้อมแล้ว" ([async-feedback](async-feedback.md), [notifications](notifications.md)).
- Error: "สร้าง PDF ไม่สำเร็จ · ลองอีกครั้ง"; keep the on-screen version.
- Mobile: open in new tab (in-app browsers like LINE may block downloads → offer "เปิดในเบราว์เซอร์" or send file in chat).
- Show a preview (HTML) before download when the user can still edit.

## 7. Accessibility
- Tagged PDF (headless Chrome tags by default; keep real headings, tables, alt text in HTML).
- Reading order = HTML order. Don't flatten text into images.

## 8. Check
- Open the PDF: Thai renders, text selectable, fonts embedded (viewer → Properties → Fonts).
- 1-page and 3-page cases; long names; 0 items; max items.
- Totals match the screen; page numbers right; nothing cut at margins.
- Opens in Chrome, Adobe Reader, iOS Files, LINE.
