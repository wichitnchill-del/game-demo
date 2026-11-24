# Audio & Haptics Feedback Map for Game UI

ตารางจับคู่ระหว่างการกระทำของผู้เล่น (User Input), ปฏิกิริยาบนหน้าจอ (Visual), เสียง (Audio Cue), และแรงสั่น (Haptic Feedback)

---

## 1. ตาราง Audio-Visual-Haptic Sync

| แอ็กชัน / อีเวนต์ | การตอบสนองทางภาพ (Visual) | เสียง (Audio SFX) | แรงสั่นสัมผัส (Haptics) |
|---|---|---|---|
| **Hover / ชี้ปุ่มคำสั่ง** | ปุ่มขยาย 1.05x มีแสงไฮไลท์วิ่งรอบกรอบ | เสียงคลิกเบา ความถี่สูง (High-tech chirp 800Hz) | สั่นเบามาก 5ms (Light tap) |
| **กดเลือกคำสั่งโจมตี** | ปุ่มยุบตัว 0.95x ปล่อยประกายแสงเล็กๆ | เสียงคลิกโลหะแน่น (Mechanical click 300Hz) | สั่นปานกลาง 15ms (Medium click) |
| **เปิดใช้สกิล 3 วินาที** | เวลาชะลอ จอปรับเป็น Vignette + ขาวดำ | เสียงระเบิดนิ่ง (Bass drop) + เข็มนาฬิกาติ๊ก 3 ครั้ง | สั่นยาวแบบเต้นเป็นจังหวะ 3 ครั้ง (Tick-Tick-Tick) |
| **ตราแกนเกิดรอยร้าว (Cracked)** | รอยแตกสีแดงสว่างวาบ หน้าจอกระตุก 1 เฟรม | เสียงแก้วหรือคริสตัลเริ่มลั่นเปรี๊ยะ (Glass Stress) | สั่นแบบดับเบิ้ลช็อก 30ms + 40ms |
| **ตราแกนแตก (Shattered)** | ตราแตกเป็นเสี่ยงๆ ขอบจอแดงวาบ | เสียงแก้วแตกก้องกังวาน (Glass Shatter + Low Rumble) | สั่นรุนแรง 100ms (Heavy impact) |
| **ลมหายใจเวทวิกฤต (<20%)** | หลอดกระพริบสีส้มตามจังหวะชีพจร | เสียงเตือนอัตราการเต้นของหัวใจ (Heartbeat loop) | สั่นเป็นจังหวะหัวใจ (Duk-Duk) ทุก 1.5 วินาที |
| **โจมตีติดคริติคอล** | ตัวเลขดาเมจสีเหลืองดีดเด้ง + จอค้าง 0.08s | เสียงคมดาบ/พลังทะลวงแหลมสะท้อน (Slash Sharp) | สั่นแน่นคม 25ms (Sharp transient) |
| **น็อลล์ดูดกลืนเวท** | เกลียวหมอกดำดูดเข้าสู่แกนกลางตัวละคร | เสียงลมหมุนสุญญากาศ (Vacuum Whoosh) | สั่นแบบไต่ระดับจากเบาไปแรง 50ms |

---

## 2. โค้ดตัวอย่างการเรียก Haptic บน Mobile Web (Navigator API)

```javascript
// Web Vibration API ตัวอย่าง
const GameHaptics = {
    lightTap: () => navigator.vibrate?.(10),
    mediumClick: () => navigator.vibrate?.(20),
    sealCrack: () => navigator.vibrate?.([30, 40, 50]),
    heartbeat: () => navigator.vibrate?.([15, 80, 20]),
    heavyImpact: () => navigator.vibrate?.(100)
};
```
