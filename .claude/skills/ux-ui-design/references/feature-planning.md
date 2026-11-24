# Feature Planning — put features in order

Trigger: "วางแผนฟีเจอร์", "ฟีเจอร์ไหนทำก่อน", "MVP", "roadmap", "จัดลำดับฟีเจอร์".

## 1. Ask (max 3)
- Goal: what must this product achieve? (sales, bookings, save staff time…)
- Users + their top 3 jobs.
- Limits: deadline, team size, budget.

## 2. List
Dump every feature idea as one line: **verb + object** ("จองโต๊ะออนไลน์").
Merge duplicates. Tie each to a user job; no job → cut or park.

## 3. Prioritize

Score each 1–3: **Value** (to user/goal) × **Reach** (how many use it) ÷ **Effort**.
Then sort into MoSCoW:

| Bucket | Rule |
| --- | --- |
| **Must** (MVP) | Product fails without it. Keep to the smallest set that completes the main job end to end |
| **Should** | Big value, not blocking launch |
| **Could** | Nice, cheap |
| **Won't (now)** | Parked, written down |

Check: Must list covers one full journey (e.g. find → book → confirm → remind), incl.
empty / loading / error states.

## 4. Order & map
- Dependencies first (login before booking history).
- Map features → screens → nav ([navigation](navigation.md)).
- Phases: **MVP → v1.1 → v2**, each with one goal and success metric.

## 5. Output

```
Goal: … | Users: … | Metric: …

| Feature | Job | Value | Reach | Effort | Score | Bucket | Phase |

MVP journey: step → step → step
Screens: …
Parked: …
Risks / unknowns [assumed]: …
```

## Rules
- Fewer, finished features beat many half-done ones.
- One feature = one clear job. If it needs a paragraph to explain, split it.
- Re-check after user testing; plans change.
