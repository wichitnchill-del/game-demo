"""Synthesised placeholder sound effects (no recordings in the project yet).

shutter.wav: camera shutter — two sharp clicks (open/close) with a short whir.
step_1..4.wav: soft shoe footsteps on an indoor floor — a short low "thud"
(decaying low sine) plus a filtered noise "scuff". Replace with real recordings later.

Run: python3 tools/make_sfx.py
"""
import math
import os
import random
import struct
import wave

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx")
RATE = 44100


def step(seed: int) -> list:
    rnd = random.Random(seed)
    n = int(RATE * 0.16)
    thud_f = rnd.uniform(70, 95)
    out, lp, lp2 = [], 0.0, 0.0
    for i in range(n):
        t = i / RATE
        thud = math.sin(2 * math.pi * thud_f * t) * math.exp(-t * 38)
        noise = rnd.uniform(-1, 1)
        lp += (noise - lp) * 0.18          # two one-pole low-passes -> soft scuff
        lp2 += (lp - lp2) * 0.35
        scuff = lp2 * math.exp(-t * 55) * 2.2
        attack = min(1.0, i / (RATE * 0.002))
        out.append((thud * 0.75 + scuff * 0.5) * attack)
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak * 0.6 for v in out]


os.makedirs(OUT, exist_ok=True)
for k in range(1, 5):
    data = step(k * 17)
    path = os.path.join(OUT, f"step_{k}.wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in data))
    print("wrote", os.path.normpath(path))


def shutter() -> list:
    rnd = random.Random(7)
    n = int(RATE * 0.22)
    out = [0.0] * n
    for start, amp in ((0.0, 1.0), (0.085, 0.8)):          # two clicks
        s0 = int(start * RATE)
        hp = 0.0
        for i in range(int(RATE * 0.025)):
            t = i / RATE
            noise = rnd.uniform(-1, 1)
            hp = noise - hp * 0.6                             # bright, clicky
            out[s0 + i] += hp * math.exp(-t * 260) * amp
    for i in range(int(RATE * 0.02), int(RATE * 0.08)):        # whir between them
        t = i / RATE
        out[i] += math.sin(2 * math.pi * 1800 * t) * 0.06 * math.sin(math.pi * (t - 0.02) / 0.06)
    peak = max(abs(v) for v in out) or 1.0
    return [v / peak * 0.7 for v in out]


path = os.path.join(OUT, "shutter.wav")
with wave.open(path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(RATE)
    w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in shutter()))
print("wrote", os.path.normpath(path))
