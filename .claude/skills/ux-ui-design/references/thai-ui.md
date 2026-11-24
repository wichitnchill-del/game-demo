# Thai UI

## Fonts
- Body: IBM Plex Sans Thai, Noto Sans Thai, Sarabun, Anuphan.
- Display: Kanit, Prompt, Mitr (headings only).
- Pair Thai font with a matching Latin face; check digits and English look right.

## Size & spacing
- Thai needs more height: line-height 1.6–1.8 body, ≥ 1.3 headings.
- Body ≥ 16 px; don't go below 14 px.
- Leave room for vowels/tone marks above and below (no tight `leading-none`).

## Line breaks
- Thai has no spaces between words: use `word-break: normal; line-break: auto;`
  and test long text. Add `<wbr>` or zero-width space in long labels if needed.
- Avoid `text-justify`.

## Copy
- Short, polite, plain. Drop "กรุณา" when the button is clear ("บันทึก", not "กรุณากดบันทึก").
- Buttons = verbs: บันทึก, ลบ, เพิ่ม, ยกเลิก.
- Use the words users say (คนไข้ / ลูกค้า / สมาชิก — ask which).
- Dates: Thai or Gregorian year — pick one per product, state it.
- Numbers: Arabic digits; ฿ before or "บาท" after, consistent.

## Common AI mistakes
- Vowels/tone marks clipped (่ ้ ิ ี ึ ื): fixed height or tight line-height → use min-height, line-height ≥ 1.6.
- Thai labels longer than English ("บันทึกการเปลี่ยนแปลง" vs "Save") → no fixed widths; test real Thai text.
- Font without Thai glyphs → pick a Thai-capable font above.

## Language switch (TH / EN)
- Place: header right (desktop), drawer or footer (mobile) + in settings.
- Label in each language's own name: `ไทย · English` (or `TH / EN`). No flags.
- Switch stays on the same page and scroll; remember the choice (cookie / account).
- First visit: browser language, never IP. URLs: `/en/...` so each language can be shared.
- `<html lang="th">` / `lang="en"`; per-language font via `:lang(th)`, `:lang(en)`.
- Formats from locale: `Intl.DateTimeFormat('th-TH')` (พ.ศ.) / `'en-GB'`, `Intl.NumberFormat`.
- Layouts must fit both: test the longer text in each place; no fixed widths.
- Translate everything incl. errors, emails, alt text, meta. Missing key → show Thai, log it.
