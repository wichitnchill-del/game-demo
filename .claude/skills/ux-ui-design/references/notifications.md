# Notifications & Popups

## 1. Pick the type

| Situation | Use |
| --- | --- |
| Done, low stakes (saved, copied) | Toast, auto-hide 3–5 s |
| Done, undoable (deleted) | Toast + "เลิกทำ", ~6 s |
| Problem in one field/section | Inline alert there |
| Page-level problem / offline | Banner on top, stays |
| Needs a decision (delete, leave unsaved) | Modal (dialog) |
| Async with result | Promise toast: loading → success/error |

Never a center modal for "บันทึกแล้ว".

## 2. Container: modal vs drawer vs bottom sheet

| Use | When |
| --- | --- |
| **Modal** | Short decision or small form (≤ 5 fields), must answer before continuing |
| **Drawer (side)** | Detail / edit while keeping the list in view (desktop), filters |
| **Bottom sheet** | Mobile: actions, choices, short forms; swipe down to close |
| **Full page** | Long form, many steps, or needs its own URL |

Mobile: modal → bottom sheet or full screen.

## 3. Modal rules
- Size: sm 400 px (confirm), md 560 px (form), lg 800 px (content). Mobile: full width.
- Title as a question/topic; body ≤ 2 lines for confirms.
- Buttons: specific verb ("ลบ", "บันทึก"), not "ตกลง". Primary right; destructive = `btn-error`.
- Close: Lucide `x` button + Esc + backdrop. Destructive/unsaved: backdrop doesn't close.
- Focus: move into modal on open, trap inside, return to trigger on close.
- Lock page scroll behind. Long content scrolls **inside** the body; header/footer fixed.
- Never stack modals. Need a second step → replace content in the same modal.
- Pending action: button loading, modal stays until result.

## 4. Confirm levels
| Risk | Pattern |
| --- | --- |
| Low, undoable | No confirm; toast + undo |
| Medium | Confirm modal: "ลบ 'โต๊ะ 5'?" + what happens |
| High, permanent | Type name to confirm, red button disabled until match |

## 5. Promo / marketing popups
- Not on first second: after ~30 s, 50 % scroll, or exit intent. Not on mobile first view.
- One per visit; closed = don't show again for ≥ 7 days (store flag).
- Easy close button (Lucide `x`, ≥ 44 px), Esc works; never block content without a close.
- Prefer a slide-in or banner over a full modal.

## 6. Messages
- ≤ 8 words. Error = what happened + what to do ("บันทึกไม่ได้ ลองใหม่อีกครั้ง").
- Max 3 toasts; newest on top; errors don't auto-hide.
- Position: top-right desktop, top-center or bottom mobile (above bottom nav).
- `aria-live="polite"` toasts, `role="alert"` errors, `role="dialog" aria-modal="true"` + `aria-labelledby`.

## 7. Common mistakes
| Mistake | Fix |
| --- | --- |
| Modal for success | Toast |
| "ตกลง / ยกเลิก" for delete | "ลบ / ยกเลิก" |
| Page scrolls behind modal | Scroll lock |
| Modal taller than screen | Scroll body inside |
| Focus lost after close | Return to trigger |
| Popup on page load | Delay / trigger |
| Modal on modal | Replace content |

## 8. daisyUI code
```html
<!-- Confirm -->
<dialog id="del" class="modal modal-bottom sm:modal-middle" aria-labelledby="del-t">
  <div class="modal-box">
    <h3 id="del-t" class="font-bold text-lg">ลบ "โต๊ะ 5"?</h3>
    <p class="py-2">ลบแล้วกู้คืนไม่ได้</p>
    <div class="modal-action">
      <form method="dialog"><button class="btn btn-ghost">ยกเลิก</button></form>
      <button class="btn btn-error">ลบ</button>
    </div>
  </div>
  <form method="dialog" class="modal-backdrop"><button>ปิด</button></form>
</dialog>
<!-- open: document.getElementById('del').showModal() -->

<!-- Toast -->
<div class="toast toast-top toast-end" aria-live="polite">
  <div class="alert alert-success">บันทึกแล้ว</div>
</div>

<!-- Side drawer for edit: use daisyUI drawer with drawer-end -->
```
`modal-bottom sm:modal-middle` = bottom sheet on mobile, centered on desktop.

## 9. Tools
- daisyUI `modal`, `toast`, `alert`, `drawer` — default.
- React: Sonner (`toast.promise`), react-hot-toast; Vaul for bottom sheets.
- Plain JS: Notyf, Toastify-js.
- SweetAlert2: only for showy confirms; restyle to theme.

## 10. Sound
- Only for events needing attention now: new order, call, timer done, critical alert.
- Never for routine success. Never autoplay on page load.
- Short (< 1 s), soft; distinct sounds per type (new order vs error), max 2–3 kinds.
- Always paired with something visible (badge, toast). Never sound-only.
- User control: on/off + volume in settings; respect device mute.
- Browsers block audio until the user clicks once → add "เปิดเสียงแจ้งเตือน" button.
- Busy places (kitchen, front desk): louder option + repeat until acknowledged.

## 11. Push notifications (browser / mobile app)
- Ask permission **after** showing value, never on first visit: own pre-prompt first
  ("รับแจ้งเตือนเมื่อออเดอร์พร้อม?" → [เปิด] [ไว้ทีหลัง]), then the system prompt.
- Send only what the user asked for or truly time-sensitive. Rarely marketing.
- Content: title ≤ 40 chars, body ≤ 90 chars, specific ("ออเดอร์ #128 พร้อมรับ").
- Tap → opens the exact screen, not home.
- Group repeats ("3 ออเดอร์ใหม่"); quiet hours at night.
- Settings: per-type toggles (orders, promos, reminders).
- Web push needs HTTPS + service worker; iOS web push only for installed PWA.

## 12. In-app notification center
- Bell icon + unread count badge (cap "99+").
- List: newest first, unread bold/dot, time ("5 นาทีที่แล้ว"), tap → target.
- "อ่านทั้งหมด", filter by type; empty state "ยังไม่มีการแจ้งเตือน".
- Real-time update (websocket/poll) without jumping the list.

## 13. Badges
- Count = items needing action, not total. Clear when handled.
- Dot for "something new", number for "how many to do".
- Not on every menu item — only where action is needed.

## 14. Other channels
| Channel | Use for |
| --- | --- |
| Email | Receipts, account, summaries; not urgent |
| SMS | OTP, critical (cost) |
| LINE OA | Thai users: booking confirm, reminders, order status |
| In-app | Everything while using the app |

Rule: same event → one main channel; let users choose. Reminder timing: e.g. booking
1 day + 1 hour before.

## 15. Notification checklist
- [ ] Each notification has a reason and a target screen
- [ ] Visible + (optional) sound, never sound-only
- [ ] Permission asked after value, with pre-prompt
- [ ] User can turn types off
- [ ] Not more than needed (group, quiet hours)
