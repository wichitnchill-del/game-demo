# Account Settings & Privacy (PDPA)

Not legal advice — have the client's lawyer confirm PDPA wording.

## 1. Structure
Sidebar (desktop) / list → sub-page (mobile). Groups:

| Group | Items |
| --- | --- |
| โปรไฟล์ | ชื่อ, รูป, เบอร์, อีเมล |
| ความปลอดภัย | รหัสผ่าน, ยืนยัน 2 ขั้น, อุปกรณ์ที่เข้าใช้, ออกจากระบบทุกเครื่อง |
| การแจ้งเตือน | ช่องทาง × เรื่อง (toggle grid) — [notifications](notifications.md) |
| ภาษาและการแสดงผล | ไทย / English, ธีมสว่าง / มืด — [thai-ui](thai-ui.md#language-switch-th--en) |
| ความเป็นส่วนตัว | ความยินยอม, คุกกี้, ดาวน์โหลดข้อมูล, ลบบัญชี |
| การชำระเงิน | บัตร / วิธีจ่าย, ใบเสร็จ — [receipts](receipts-print-email.md) |

## 2. Save pattern
- Save per section ("บันทึก" in each card), not one giant save at the bottom.
- Toggles save instantly + toast "บันทึกแล้ว"; revert on fail.
- Pending / success / error per section ([async-feedback](async-feedback.md)). Unsaved → confirm on leave.

## 3. Sensitive changes
- Email / phone / password / 2FA → re-auth (password or OTP) first.
- New email/phone: verify the new one before switching; notify the old one.
- Sessions list: device, place, last active, "ออกจากระบบ" per row + "ทุกเครื่อง".

## 4. Delete account
1. Explain what's lost + what's kept by law (e.g. tax records).
2. Offer "ดาวน์โหลดข้อมูล" first.
3. Re-auth → type "ลบบัญชี" to confirm → danger button.
4. Grace period (e.g. 30 days) + email to undo.
Button `btn-error`, never primary color; away from other actions.

## 5. PDPA consent
- Separate from terms: own checkbox per purpose, **unticked** by default.
- Plain Thai: what data, why, who sees it, how long. Link full privacy policy.
- Withdraw as easy as give: same toggles in ความเป็นส่วนตัว.
- Marketing consent ≠ required to use the service.
- Rights page: ขอดู / แก้ไข / ลบ / โอนย้ายข้อมูล / คัดค้าน — each a clear action or form.
- Record: what was agreed, version, time.

## 6. Cookie banner
- Bottom bar, doesn't block content; no cookies (except necessary) before choice.
- 3 buttons, equal weight: **ยอมรับทั้งหมด · ปฏิเสธ · ตั้งค่า**. No pre-ticked boxes.
- ตั้งค่า: จำเป็น (always on, locked) · วิเคราะห์ · การตลาด — each toggle + 1-line why.
- Re-open from footer link "ตั้งค่าคุกกี้".

```html
<div role="region" aria-label="คุกกี้" class="fixed inset-x-0 bottom-0 z-50 bg-base-200 p-4">
  <div class="max-w-5xl mx-auto flex flex-col md:flex-row gap-3 md:items-center">
    <p class="flex-1 text-sm">เราใช้คุกกี้เพื่อให้เว็บทำงานและปรับปรุงบริการ <a class="link" href="/privacy">อ่านเพิ่ม</a></p>
    <div class="flex gap-2">
      <button class="btn btn-sm">ตั้งค่า</button>
      <button class="btn btn-sm">ปฏิเสธ</button>
      <button class="btn btn-sm btn-primary">ยอมรับทั้งหมด</button>
    </div>
  </div>
</div>
```
Equal weight: if "ยอมรับ" is primary, keep "ปฏิเสธ" same size and as visible.

## 7. Check
- Every setting has a visible current value; every save shows result.
- Mobile: each group is its own page with back; no horizontal scroll.
- Keyboard + screen reader: toggles are `<input type="checkbox" role="switch">` with labels.
