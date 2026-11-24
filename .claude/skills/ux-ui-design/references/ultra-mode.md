# Ultra Mode

Trigger: "อัลตร้า", "ultra", "แบบละเอียดที่สุด", "เต็มที่", "ทำให้ดีที่สุด".
Same paths as normal, every step at full depth. Still short in output.

## What changes

| Step | Normal | Ultra |
| --- | --- | --- |
| Brief | ≤ 3 questions | Same 3 + goal metric, roles, devices, brand assets; list every [assumed] |
| Options | 1 wireframe (2 for nav) | **3 directions** (e.g. safe / bold / content-first), scored, user picks |
| Platforms | Web | Desktop + mobile web always; app / LINE if relevant ([platforms](platforms.md)) |
| States | 4 per screen | Every screen × empty / loading / error / success × 375 / 768 / 1024 / 1440 |
| Domain states | When present | All: payment, slot taken, OTP expired, offline, session timeout, long Thai text |
| Theme | 1 pair | 2 candidate pairs compared on real screens ([theme-selection](theme-selection.md)) |
| Checks | ship-checklist | ship-checklist + [ui-audit](ui-audit.md) + [accessibility](accessibility.md) + [website-review](website-review.md) (public sites) + [ai-design-qa](ai-design-qa.md) |
| Verify | Key widths | Full verify steps in [ship-checklist](ship-checklist.md) §2, fix, re-run until all pass |
| Review | Self-check | Critique own work as a skeptic: 3 lenses (user, accessibility, engineer); fix P0–P1 |
| Copy | Short | Short + 2 versions of headline / key CTA ([content-writing](content-writing.md)) |

## Score the 3 directions

| Criterion (0–2) | A | B | C |
| --- | --- | --- | --- |
| Task fit (main job fastest) | | | |
| Audience fit | | | |
| Brand / not generic | | | |
| Mobile works | | | |
| Effort to build | | | |

Recommend the top score; graft the best idea from the others.

## Loop

1. Build → 2. Verify all → 3. Skeptic review → 4. Fix P0–P1 → back to 2 until clean (max 3 rounds; say if stopped early).

## Output
- Decisions block (who, task, platform, theme, chosen direction + why).
- Files + screenshots (375, 1440, one pending state).
- Scorecard from [ui-audit](ui-audit.md).
- Delivery footer: ไฟล์ · ตรวจแล้ว · ยังไม่ได้ตรวจ · ต่อไป.
