# Forms

## Layout
- One column. Label above field. Group related fields.
- Ask only what's needed; mark optional, not required (if most are required).
- Right input type + `autocomplete` (`name`, `tel`, `email`, `address-line1`, `postal-code`).
- Width hints the length (postcode short, address wide).

## Validation
- Validate on blur, re-check on change after an error.
- Error under the field: what's wrong + how to fix.
- On submit: focus first error; summary at top if > 3 errors.
- Never clear input on error. Don't block typing; format after.

## Submit
- Button says the result ("สมัครสมาชิก", "บันทึก").
- Pending: disabled + spinner + "กำลังบันทึก…". Form stays open until confirmed ([async-feedback](async-feedback.md)).
- Success: toast or next page.
- Unsaved changes → confirm before leaving (`beforeunload` + in-app nav guard).

## Thai data

| Field | Rule | Error text |
| --- | --- | --- |
| เบอร์มือถือ | 10 digits, starts 0; `inputmode="tel"`; show `081-234-5678` | เบอร์ต้องมี 10 หลัก |
| เลขบัตรประชาชน | 13 digits + checksum; `inputmode="numeric"`; show `1-2345-67890-12-3` | เลขบัตรไม่ถูกต้อง ตรวจอีกครั้ง |
| ที่อยู่ | Postcode first → auto-fill ตำบล/อำเภอ/จังหวัด (select, searchable) | เลือกตำบล |
| วันที่ | Pick พ.ศ. or ค.ศ. per product; date picker + typed fallback | วันที่ไม่ถูกต้อง |
| ชื่อ | One "ชื่อ-นามสกุล" field unless split is needed; no title dropdown unless required | กรอกชื่อ |
| อีเมล | `type="email"`; trim spaces | รูปแบบอีเมลไม่ถูกต้อง |
| เงิน | `inputmode="decimal"`; show ฿ and commas | กรอกจำนวนเงิน |

## Multi-step
- Use when > ~8 fields or distinct topics. 3–5 steps max.
- Show "ขั้น 2 จาก 3" + step names. Back keeps data.
- Validate per step; save draft (local or server) so refresh doesn't lose data.
- Last step: review summary with "แก้ไข" links.

## Mobile
- Right keyboard: `inputmode` (tel, numeric, decimal, email).
- Field scrolls into view above keyboard; no fixed elements covering it.
- Primary button sticky at bottom (safe-area padding).
- Inputs ≥ 16 px font (prevents iOS zoom); targets ≥ 44 px.
- `enterkeyhint="next"` / `"done"`.

## File / image upload
- Drop zone + "เลือกไฟล์" button. State allowed types + max size before upload.
- Preview (image thumb / file name + size), remove (Lucide `x`), per-file progress, retry on fail.
- Check type/size on client, but trust server checks.

## Search & filter forms
- Search: instant results after ~300 ms pause; keep old results dimmed while loading.
- 2–3 key filters visible, rest in "ตัวกรองเพิ่มเติม" (drawer on mobile).
- Show active filters as chips with Lucide `x` + "ล้างทั้งหมด". Keep filters in URL.

## A11y
- `<label for>`, `aria-describedby` (hint + error), `aria-invalid="true"`, `required`.
- Placeholder is an example, never the label.
- Error not by color only: icon + text.

## Common mistakes
| Mistake | Fix |
| --- | --- |
| Placeholder as label | Visible label |
| Error only on submit, at top | Inline on blur |
| Form clears after error | Keep values |
| Two primary buttons | One primary, one ghost |
| "Submit" / "ตกลง" button | Say the result |
| Asking title/gender/birthday for no reason | Remove |

## daisyUI example
```html
<form class="max-w-md space-y-4" novalidate>
  <fieldset class="fieldset">
    <label class="label" for="phone">เบอร์มือถือ</label>
    <input id="phone" name="phone" type="tel" inputmode="tel" autocomplete="tel"
      class="input w-full" placeholder="081-234-5678" required
      aria-describedby="phone-err" aria-invalid="true" />
    <p id="phone-err" class="text-error text-sm">เบอร์ต้องมี 10 หลัก</p>
  </fieldset>
  <button class="btn btn-primary w-full" type="submit">
    <span class="loading loading-spinner loading-sm hidden"></span> บันทึก
  </button>
</form>
```
