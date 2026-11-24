# VFX & Shader Specs for Anime Game UI

คู่มือสเปกเทคนิคสำหรับโปรแกรมเมอร์และ Technical Artist ในการทำ Shader, Particle Effects, และ Post-processing ให้เข้ากับโลกเวทมนตร์ปี 2026

---

## 1. Post-Processing: "เวทสามวินาทีของเรน" (Time Dilation Filter)

เมื่อเรนเปิดใช้สกิลเสริมสามวินาที เกมจะเข้าสู่สถานะสมาธิขั้นสูงสุด ภาพจะเปลี่ยนผ่านในเวลา 0.15 วินาที:

### Shader Parameters
```hlsl
// Conceptual Shader / Material Parameters
Uniform float  u_time_dilation_weight; // 0.0 (ปกติ) -> 1.0 (สามวินาที)
Uniform float2 u_screen_center;        // จุดศูนย์กลางของหน้าจอ (0.5, 0.5)
Uniform float  u_chromatic_aberration; // ความเหลื่อมของสี RGB (0.005 - 0.02)
Uniform float  u_vignette_intensity;   // ขอบมืด (0.4 - 0.75)
Uniform float3 u_tint_color;           // สีโทนเย็น/ซีเปีย (0.9, 0.95, 1.0)
```

### พฤติกรรมของภาพ
1. **Saturation Drop:** ความอิ่มสีของฉากหลังลดลง 60% ปล่อยให้เฉพาะตัวเรนและเป้าหมายที่มีออร่าสีขาวเงินเปล่งแสง
2. **Radial Blur & Chromatic Aberration:** ขอบจอเบลอพุ่งเข้าสู่จุดศูนย์กลาง มีสีแดง-ฟ้าเหลื่อมกันเล็กน้อย
3. **UI HUD Response:** มีตัวเลขนับถอยหลังขนาดใหญ่กึ่งกลางจอ `03.00` -> `02.00` -> `01.00` -> `00.00` จังหวะละ 1 วินาที พร้อมเสียงเข็มนาฬิกาติ๊ก

---

## 2. UI Shader: "ตราแกนร้าว & แตก" (Seal Fracture Shader)

ใช้แสดงผลบนหน้าจอ HUD ตรงการ์ดตัวละครเมื่อใช้เวทเกินขีดจำกัด

### เทคนิคการสร้าง (Technique)
- ใช้ **Voronoi Fracture Texture** หรือ **Crack Heightmap** ร่วมกับการคำนวณ `step()` หรือ `smoothstep()`
- ความคืบหน้าของรอยร้าวถูกขับเคลื่อนด้วยพารามิเตอร์ `_CrackProgress` (0.0 ถึง 1.0)
- บริเวณรอยแตกให้ใส่ Emissive Glow สีแดงนีออนปนสีส้มเพลิง เพื่อสื่อถึงความร้อนของแกนเวทมนตร์ที่กำลังจะระเบิด

```glsl
// GLSL / Godot Shader snippet
shader_type canvas_item;

uniform sampler2D crack_texture;
uniform float crack_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 glow_color : source_color = vec4(1.0, 0.2, 0.1, 1.0);

void fragment() {
    vec4 base_color = texture(TEXTURE, UV);
    float crack_val = texture(crack_texture, UV).r;
    
    if (crack_val < crack_intensity) {
        // เส้นรอยแตกเรืองแสง
        COLOR = glow_color * 2.5;
    } else {
        COLOR = base_color;
    }
}
```

---

## 3. Particle System: "การดูดกลืนเวทของน็อลล์" (Magic Absorption Vortex)

เมื่อน็อลล์กางม่านดูดเวทมนตร์ของศัตรู:
- **Particle Type:** Inward Vector Field (อนุภาคพุ่งกลับเข้าสู่จุดศูนย์กลาง ไม่ใช่ระเบิดออก)
- **Blend Mode:** Additive หรือ Subtractive (เพื่อสร้างความรู้สึกว่าแสงถูกลบหายไป)
- **Color Palette:** ดำ เหลื่อมน้ำเงินเข้มขอบม่วง (Void Purple: `#2A0845` -> `#6441A5`)
- **HUD Indicator:** ในเมนูของน็อลล์ สล็อตธาตุจะถูกเติมเต็มด้วยไอคอนธาตุที่ดูดมาพร้อมประกายหมุนวน

---

## 4. Physics & Animation: ตัวเลขดาเมจลอย (Floating Combat Text - FCT)

### จังหวะการเคลื่อนที่ (Motion Curve)
- **Spawn:** ขนาดเริ่มต้นที่ scale 0.4 ขยายอย่างรวดเร็ว (Overshoot) ไปที่ 1.3 ใน 0.08 วินาที (Pop effect)
- **Settle:** หดกลับมาที่ขนาด 1.0 ใน 0.05 วินาที
- **Drift:** ลอยขึ้นเป็นแนวโค้งพาราโบลา (Arc jump) เบี่ยงซ้ายหรือขวาเล็กน้อยแบบสุ่ม ทิ้งหางจางๆ (Alpha fade out) ในเวลา 0.6 วินาที

### รหัสสีตามประเภทการโจมตี
- ดาเมจกายภาพ: ขาวนวล `#FFFFFF` พร้อมขอบเงาดำ `#1A1A1A` หนา 3px
- ดาเมจธาตุไฟ: ส้มเพลิง `#FF5722`
- ดาเมจธาตุน้ำ: ฟ้าทะเล `#00BCD4`
- ดาเมจธาตุลม: เขียวมรกต `#00E676`
- ดาเมจธาตุดิน: ทองอำพัน `#FFC107`
- คริติคอล: เหลืองนีออน `#FFFF00` ขนาดตัวอักษรใหญ่ขึ้น 150% มีคำว่า `CRITICAL!` เด้งนำหน้า
- พลาดเป้า (Miss): สีเทาซีด `#9E9E9E` เคลื่อนที่เฉียงลงด้านข้าง
