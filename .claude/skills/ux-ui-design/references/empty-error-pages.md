# Empty & Error Pages

Every screen needs these. One look, one formula, every page.

## 1. Formula
Icon (Lucide) → title ≤ 6 words → 1 line why / what next → 1 primary action (+ 1 link).
No blame, no jokes on errors, no raw codes up front (small ref ID for support is fine).

## 2. Empty states

| Type | Title | Action |
| --- | --- | --- |
| First use | ยังไม่มีออเดอร์ | เพิ่มออเดอร์แรก |
| No results | ไม่พบ "{คำค้น}" | ล้างตัวกรอง · ตรวจคำสะกด |
| Cleared / done | เคลียร์ครบแล้ว | กลับหน้าหลัก |
| No permission | ไม่มีสิทธิ์ดูหน้านี้ | ขอสิทธิ์จากผู้ดูแล |
| Filtered to zero | ไม่มีรายการในช่วงนี้ | ดูทั้งหมด |

- First use teaches: 1 line on what will appear + the button that makes it.
- Keep the page frame (nav, header, filters) — only the content area changes.
- Tables: empty row area, keep column headers.

## 3. Error pages

| Case | Title | Body | Actions |
| --- | --- | --- | --- |
| 404 | ไม่พบหน้านี้ | ลิงก์อาจเก่าหรือพิมพ์ผิด | กลับหน้าแรก · ค้นหา |
| 500 | ระบบขัดข้องชั่วคราว | ลองใหม่อีกครั้ง ข้อมูลของคุณยังอยู่ | ลองอีกครั้ง · ติดต่อเรา |
| 403 | ไม่มีสิทธิ์เข้าถึง | บัญชีนี้ดูหน้านี้ไม่ได้ | เปลี่ยนบัญชี · กลับ |
| Offline | ไม่มีอินเทอร์เน็ต | เชื่อมต่อแล้วจะโหลดให้เอง | ลองอีกครั้ง |
| Maintenance (503) | ปิดปรับปรุงถึง 14:00 น. | บอกเวลากลับมา | ช่องทางติดต่อ |
| Session expired | หมดเวลาการใช้งาน | เข้าสู่ระบบอีกครั้ง ข้อมูลที่กรอกยังอยู่ | เข้าสู่ระบบ |
| Payment / action failed | ชำระเงินไม่สำเร็จ | ยังไม่ถูกตัดเงิน + เหตุผล | ลองอีกครั้ง · เปลี่ยนวิธี |

- Real HTTP status (404 page returns 404, not 200). Maintenance: 503 + `Retry-After`.
- 404: show nav + search; log the broken URL.
- Session expired: keep form data, return to the same page after login ([auth](auth.md)).
- Offline: keep last data visible, dimmed + banner; auto-retry when back ([async-feedback](async-feedback.md)).

## 4. Inline errors (not full page)
- Part failed → error in that card only, with "ลองอีกครั้ง"; rest of page works.
- Say what's safe: "ยังไม่ได้บันทึก" / "ยังไม่ถูกตัดเงิน".

## 5. Look
- Centered in the content area, max-width ~28rem, icon 48 px in `text-base-content/50`.
- Same theme as the app. No stock 404 art, no emoji.
- `role="alert"` only for errors that appear after an action, not on page load.

```html
<div class="flex flex-col items-center text-center gap-3 py-16 max-w-md mx-auto">
  <i data-lucide="inbox" class="size-12 text-base-content/50"></i>
  <h2 class="text-lg font-semibold">ยังไม่มีออเดอร์</h2>
  <p class="text-base-content/70">ออเดอร์ใหม่จะแสดงที่นี่</p>
  <button class="btn btn-primary">เพิ่มออเดอร์แรก</button>
</div>
```

## 6. Check
- Each screen: empty, no results, error, offline, no permission — all designed.
- Long Thai search terms don't break the title (truncate with `…`).
