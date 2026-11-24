# Build HTML

## 1. New single file: copy this skeleton (verbatim, then fill)
```html
<!doctype html>
<html lang="th" data-theme="corporate">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>หัวข้อหน้า – แบรนด์</title>
<meta name="description" content="120–155 ตัวอักษร">
<script>var t;try{t=localStorage.getItem('theme')}catch(e){}if(!t&&matchMedia('(prefers-color-scheme:dark)').matches)t='business';if(t)document.documentElement.dataset.theme=t</script><!-- drop the dark part if no dark pair -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans+Thai:wght@400;500;600;700&display=swap" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/daisyui@5.8.2/daisyui.css" rel="stylesheet">
<link href="https://cdn.jsdelivr.net/npm/daisyui@5.8.2/themes.css" rel="stylesheet"><!-- only if theme is not light/dark -->
<script src="https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4.3.5"></script>
<script src="https://cdn.jsdelivr.net/npm/lucide@1.78.0/dist/umd/lucide.min.js"></script>
<style type="text/tailwindcss">
@theme { --font-sans: "IBM Plex Sans Thai", "Noto Sans Thai", system-ui, sans-serif; }
</style>
<style>/* keep after daisyUI */
:root,[data-theme]{--size-field:.275rem!important} /* btn/input 44px */
.input,.select,.textarea{font-size:max(1rem,var(--font-size-min,1rem))} /* >=16px, no iOS zoom */
html{scroll-padding-block:5rem} body{line-height:1.7}
@media (prefers-reduced-motion:reduce){*{animation:none!important;transition:none!important}}
</style>
</head>
<body class="min-h-dvh bg-base-100 text-base-content">
<a href="#main" class="sr-only focus:not-sr-only">ข้ามไปเนื้อหา</a>
<main id="main"><!-- page --></main>
<div id="status" class="toast toast-top toast-center sm:toast-end" aria-live="polite"></div>
<script>lucide.createIcons()</script>
</body>
</html>
```
- Pin exact versions as above; never `@latest` or a bare major in output. Bump deliberately.
- `daisyui.css` has only `light` + `dark`; any other preset needs `themes.css` or `data-theme` silently does nothing.
- The override `<style>` makes `btn`/`input` 44 px and input text 16 px; `!important` beats the more specific theme selectors (`:root:has(.theme-controller…)`, unlayered `themes.css`). `btn-sm` becomes ~35 px: desktop-dense only. Targets per [accessibility](accessibility.md).
- Thai font choice per [thai-ui](thai-ui.md).
- Tailwind browser CDN = prototype only; production uses the build (`@import "tailwindcss"; @plugin "daisyui";`).

## 2. Brand theme without a build
Plain CSS after the links: `[data-theme="brand"]{color-scheme:light;--color-primary:oklch(…);--color-primary-content:oklch(…);…}`. A new name must define every variable ([theme-selection](theme-selection.md) 4c); overriding a preset may list only what changes.

## 3. Theme toggle (light/dark pair)
```html
<button class="btn btn-ghost btn-square tooltip tooltip-bottom" data-tip="สลับโหมดมืด" data-theme-toggle aria-label="สลับโหมดมืด"><i data-lucide="moon" aria-hidden="true"></i></button>
<script>
document.querySelectorAll('[data-theme-toggle]').forEach(b=>b.onclick=()=>{
  const r=document.documentElement,t=r.dataset.theme==='business'?'corporate':'business';
  r.dataset.theme=t;try{localStorage.setItem('theme',t)}catch(e){}});
</script>
```
The head script restores the choice before paint (no flash). Keep the pair names in sync with section 1.

## 4. Icons (Lucide only)
- `<i data-lucide="menu" aria-hidden="true"></i>` + `lucide.createIcons()` at end of body; call it again after inserting DOM. React `lucide-react`, Vue `lucide-vue-next`, Svelte `lucide-svelte`.
- Size `size-4` (16, inline) / `size-5` (20, buttons, menus) / `size-6` (24, nav, dock); stroke 2 (1.5 at >= 32 px); color = `currentColor`.
- Icon-only button: `aria-label` + daisyUI `tooltip` (`data-tip`); nav keeps icon + text.
- Common names: menu, x, search, shopping-cart, bell, calendar-days, clock, map-pin, phone, copy, printer, chevron-left, chevron-right, circle-alert, check, moon, ellipsis.
- Lucide has no brand logos (LINE, Facebook, Google, TikTok): use official brand assets or Simple Icons SVG and follow brand rules. Never emoji or glyphs (☰ ✕ ★).

## 5. Images
- Always `width`+`height`, or `aspect-[4/3]` + `object-cover` (no layout shift).
- Hero `fetchpriority="high"`, not lazy; others `loading="lazy" decoding="async"`; `srcset` + `sizes`; `<picture>` AVIF -> WebP -> JPG.
- Product grid: one ratio (1:1 or 4:5). No Thai text baked into images. Placeholder `bg-base-200` / `skeleton`.
- `alt` in the page language, describing purpose ("ข้าวซอยไก่ จานใหญ่"); decorative `alt=""`.
- Sources: own photos > Unsplash / Pexels (note license); label AI images; never fake people or reviews.
- Avatar initial for Thai names skips leading vowels เ แ โ ใ ไ ("เกศินี" -> "ก").

## 6. Prototype states (needed by Verify)
Ship this in every prototype (after `#status`):
- `?state=empty|loading|error|success` shows matching `[data-state]` blocks, hides others (default `content`).
- Toasts: max 3, newest on top, top-center mobile / top-right desktop ([notifications](notifications.md)).
- `[data-async]` button: `aria-disabled` (not `disabled`, focus stays) + spinner + `data-pending` label; after `?delay=` ms (default 1200) restore + toast `data-done`; `?fail=1` = error toast that stays until closed.
```html
<script>
const q=new URLSearchParams(location.search),S=document.getElementById('status');
const st=q.get('state')||'content',wait=q.has('delay')?+q.get('delay'):1200,fail=q.get('fail')==='1';
document.querySelectorAll('[data-state]').forEach(e=>e.hidden=e.dataset.state!==st);
function toast(cls,msg,stay){const d=document.createElement('div');d.className='alert '+cls;if(stay)d.setAttribute('role','alert');d.textContent=msg;
  if(stay){const x=document.createElement('button');x.className='btn btn-ghost';x.textContent='ปิด';x.onclick=()=>d.remove();d.append(x)}
  else setTimeout(()=>d.remove(),4000);S.prepend(d);while(S.children.length>3)S.lastChild.remove()}
document.addEventListener('click',e=>{const b=e.target.closest('[data-async]');if(!b)return;e.preventDefault();
  if(b.getAttribute('aria-disabled')==='true')return;const html=b.innerHTML;
  b.setAttribute('aria-disabled','true');b.setAttribute('aria-busy','true');
  b.innerHTML='<span class="loading loading-spinner loading-sm" aria-hidden="true"></span> '+(b.dataset.pending||'กำลังบันทึก…');
  setTimeout(()=>{b.innerHTML=html;b.removeAttribute('aria-disabled');b.removeAttribute('aria-busy');if(window.lucide)lucide.createIcons();
    fail?toast('alert-error','บันทึกไม่ได้ ลองใหม่',1):toast('alert-success',b.dataset.done||'บันทึกแล้ว')},wait)});
</script>
```
Usage: `<button class="btn btn-primary" data-async data-pending="กำลังจอง…" data-done="จองแล้ว">จองโต๊ะ</button>`. Real code: same 4 states per [async-feedback](async-feedback.md).

## 7. Existing project (check before writing code)
1. `package.json`: react / next / vue / nuxt / svelte / astro; `daisyui` and `tailwindcss` versions; lucide-react / lucide-vue-next / lucide-svelte.
2. `components.json` -> shadcn/ui: use its components; loaders per [async-feedback](async-feedback.md).
3. `tailwind.config.*` with daisyui in `plugins` -> Tailwind 3 + daisyUI 4. CSS with `@import "tailwindcss"` + `@plugin "daisyui"` -> Tailwind 4 + daisyUI 5.

Rules: use the project's stack, components and icon package; never add CDN tags; tokens go in the project's theme file; put the 44 px / 16 px override in project CSS. Match the installed daisyUI major (v4 -> v5: `btm-nav` -> `dock`; `form-control` + `label-text` -> `fieldset` + `label`; `card-bordered` -> `card-border`; menu `active` -> `menu-active`; `input-bordered` -> drop, default). Verify on the project's dev server (`.claude/launch.json` + preview).

## 8. Before delivering -> [ship-checklist](ship-checklist.md).
