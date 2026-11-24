# Checkout & Thai payments

Cart, checkout, PromptPay / slip / card / COD, tax invoice, order status, pricing.

## 1. Flow
- cart -> checkout (one page, guest allowed) -> pay -> order status; <= 3 steps after cart.
- Guest: 'สั่งซื้อแบบไม่สมัครสมาชิก'. LINE login only to prefill ([auth](auth.md)).

## 2. Cart
- Row: image 1:1, name, option, price, qty stepper, line total, remove.
- Stepper `join`: [−] [2] [+], min 1 (− disabled at 1); Lucide `minus` / `plus`, aria-labels 'ลดจำนวน' / 'เพิ่มจำนวน'.
- Remove: `trash-2`, aria-label 'ลบ' -> toast 'ลบแล้ว' + 'เลิกทำ' ([notifications](notifications.md)).
- Qty change is async: spinner on that line; totals update after the server ([async-feedback](async-feedback.md)). Stock limit inline: 'เหลือ 2 ชิ้น'.
- Summary: ยอดสินค้า, ค่าส่ง (or 'คำนวณตอนกรอกที่อยู่' + from-price), ส่วนลด, ยอดรวม. No new costs at the last step.
- Free-shipping nudge: 'ซื้ออีก ฿120 ส่งฟรี' + `progress`.
- Mobile sticky bar: 'รวม ฿1,290' + [สั่งซื้อ], safe-area padding ([platforms](platforms.md)).
- Empty: 'ตะกร้ายังว่าง' + [เลือกซื้อสินค้า]. Keep cart across visits.

```html
<div class="join">
  <button class="btn join-item" aria-label="ลดจำนวน"><i data-lucide="minus" aria-hidden="true"></i></button>
  <input class="input join-item w-14 text-center" inputmode="numeric" value="2" aria-label="จำนวน" />
  <button class="btn join-item" aria-label="เพิ่มจำนวน"><i data-lucide="plus" aria-hidden="true"></i></button>
</div>
```

## 3. Checkout (one page, this order)
1. ติดต่อ: ชื่อ-นามสกุล, เบอร์มือถือ (couriers need it), อีเมล optional; `autocomplete` name / tel / email ([forms](forms.md)).
2. ที่อยู่จัดส่ง: postcode first -> ตำบล/อำเภอ/จังหวัด autofill ([forms](forms.md) Thai data); saved addresses; 'รับที่ร้าน'.
3. การจัดส่ง: radio cards, price + ETA ('Flash Express ฿40 · 1–2 วัน', KEX, J&T, ไปรษณีย์ไทย EMS; Lalamove / Grab for same-day local).
4. การชำระเงิน (§4).
5. หมายเหตุถึงร้าน: optional, collapsed.
6. 'ขอใบกำกับภาษี' `toggle` -> ชื่อบริษัท/ชื่อ, เลขประจำตัวผู้เสียภาษี 13 หลัก (checksum, `inputmode="numeric"`), สำนักงานใหญ่ / สาขาที่ (5 digits, e.g. 00001), ที่อยู่ใบกำกับ + 'ใช้ที่อยู่จัดส่ง' checkbox (WCAG 3.3.7).
7. 'มีโค้ดส่วนลด?' link -> input + [ใช้โค้ด] with loading + inline result.

- Order summary: side column on desktop; collapsible on top on mobile.
- Button = result + amount: 'ชำระเงิน ฿1,290' -> pending 'กำลังสร้างคำสั่งซื้อ…'.
- Create the order once: disabled while pending + idempotency key.

## 4. Methods
PromptPay first for Thai consumers.

| Method | UI | Confirmation |
| --- | --- | --- |
| PromptPay QR (dynamic, via gateway) | Amount, receiver name, countdown from gateway expiry ('ชำระภายใน 14:59'), [บันทึก QR], 3 steps (same phone: save -> open bank app -> scan from gallery) | Auto via gateway webhook -> page flips to 'ชำระเงินแล้ว' |
| Bank transfer | Bank, account name, number + [คัดลอก] (`copy`, toast 'คัดลอกแล้ว'), amount; slip upload with preview + progress ([forms](forms.md) upload) | 'รอตรวจสอบสลิป'; slip-check service (reads slip QR) or staff review |
| Card | Gateway-hosted fields / page only (Opn Payments (Omise), 2C2P, GB Prime Pay, Stripe); never own card inputs | 3-D Secure redirect 'กำลังไปยังหน้ายืนยันของธนาคาร…' -> status page |
| TrueMoney Wallet / mobile banking | Via gateway | Pending until callback |
| COD เก็บเงินปลายทาง | Fee + max amount shown before choosing; phone confirm | 'รอจัดส่ง' |

Static PromptPay QR / personal PromptPay ID cannot auto-confirm -> treat as bank transfer.

## 5. Payment states (design every row)

| State | UI |
| --- | --- |
| รอชำระ | QR / details + countdown; after 2 min help link 'ชำระแล้วแต่ยังไม่อัปเดต?' |
| กำลังตรวจสอบ | Spinner 'กำลังตรวจสอบการชำระเงิน…' (poll / websocket); never 'สำเร็จ' yet |
| ชำระแล้ว | `check` + order number + what happens next |
| QR หมดอายุ | 'QR หมดอายุ' + [สร้าง QR ใหม่] (same order) |
| ไม่สำเร็จ | Reason + [ลองอีกครั้ง] + [เปลี่ยนวิธีชำระ]; cart kept; `role="alert"` |
| รอตรวจสลิป | 'ได้รับสลิปแล้ว ร้านจะตรวจภายใน …' |

Rules: success only after the server confirms. Order page link sent by LINE / SMS / email ([notifications](notifications.md) §14). Guests look up by order number + phone.

## 6. Order status
- daisyUI `steps` (or `timeline`): รอชำระ -> ชำระแล้ว -> กำลังเตรียม -> จัดส่งแล้ว -> สำเร็จ, each with time. Mobile `steps-vertical`.
- Shipped: carrier + tracking number [คัดลอก] + 'ติดตามพัสดุ' link.
- Cancel / refund: reason, refund method, ETA.
- Contact shop (LINE OA / โทร) in the same place on every order page (WCAG 3.2.6).

## 7. Money
- `Intl.NumberFormat('th-TH',{style:'currency',currency:'THB',minimumFractionDigits:0,maximumFractionDigits:0})` -> '฿1,290'; 2 decimals when satang matter. Display only: charge the exact server amount.
- `tabular-nums`; totals right-aligned. State 'ราคารวม VAT แล้ว' or '+ VAT 7%'. Discounts: '−฿100'.

## 8. Pricing / packages (services, SaaS)
- <= 3 plans; middle one `badge` 'แนะนำ'. Monthly / yearly toggle showing the saving ('ประหยัด 2 เดือน').
- Price + period + VAT note; 3–5 bullets each; one CTA per plan.
- Compare table below. FAQ: ใบกำกับภาษี, ยกเลิกได้ไหม, ชำระทางไหนได้.

## 9. Wireframe, icons, a11y
Mobile samples (Thai lines: right border open, [ux-process](ux-process.md) Phase 4):
```
┌────────────────────┐
│ ติดต่อ
│ ที่อยู่จัดส่ง
│ การจัดส่ง ( )( )
│ การชำระเงิน
│ ใบกำกับภาษี [ ]
├────────────────────┤
│ [ ชำระเงิน ฿1,290 ]  ← sticky
└────────────────────┘
```
```
┌────────────────────┐
│ ยอดชำระ ฿1,290
│ ┌──────────┐       │
│ │    QR    │       │
│ └──────────┘       │
│ ชำระภายใน 14:59
│ [ บันทึก QR ]
│ รอชำระ…
└────────────────────┘
```
- Lucide: `shopping-cart`, `minus`, `plus`, `trash-2`, `qr-code`, `copy`, `upload`, `truck`, `package-check`, `receipt`, `credit-card`, `wallet`, `store`.
- Countdown updates visually each second; `aria-live` announces only at 5 and 1 min left (same as [booking](booking.md)).
- QR text alternative: amount + receiver + 'สแกนด้วยแอปธนาคาร'.
- Targets 44 px; sticky pay bar never covers the focused field (WCAG 2.4.11, [accessibility](accessibility.md)).
- PDPA: ask only what delivery / tax needs; never store card data.

## 10. Checklist
- [ ] No hidden costs; total final before the last step
- [ ] Guest checkout works
- [ ] Every §5 state designed
- [ ] No double order (disabled + idempotency key)
- [ ] Tracking number copyable
