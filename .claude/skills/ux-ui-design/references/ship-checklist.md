# Ship Checklist + Verify

Run before saying "done". Unchecked = list under *ยังไม่ได้ตรวจ*.

## 1. Checklist

| Check | How |
| --- | --- |
| Wireframe OK'd before build; Decisions block current | chat history ([ux-process](ux-process.md) Phase 4) |
| Main task works end to end | click through at 375 + 1440 |
| Every async action: idle / pending / success / error; no double submit; forms stay open until saved ([async-feedback](async-feedback.md)) | `?delay=3000`, double-click, `?fail=1` |
| Empty / loading / error / success on each screen | `?state=` |
| Domain states when present: payment ([checkout-payment](checkout-payment.md)), booking slot taken / hold expired, OTP / session expired ([auth](auth.md)) | walk each state |
| Contrast AA, focus visible, keyboard works ([accessibility](accessibility.md)) | theme swap + Tab pass |
| Targets >= 24 px everywhere, >= 44 px touch (48 busy) | JS `under24` / `under44` |
| 375 / 768 / 1024 / 1440 px: no horizontal scroll, nav not wrapping, CTA visible | JS `hScroll` / `navRows` + screenshots |
| Mobile: `min-h-dvh`, safe area, back closes sheets ([platforms](platforms.md)) | 375 screenshot |
| Copy short; errors say how to fix; no emoji ([copy](copy.md)) | read + JS `emoji` / `glyphs` |
| Lucide icons only; icon-only buttons have `aria-label` | JS `noName`; search for `fa-`, `material-icons`, other icon libs |
| Theme tokens only (no raw colors); light + dark if needed ([theme-selection](theme-selection.md)) | search file for `bg-gray-`, `text-slate-`, `#` hex, `rgb(` in classes |
| Right notification type; toast region `aria-live`; reduced motion respected ([notifications](notifications.md)) | read |
| Thai: line-height, line breaks, no clipped marks ([thai-ui](thai-ui.md)) | zoom screenshot |
| Images sized + alt; `<title>` + meta set | JS `imgNoAlt`; read `<head>` |
| No console errors; CDN versions pinned ([build-html](build-html.md)) | console |
| Not verified items listed | footer |

Test hooks (from [build-html](build-html.md) section 6): `?state=empty|loading|error|success`, `?delay=<ms>`, `?fail=1`, `data-async` on async triggers. Missing -> use the fetch wrapper (step 3).

## 2. Verify steps (on the built file)

1. **Open.** Claude Code: Browser pane `preview_start` with `url: file:///<abs path>`; project -> dev server in `.claude/launch.json` + `preview_start(name)`. Site behind the user's login -> Chrome extension; the user logs in, never type passwords. No browser tool -> ask for screenshots; mark visual checks *ยังไม่ได้ตรวจ*.
2. **Widths.** 375 (`resize_window` preset `mobile`), 768 (`tablet`), 1024x768, 1440x900. Each: reload -> screenshot -> run JS check -> console (errors only).
   Pass = `hScroll` false, `navRows` <= 1, `under24` 0, `under44` 0 at 375/768, `noLabel` 0, `noName` 0, `imgNoAlt` 0, `emoji` false, `glyphs` false, no console errors (CDN 404, JS errors).
3. **States.** Load `?state=empty`, `loading`, `error`, `success`. With `?delay=3000` click each `[data-async]`, screenshot pending; double-click -> one action; `?fail=1` -> error shows, input kept. Real fetch: wrap `window.fetch` with a 3 s delay via the JS tool (no network throttle in the pane).
4. **Theme.** Set `document.documentElement.dataset.theme` to each chosen theme, screenshot; check muted text and `*-content` contrast. Static file previews ignore OS dark emulation.
5. **Keyboard.** Tab x6 -> screenshot focus ring; Enter/Space open menus; Esc closes drawer/modal and focus returns; sticky bars never hide the focused field.
6. **Thai.** Zoom headings/buttons for clipped marks (่ ้ ิ ี ึ ื ั). Set one nav/button label to `บันทึกการเปลี่ยนแปลงทั้งหมด`, re-check wrap.
7. **Native.** iOS -> iOS Simulator (attach, build, launch, screenshot, light + dark, largest Dynamic Type). Android -> *ยังไม่ได้ตรวจ*.
8. **Wrap.** Reset (`resize_window` preset `desktop`). Send 2-3 screenshots (375, 1440, one pending state) to the user (Claude Code: `SendUserFile`).

JS check (paste as is):

```js
(() => {
  const box = e => { const b = e.getBoundingClientRect(); return b.width && b.height ? b : null; };
  const ctl = [...document.querySelectorAll('a,button,input,select,textarea,[role=button]')].filter(e => box(e) && !e.closest('p'));
  return {
    hScroll: document.documentElement.scrollWidth > innerWidth,
    navRows: new Set([...document.querySelectorAll('header nav a')].filter(box).map(a => a.offsetTop)).size,
    under24: ctl.filter(e => { const b = box(e); return b.width < 24 || b.height < 24; }).length,
    under44: ctl.filter(e => box(e).height < 44).length,
    noLabel: [...document.querySelectorAll('input:not([type=hidden]),select,textarea')].filter(e => !e.labels?.length && !e.getAttribute('aria-label') && !e.getAttribute('aria-labelledby')).length,
    noName: ctl.filter(e => e.matches('a,button') && !e.textContent.trim() && !e.getAttribute('aria-label')).length,
    imgNoAlt: document.querySelectorAll('img:not([alt])').length,
    emoji: /\p{Emoji_Presentation}/u.test(document.body.innerText),
    glyphs: /[☰✕✖★☆✓✔]/.test(document.body.innerText),
  };
})()
```

Inline text links inside `<p>` are exempt from the 24 px rule (WCAG 2.5.8), hence the filter.

## 3. Delivery footer (end every delivery with it)

```
ไฟล์: <path/link> · ตรวจแล้ว: … · ยังไม่ได้ตรวจ: … · ต่อไป: …
```

Add the Decisions block if anything changed.
