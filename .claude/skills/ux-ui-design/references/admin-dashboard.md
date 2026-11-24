# Admin / Dashboard

## Sidebar
- Group by job; most-used group on top. Max ~4 items per group.
- Labels 1–3 words, in users' own words. Lucide icons, no emoji.
- Badges for pending work (counts, `!`); icon + color, never color only.
- Bottom: settings, help, user, sign out.
- Collapsible to icons (tooltip); mobile = drawer. Patterns: [navigation](navigation.md).
- Active: bg + bar + `aria-current="page"`.
- Show only what the role may use.

Order examples:
- Clinic: today → appointments, queue, patients → billing → stock → staff → reports
- Restaurant: today → orders, tables, kitchen, bookings → menu → billing, shift close → stock → staff → reports

## Dashboard home
- "Today" first: 3–5 numbers that need action, not vanity stats.
- Each number links to its list.
- Empty, loading (skeleton), error states; KPI and chart rules below.

## Tables
- Text left; numbers/money right + `tabular-nums`; dates one fixed format; status = `badge` + text (+ icon), never color only.
- Columns: ID/name first, key status next, actions last; ≤ 7 columns (rest in a row drawer or 'คอลัมน์' toggle).
- daisyUI `table table-pin-rows` (sticky header), `table-pin-cols` for wide tables, `table-zebra` optional, `table-sm` density toggle for power users.
- Long text `truncate` + `title`; IDs/order numbers `whitespace-nowrap`.
- Sort key columns with `aria-sort`; Thai text with `Intl.Collator('th').compare` (plain `sort()` puts 'เกศินี' after 'ขนม').
- Search + 2–3 key filters visible, rest in 'ตัวกรองเพิ่มเติม'. Search: substring on trimmed, lower-cased text; 300 ms debounce; old rows dimmed while loading ([forms](forms.md)).
- States: 5 skeleton rows / empty + CTA ('ยังไม่มีออเดอร์' + [เพิ่มออเดอร์]) / no results with the query echoed + [ล้างตัวกรอง] / error row + [ลองใหม่].
- Select: checkbox column; header box = this page, then link 'เลือกทั้งหมด 345 รายการ'; bulk bar 'เลือก 3 รายการ' + actions; destructive bulk → confirm ([notifications](notifications.md) §4).
- Pagination '1–20 จาก 345' + page size 20/50/100; page, sort and filters in the URL.
- Row actions: 1 visible, rest in `dropdown` (`ellipsis`, aria-label 'ตัวเลือกเพิ่มเติม'). Inline edit for single fields only (Enter saves, Esc cancels, saving state).
- Export: CSV with UTF-8 BOM (`'\uFEFF' + csv`) so Excel shows Thai, or XLSX (SheetJS); big export = background job + progress toast + download link; filename 'orders-2026-11-24.csv'.
- Mobile (< 768 px): cards with 2–3 key fields + status badge + `chevron-right`, not squeezed tables.

```js
rows.sort((a, b) => new Intl.Collator('th').compare(a.name, b.name));
const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8' });
```

## Charts
| Question | Chart |
| --- | --- |
| Trend over time | Line |
| Compare categories | Bar (horizontal for long Thai labels) |
| Part of whole, ≤ 5 parts | Stacked / 100 % bar (donut rarely; no pie > 5) |
| Distribution | Histogram |
| One number | `stat` |
| Target vs actual | Bar + target line, or `progress` |

- Bars start at 0; ≤ 5 colors from theme tokens (primary, secondary, accent, neutral, info) + grey for 'อื่น ๆ'; direct labels over legends; no 3D, no dual axes.
- Show the previous period (dashed line / grey bar).
- States: skeleton of the same height; empty 'ยังไม่มีข้อมูลช่วงนี้' + change range; error + [ลองใหม่].
- A11y: 1-line text summary above ('ยอดขายสัปดาห์นี้ ฿48,200 เพิ่ม 12% จากสัปดาห์ก่อน'); [ดูเป็นตาราง] toggle; canvas `role="img"` + `aria-label`; not color only.
- Libraries: plain HTML → Chart.js (pin a version, e.g. `chart.js@4.6.1`) or ApexCharts; React → Recharts; heavy data / maps → ECharts. Set the lib's font to the page Thai font ([thai-ui](thai-ui.md)).
- Colors: read tokens, don't hard-code. Values are oklch; if a lib can't parse them, convert via a 1x1 canvas. Re-render on theme change with a `MutationObserver` on `data-theme`.

```js
const css = (v) => getComputedStyle(document.documentElement).getPropertyValue(v).trim();
const primary = css('--color-primary'); // oklch(...)
new MutationObserver(redraw).observe(document.documentElement, { attributes: true, attributeFilter: ['data-theme'] });
```

## Thai number / date formats (one compact style per product)
| Need | Code | Output |
| --- | --- | --- |
| Money | `'฿' + n.toLocaleString('th-TH')` | ฿48,200 |
| Compact (long) | `Intl.NumberFormat('th-TH',{notation:'compact',compactDisplay:'long'})` | 1.2 พัน / 1.2 หมื่น / 1.2 แสน / 1.2 ล้าน |
| Compact (short, dense views) | same, `compactDisplay:'short'` | 1.2K / 1.2M |
| Axis date | `Intl.DateTimeFormat('th-TH',{day:'numeric',month:'short'})` | 26 พ.ย. |

## KPI stats
3–5 that need action. daisyUI `stats` / `stat` (`stat-title`, `stat-value`, `stat-desc`): label, value, delta with sign + `trending-up` / `trending-down` icon + text (not color only), period 'เทียบสัปดาห์ก่อน'; each links to its list.

## Roles
List roles → map each to menu items + actions before designing.

## Busy environments (shops, clinics, kitchens)
- Tablet first, targets ≥ 48 px.
- New items: badge + sound + toast (`aria-live`).
- Every action shows loading at once ([async-feedback](async-feedback.md)).

## Output
1. Role → menu: `| Role | Menu items | Actions |`
2. Sidebar ASCII sketch.
3. Home KPI list.
4. Main table spec: `| Column | Type | Align | Sort |`
5. Lo-fi wireframe (desktop + mobile) → OK before code.
