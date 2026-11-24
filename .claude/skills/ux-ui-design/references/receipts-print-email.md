# Receipts, Tax Invoice, Print, Email, LINE Flex

Tax rules: have the client's accountant confirm. VAT 7% unless told otherwise.

## 1. Which document

| Doc | When | Must show |
| --- | --- | --- |
| ใบเสร็จรับเงิน | Any sale | Shop name, no., date, items, total, paid by |
| ใบกำกับภาษีอย่างย่อ | Retail, VAT-registered shop | + shop tax ID, "VAT included" total |
| ใบกำกับภาษีเต็มรูป | Customer asks (business) | Below |
| ใบแจ้งหนี้ / ใบเสนอราคา | Before payment | No., due date, "ยังไม่ใช่ใบเสร็จ" |

Full tax invoice shows: word **ใบกำกับภาษี** prominently · seller name, address, 13-digit
tax ID, branch (สำนักงานใหญ่ / สาขาที่ 00001) · buyer name, address (+ tax ID, branch if
VAT-registered) · invoice no. · date · items, qty, unit price · subtotal, VAT, total separate.

## 2. Layout (A4)
```
┌───────────────────────────────────────┐
│ [Logo] ร้าน / บริษัท     ใบกำกับภาษี    │
│ ที่อยู่ · เลขภาษี · สาขา   เลขที่ · วันที่ │
├───────────────────────────────────────┤
│ ลูกค้า: ชื่อ ที่อยู่ เลขภาษี              │
├────┬──────────────┬────┬──────┬───────┤
│ #  │ รายการ        │ จน.│ ราคา │ รวม   │
├────┴──────────────┴────┴──────┴───────┤
│                     รวม       1,000.00 │
│                     VAT 7%       70.00 │
│                     สุทธิ      1,070.00 │
│ (หนึ่งพันเจ็ดสิบบาทถ้วน)                 │
│ ผู้รับเงิน ________     วันที่ ________   │
└───────────────────────────────────────┘
```
- Numbers right-aligned, tabular digits, 2 decimals, commas. Amount in Thai words.
- Long item names wrap; never cut. Multi-page: repeat header row, "หน้า 1/2".

## 3. Print CSS
```css
@page { size: A4; margin: 15mm; }
@media print {
  nav, .no-print, .btn { display: none !important; }
  body { background: #fff; color: #000; font-size: 12pt; }
  * { print-color-adjust: exact; -webkit-print-color-adjust: exact; }
  tr, .keep { break-inside: avoid; }
  thead { display: table-header-group; }
}
```
- Thermal slip: `@page { size: 80mm auto; margin: 3mm; }` (58 mm for small printers),
  1 column, 12–14 px, no logo color, cut space at end.
- Light theme only for print; test in browser print preview at A4 and 80 mm.
- "พิมพ์" button: `window.print()`; "ดาวน์โหลด PDF" → [pdf-documents](pdf-documents.md).

## 4. Email receipt
- Table layout, inline CSS, width 600 px, no JS, no web-font reliance
  (stack: `'Noto Sans Thai', Tahoma, sans-serif`).
- Order: preheader (hidden 1-line summary) → logo → "ชำระเงินแล้ว ฿1,070" → items → total
  → 1 button (ดูออเดอร์) → shop contact → footer (why you got this).
- Subject: `ใบเสร็จ #A1024 · ร้าน… · ฿1,070`. Works in dark mode (no white-only logos).
- Attach PDF for tax invoices.

## 5. LINE Flex Message
Bubble: header (shop) → body (status, items, total) → footer (1–2 buttons). `altText` required.
```json
{ "type": "flex", "altText": "ใบเสร็จ #A1024 ฿1,070",
  "contents": { "type": "bubble", "size": "kilo",
    "body": { "type": "box", "layout": "vertical", "spacing": "sm", "contents": [
      { "type": "text", "text": "ชำระเงินแล้ว", "weight": "bold", "color": "#16a34a" },
      { "type": "text", "text": "#A1024 · 24 พ.ย. 2569", "size": "sm", "color": "#6b7280" },
      { "type": "separator" },
      { "type": "box", "layout": "horizontal", "contents": [
        { "type": "text", "text": "รวม", "flex": 1 },
        { "type": "text", "text": "฿1,070", "align": "end", "weight": "bold" } ] } ] },
    "footer": { "type": "box", "layout": "vertical", "contents": [
      { "type": "button", "style": "primary", "action":
        { "type": "uri", "label": "ดูออเดอร์", "uri": "https://example.com/o/A1024" } } ] } } }
```
- Short: ≤ 5 items, then "และอีก 3 รายการ". Test in LINE Flex Message Simulator.

## 6. Check
- Totals add up; VAT line matches; dates in one calendar (พ.ศ. or ค.ศ.).
- Print preview: no nav, no cut rows, fits A4 / 80 mm.
- Email: Gmail + iOS Mail, light + dark. Flex: altText set, buttons open the right page.
