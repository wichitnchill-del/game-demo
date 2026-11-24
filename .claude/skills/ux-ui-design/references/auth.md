# Auth (login, signup, OTP, reset, social, session)

## 1. Pick method
| Audience | Default |
| --- | --- |
| Thai consumers (shop, booking, member) | LINE Login first + phone OTP fallback |
| Inside LINE LIFF | Automatic LINE Login, no form ([platforms](platforms.md) §6) |
| B2B / admin / staff | Email + password (+ Google); 2-step (OTP or authenticator) for admin roles |
| Native iOS with Google / LINE / Facebook login | Also a privacy-focused login, e.g. Sign in with Apple (App Store 4.8) |

Passkey optional: 'เข้าสู่ระบบด้วย passkey', `autocomplete="username webauthn"`. Ask for login only when needed (guest browse / checkout first).

## 2. Screen set (design all)
| Screen | Must have |
| --- | --- |
| Login | Method buttons, field(s), 'ลืมรหัสผ่าน?', link to signup |
| Signup | Fewest fields, password checklist, terms + consent |
| OTP | Masked number, Ref, timer, attempts left |
| Forgot password | One field, same reply always |
| Reset password | New password + checklist; expired-link state |
| Social callback | 'กำลังเชื่อมต่อ LINE…'; cancel -> login + neutral note 'ยกเลิกการเข้าสู่ระบบแล้ว' |
| Session expired | Re-login modal, data kept |
| Locked | 'ลองใหม่ใน 15 นาที' + reset link |

## 3. Login
- `type="email" autocomplete="username"` (or `type="tel" autocomplete="tel"`); `type="password" autocomplete="current-password"`.
- Show/hide button: Lucide `eye` / `eye-off`, `aria-label="แสดงรหัสผ่าน"`, `aria-pressed`.
- 'ลืมรหัสผ่าน?' link right under the password field.
- 'เข้าสู่ระบบ' -> pending 'กำลังเข้าสู่ระบบ…' (spinner, no double submit); stay until auth resolves, then return to the page the user came from.
- Error: generic 'อีเมลหรือรหัสผ่านไม่ถูกต้อง' (never say which), `role="alert"`, keep the email.
- Allow paste + password managers. No CAPTCHA by default: rate-limit server-side; after repeated fails use a non-puzzle check (WCAG 3.3.8).

## 4. Signup
- Fewest fields: name + phone or email + password; the rest later.
- `autocomplete="new-password"` + live checklist under the field ('อย่างน้อย 8 ตัวอักษร' with Lucide `check` / `x` + text). Length over symbol rules; check breached passwords server-side.
- Show toggle instead of a confirm-password field.
- Links ข้อกำหนด + นโยบายความเป็นส่วนตัว. Marketing consent = separate unticked checkbox 'รับข่าวสารและโปรโมชัน' (PDPA); store consent, version, time.
- Email verification after signup; don't block first use unless required.

## 5. Phone OTP
- 'ส่งรหัสไปที่ 08x-xxx-5678' + 'เปลี่ยนเบอร์' link.
- One input `autocomplete="one-time-code" inputmode="numeric" pattern="[0-9]*" maxlength="6"`; auto-submit at 6 digits with 'กำลังตรวจสอบ…'.
- Six boxes only if the brand insists: accept paste, backspace moves back, each `aria-label="หลักที่ 1 จาก 6"`, >= 44 px.
- Show the Ref that matches the SMS ('Ref: K7QD').
- Resend disabled with countdown 'ส่งอีกครั้งใน 0:59' (60 s, not read out every second); code valid 5 min (say so); 'เหลือ 2 ครั้ง'.
- Wrong -> 'รหัสไม่ถูกต้อง', digits selected for retype. Expired -> 'รหัสหมดอายุ ขอรหัสใหม่'.
- SMS ≤ 70 chars (one Thai SMS segment): 'รหัส OTP คือ 123456 (Ref: K7QD) ใช้ได้ 5 นาที อย่าบอกผู้อื่น'.

## 6. Forgot / reset
- Same reply always: 'ถ้ามีบัญชีนี้ เราส่งลิงก์ให้แล้ว' + 'ตรวจในกล่องจดหมายขยะด้วย' + resend after 60 s.
- Link single-use, expires (e.g. 30 min) -> expired page with [ขอลิงก์ใหม่].
- New password (signup rules) -> auto-login -> toast 'เปลี่ยนรหัสผ่านแล้ว'; offer 'ออกจากระบบทุกอุปกรณ์'.

## 7. Social buttons
- Follow each brand's official button rules + assets (Lucide has no brand logos; see [build-html](build-html.md) §4).
  LINE: green `#06C755` + LINE logo + 'เข้าสู่ระบบด้วย LINE'. Google: 'ดำเนินการต่อด้วย Google'. Apple: per Apple HIG.
- Most used first; `divider` 'หรือ' before phone / email.
- Loading on the button during redirect; on return 'กำลังเข้าสู่ระบบ…' until the session is ready.
- Email matches an existing account -> 'เชื่อมบัญชี' after confirming with password / OTP; never merge silently.
- LINE returns email only with permission -> ask phone / email later if needed.

## 8. Session
- Expired mid-task -> re-login modal over the page (mobile: full screen; focus per [notifications](notifications.md) §3); keep unsaved form data; continue the action after login.
- Long forms: warn 2 min before timeout 'ยังใช้งานอยู่ไหม' [ใช้งานต่อ] (WCAG 2.2.1).
- Logout immediate, no confirm; toast 'ออกจากระบบแล้ว'.

## 9. daisyUI + wireframe
- `fieldset`, `label`, `input` (+ `validator` / `validator-hint` for format only), `join` for password + toggle, `divider`, `btn btn-block`, `alert alert-error`.
- Every button: idle / pending / success / error ([async-feedback](async-feedback.md)); field errors per [forms](forms.md); alerts per [notifications](notifications.md).

Mobile login (lo-fi, show before building; Thai lines: right border open, [ux-process](ux-process.md) Phase 4):
```
┌────────────────────┐
│       [Logo]       │
│ [เข้าสู่ระบบด้วย LINE]
│ ────── หรือ ──────
│ เบอร์มือถือ
│ [081-234-5678    ] │
│ [   ขอรหัส OTP   ]
│ ▸ สมัครสมาชิก
│ ข้อกำหนด · ความเป็นส่วนตัว
└────────────────────┘
```

## 10. Checklist
- [ ] Errors generic (login, forgot); never reveal if an account exists
- [ ] Paste + password managers work; no puzzle CAPTCHA
- [ ] OTP: `one-time-code`, Ref shown, resend timer, attempts left
- [ ] Marketing consent unticked and separate
- [ ] Every §2 screen designed, each with loading + error
