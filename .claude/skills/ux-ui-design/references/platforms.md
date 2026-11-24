# Platforms

Desktop web, mobile web, PWA, LINE LIFF, iOS, Android, incl. the native-app path.

## 1. Ask first (only if unknown; counts toward the 3-question limit)
`ใช้ที่ไหน: เว็บ (คอม / มือถือ) · แอปจริง (iOS / Android) · ใน LINE` + `มีโค้ดเดิมไหม`.
Unknown -> assume responsive web, mark **[assumed]**.

## 2. Pick

| Need | Build | Why |
| --- | --- | --- |
| Most Thai SME sites, no install | Responsive web (daisyUI) | Cheapest, shareable link, SEO |
| Repeat use, home-screen icon, light offline | PWA | No app store |
| Customers already in a LINE OA (shop, booking, queue, member card, coupon) | LINE LIFF (web app inside LINE) | No signup (LINE Login), easy share, OA messages |
| Heavy offline, hardware (Bluetooth thermal printer, NFC, fast barcode scan), store presence, background location / push | Native: SwiftUI / Jetpack Compose, or Flutter / React Native for both | Needs OS access the web lacks |

Rule: default web or LIFF; go native only with one of those reasons written down.

## 3. Per platform

| Platform | Nav | Targets | Sheets / dialogs | Back | Main action | Type |
| --- | --- | --- | --- | --- | --- | --- |
| Desktop web | Top `navbar` or sidebar ([navigation](navigation.md)) | 24 px AA floor, 44 px default | `modal`, side `drawer` | Browser back works; breadcrumbs in deep admin | Page top-right or end of form | Body 16 px; hover + keyboard shortcuts OK; content max-w ~1280 px |
| Mobile web | Top bar + `drawer`; app-like: `dock` 3-5 ([navigation](navigation.md)) | 44 px | `modal modal-bottom` sheet or full-screen page | Every sheet / step gets a URL or hash so browser back closes it, not the site | Sticky bottom button + safe area | Inputs >= 16 px (no iOS zoom) |
| iOS (HIG) | Tab bar 3-5 + navigation bar with back chevron; large title on top-level screens | 44 pt | Sheets with detents (medium / large); action sheet for destructive choices | Never block edge swipe-back | Nav-bar right button or bottom button | SF + system Thai fallback or bundled Thai font; Dynamic Type |
| Android (Material 3) | Navigation bar 3-5 (rail on tablet, drawer when many) + top app bar | 48 dp | Bottom sheet, dialog; snackbar at bottom for results | System back + predictive back must work | FAB for the main create action | Noto Sans Thai; font scale |

## 4. Mobile web musts
- `<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">`.
- Full height `min-h-dvh` (100dvh), never `h-screen` / 100vh (jumps under the URL bar).
- Safe area: `pb-[env(safe-area-inset-bottom)]` on sticky bottom bars (daisyUI `dock` pads it; needs `viewport-fit=cover`).
- No hover-only UI.
- Sticky header / bottom bar must not cover the focused field: `scroll-padding` on `html` (WCAG 2.4.11, [accessibility](accessibility.md)).
- Test Safari iOS, Chrome Android, and LINE / Facebook in-app browsers (shared links open there).

## 5. PWA
- `manifest.webmanifest`: `name`, `short_name` (<= 12 chars), `start_url`, `display: standalone`, icons 192 + 512 + maskable 512, `theme_color` / `background_color` from the theme (primary / base-100).
- Own button 'ติดตั้งแอป' only after value (2nd visit or first finished task). Android / desktop Chrome: `beforeinstallprompt`. iOS Safari has no prompt API: show steps 'แตะ แชร์ > เพิ่มไปยังหน้าจอโฮม'.
- Service worker caches app shell + offline page ('ไม่มีอินเทอร์เน็ต' + [ลองใหม่]); never queue payments silently.
- Standalone has no browser back / URL bar -> in-app back (`chevron-left`) on every sub-page; share button where links matter.
- iOS web push only after install ([notifications](notifications.md) §11).

## 6. LINE LIFF
- View size: `full` for multi-step flows; `tall` / `compact` for quick actions (pick a slot, show a coupon).
- LINE draws the header (title + close): no own header with logo / close; set `<title>`.
- Login is automatic in LINE: `liff.init()` -> `liff.getProfile()`; loading screen during init (4 states, [async-feedback](async-feedback.md)); outside LINE `liff.login()`. Never a password form; email / phone rules in [auth](auth.md).
- Done -> confirmation screen + [กลับไปที่แชท] calling `liff.closeWindow()`. `liff.sendMessages()` only when opened from a chat; share via `liff.shareTargetPicker()`.
- daisyUI works as on mobile web. Test in the LINE in-app browser on iOS + Android (font, safe area, keyboard); external links open inside LINE.

## 7. Native (SwiftUI / Compose / Flutter / React Native)
- daisyUI does not apply. Map the chosen theme tokens ([theme-selection](theme-selection.md): primary, primary-content, base-100/200/300, base-content, error / success / warning, radius-field / box, type scale) to:
  - iOS: Asset Catalog color sets (Any / Dark) or a `Color` extension.
  - Android: `MaterialTheme` colorScheme (`primary`, `onPrimary`, `surface`, `onSurface`, `error`).
  - Flutter: `ThemeData.colorScheme`.
- Thai font bundled or system, line-height >= 1.6; test largest Dynamic Type / font scale 200 % for clipped vowels and tone marks ([thai-ui](thai-ui.md)).
- 4 async states with native loaders: iOS `ProgressView`, `.redacted(reason: .placeholder)`; Android `CircularProgressIndicator` / `LinearProgressIndicator`, placeholder shimmer; button disabled + 'กำลังบันทึก…'.
- Icons: Lucide (`lucide-react-native`, `lucide_icons` for Flutter, or exported SVG in the asset catalog / vector drawables). No emoji.
- iOS app with Google / LINE / Facebook login must also offer a privacy-focused login such as Sign in with Apple (App Store Guideline 4.8, [auth](auth.md)).
- Native idea but no code yet -> mobile HTML prototype at 375 px labelled 'ต้นแบบ (ไม่ใช่แอปจริง)'.

## 8. Wireframe per platform
ASCII per target platform ([ux-process](ux-process.md) Phase 4): show status bar, platform nav (tab bar / navigation bar / LINE header) and back. Right border left open on Thai lines (marks break monospace width).

iOS:
```
┌────────────────────
│ 9:41
│ ‹ กลับ   นัดหมาย
├────────────────────
│ คุณเอ  10:00    ▸
│ คุณบี  11:30    ▸
├────────────────────
│ หน้าแรก นัด ลูกค้า ฉัน
└────────────────────
```

LIFF tall view:
```
┌────────────────────
│ ← LINE วาดหัวให้
├────────────────────
│ เลือกเวลา
│ [10:00]  [11:00]
│ [13:00]  [14:00]
│ [ ยืนยันการจอง ]  sticky
└────────────────────
```

## 9. Verify
- Web / PWA / LIFF layout -> browser at 375 px ([ship-checklist](ship-checklist.md) §2). Real LIFF needs the user's phone in LINE, else *ยังไม่ได้ตรวจ*.
- iOS -> iOS Simulator: attach first, build, launch, screenshot, dark mode, largest text. Android emulator with no tool -> *ยังไม่ได้ตรวจ*.
