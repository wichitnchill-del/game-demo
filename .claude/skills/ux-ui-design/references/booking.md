# Booking, queue & time slots

Appointment, table, walk-in queue, rental, admin calendar.

## 1. Pattern
| Business | Flow |
| --- | --- |
| Salon, clinic, spa, repair (appointment) | service -> staff ('ใครก็ได้ (เร็วสุด)') -> date -> slot -> details -> confirm |
| Restaurant (table) | party size -> date -> time -> (zone) -> details -> confirm |
| Walk-in queue (clinic, bank, food stall) | get number -> live position -> called |
| Rental / hotel / room | date range -> item -> details -> deposit |

In LINE -> LIFF ([platforms](platforms.md) §6): no login form, name from the LINE profile.

## 2. Service + staff
- Service first (it sets duration): 'ตัดผมชาย · 45 นาที · ฿250'; grouped by category.
- Staff: photo, name, next free time; default 'ใครก็ได้'.

## 3. Date
- Mobile: 14-day chip strip (scroll-x): 'วันนี้', 'พรุ่งนี้', then 'พฤ. 26' (dates are examples: today = อ. 24 พ.ย.).
- Desktop: month calendar = daisyUI `cally` class on Cally `<calendar-date>` (module script, pin `cally@0.9.2`), or a plain button grid.
- Day names: `Intl.DateTimeFormat('th-TH',{weekday:'narrow'})` -> 'พฤ' ('short' gives 'พฤหัส'); add '.' if the style wants 'พฤ.'.
- Pick the week start (อา. common on Thai calendars, จ. for business); same everywhere.
- Closed / full days: `disabled` (or `aria-disabled="true"` to keep focus) + visible mark ('ปิด' / 'เต็ม' or strike), never color only.
- th-TH formats in พ.ศ. ('26 พ.ย. 2569'); `th-TH-u-ca-gregory` if the product uses ค.ศ. Store ISO dates.

```html
<script type="module" src="https://unpkg.com/cally@0.9.2"></script>
<calendar-date class="cally" locale="th-TH" first-day-of-week="0">
  <calendar-month></calendar-month>
</calendar-date>
```

## 4. Slots
- Button grid grouped 'เช้า / บ่าย / เย็น', buttons >= 44 px ([accessibility](accessibility.md)); 24-h '13:30' ('เวลา 13:30 น.' in sentences).
- Full -> disabled 'เต็ม'; few left -> 'เหลือ 1'.
- None -> 'วันนี้เต็มแล้ว' + [ว่างวันถัดไป: ส. 28 พ.ย.] jump.
- Changing date -> skeleton slots in the same layout, never blank ([async-feedback](async-feedback.md)).
- Display in Asia/Bangkok; store UTC / ISO.
- Selected: `btn-primary` + `aria-pressed="true"`; `aria-label="ส. 28 พ.ย. 13:30 ว่าง"`.

## 5. Hold & conflict
- After a pick: hold ~10 min, countdown 'จองไว้ให้ 9:59'; 1 min left -> [ขอเวลาเพิ่ม] (WCAG 2.2.1); expiry -> 'หมดเวลาจอง' + pick again (details kept).
- Conflict at confirm: 'เวลานี้มีคนจองแล้ว' + 3 nearest free slots; keep all entered details.
- [ยืนยันการจอง] -> pending 'กำลังจอง…'; one booking per click (idempotent request).

## 6. Details, policy, deposit
- Name, phone ([forms](forms.md) Thai data), note; members prefilled (WCAG 3.3.7).
- Cancel / reschedule policy visible before confirm: 'ยกเลิกฟรีก่อน 24 ชม.'.
- Deposit -> PromptPay flow + payment states in [checkout-payment](checkout-payment.md) §5; extend the hold to the QR expiry.

## 7. Confirmation
- Summary: service, staff, date/time, place + map link, price / deposit; code 'BK-2481'.
- [เพิ่มลงปฏิทิน]: `.ics` download + Google Calendar link.
- LINE OA reminder opt-in; reminders 1 day + 1 hour before ([notifications](notifications.md) §14).
- Manage by link, no login: [เลื่อนนัด] [ยกเลิก] (confirm modal + policy).

## 8. Walk-in queue
- Ticket: big 'A023', 'อีก 3 คิว' + 'ประมาณ 15 นาที'; live update without jumps (`aria-live="polite"`); LINE OA message at 2 ahead; [ยกเลิกคิว].
- Shop TV: current number huge, next 3, sound on call ([notifications](notifications.md) §10).
- Staff: [เรียกคิวถัดไป] [ข้าม] [เรียกซ้ำ], 48 px targets.
- [รับคิว], [ยกเลิกคิว], staff buttons: pending state + no double call ([async-feedback](async-feedback.md)).

## 9. Admin calendar
- Day view (staff columns x 15 / 30-min rows) + week view; mobile = today list.
- Block: time, customer, service, status `badge` with text: ยืนยัน / มาแล้ว / ไม่มา / ยกเลิก.
- Drag to move / resize -> confirm 'ย้ายนัดคุณเอไป 14:00?'; always a click alternative [ย้ายเวลา] (WCAG 2.5.7).
- Block time ('ปิดช่วงพัก'), quick walk-in add, no-show count per customer. Tables / KPIs per [admin-dashboard](admin-dashboard.md).

## 10. A11y, icons, wireframe
- Calendar keys: arrows move days, Enter selects, Page Up / Down months; focus visible ([accessibility](accessibility.md)).
- Countdown announced only at 5 and 1 min, not every second.
- Lucide: `calendar-days`, `clock`, `user-round`, `map-pin`, `ticket`, `bell`.

Mobile wireframe (right border open on Thai lines):
```
┌──────────────────────
│ ‹  จองคิว
│ ตัดผมชาย · 45 นาที
│ [วันนี้][พรุ่งนี้][พฤ.26]›
│ เช้า
│ [09:00] [เต็ม ] [10:30]
│ บ่าย
│ [13:00] [13:30] [เหลือ1]
├──────────────────────
│ [   ยืนยันการจอง   ]
└──────────────────────
```

## 11. Checklist
- [ ] Service sets duration; slots match it
- [ ] Disabled / full is not color-only
- [ ] Hold expiry + conflict handled, details kept
- [ ] Policy visible before confirm
- [ ] Reminder opt-in + manage link
