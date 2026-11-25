# Phase 1 — Combat Prototype Design

> **Status:** ร่างสำหรับ build prototype
> **Source:** GDD · `game-design.md` §3 · `phase-1-design.md` · `scripts/`

---

## 1. เป้าหมายของ Combat Prototype

Validate **Core Loop ของ Phase 1** ก่อนลง production:

1. **เล่นปลอดภัย vs เสี่ยง** — buff 3 วินาท์ทำงาน แต่มีราคา (ลมหายใจ) → มีความเสี่ยง backfire
2. **ราคาของพลัง** — buff/support/needle มี cost → lose condition (shatter → forget)
3. **ทีม 5 คน** — โครงทีมพื้นฐาน

---

## 2. Scope ของ Prototype

| หัวข้อ | ใน prototype | ออกไป |
|---|---|---|
| Real-time action combat | ✅ | — |
| Buff action (เรน) | ✅ 3 วินาท์ / 1 charge | — |
| Support / Attack | ⚠️ subset | full kit |
| Team of 5 AI | ❌ | เก็บ Phase 2+ |
| คอมโบไม่จำกัด (無限連撃) | ⚠️ ตีเบา/หนัก/กระโดด/พุ่ง + ด้ายขาด 1.2 วิ | ระดับฮิต · Seal Burst |
| VFX/shader | ⚠️ basic | full |

---

## 3. Core Loop ที่จะ Prototype

```
scan → buff (3 วินาท์) → fight → backlash/lose → (victory → level/survive)
```

- **Buff (เรน):** เสริมตัวเอง · ใช้เวลา **3 วินาท์** · ก่อนใช้ต้องมีลมหายใจเหลือ
- **Cost:** ลมหายใจเวทลด → ต่ำ → backfire risk
- **Lose:** shatter (เสริมเกิน / ใช้แรงเกิน) → **ถูกลืมตัวละคร** (forget → ออกจากทีม)

---

## 4. Success Criteria

- [ ] Player รู้ว่า buff 3 วินาท์มีราคา (ลมหายใจ)
- [ ] Player เลือก: เล่นปลอดภัย หรือ เสี่ยง
- [ ] Lose condition (shatter → forget) trigger ได้
- [ ] Core loop playable end-to-end (scan → buff → fight → resolve)

---

## 5. Tech

- **Engine:** Godot (DD-01) — GDScript
- **Platform:** PC (Godot Desktop)

---

## 6. Out of Scope (Phase 1 prototype)

- ทีม 5 คน full · ธาตุ full · ไอเทม full

---

*ถัดไป: build Combat Prototype → เขียน script scene ต่อ (B-01 / A-02 / A-03) → character sheet* 🔥
