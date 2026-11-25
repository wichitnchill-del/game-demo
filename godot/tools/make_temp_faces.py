"""Temporary cartoon faces for characters that have no character sheet yet.

Draws a simple anime-style head (face, eyes, brows, mouth, hair) per character
and writes assets/faces/decal_<id>.png, the same file the cutscene stage uses for
the character-sheet faces. Replace with real art later (same file name).

Run: python3 tools/make_temp_faces.py
"""
import os

from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "faces")
S = 512          # draw big, downsample to 256 for smooth edges
SKIN = (246, 205, 176)   # matches human_model.gd SKIN f6cdb0
LINE = (60, 40, 40)

# hair colour, style, eye colour, brows ("soft"/"stern"/"angry"), mouth, extras
FACES = {
    "piang":   dict(hair=(70, 58, 52), style="bun", eye=(90, 60, 40), brows="soft", mouth="smile", grey=True, age=True),
    "mom":     dict(hair=(70, 40, 26), style="set", eye=(110, 60, 50), brows="soft", mouth="lipstick"),
    "victor":  dict(hair=(32, 28, 26), style="slick", eye=(50, 50, 60), brows="stern", mouth="flat"),
    "lily":    dict(hair=(150, 62, 36), style="long", eye=(120, 70, 40), brows="soft", mouth="grin", bow=(232, 80, 106)),
    "teacher": dict(hair=(46, 38, 32), style="short", eye=(60, 50, 40), brows="soft", mouth="flat", glasses=True),
    "enji":    dict(hair=(205, 40, 26), style="spiky", eye=(200, 90, 30), brows="angry", mouth="smirk"),
    "kai":     dict(hair=(30, 26, 22), style="buzz", eye=(60, 45, 35), brows="soft", mouth="grin"),
    "thug":    dict(hair=(26, 26, 30), style="buzz", eye=(40, 40, 40), brows="angry", mouth="frown"),
}


def draw(spec: dict) -> Image.Image:
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    hair = spec["hair"]
    st = spec["style"]
    cx = S // 2
    # hair behind the head
    if st == "long":
        d.rounded_rectangle((cx - 175, 140, cx + 175, 500), 90, fill=hair)
    if st == "bun":
        d.ellipse((cx - 70, 20, cx + 70, 150), fill=hair, outline=LINE, width=5)
    if st == "set":
        d.ellipse((cx - 185, 150, cx + 185, 420), fill=hair)
    # face
    face = (cx - 140, 110, cx + 140, 450)
    d.ellipse(face, fill=SKIN, outline=LINE, width=6)
    # hair on top
    top = (cx - 158, 70, cx + 158, 300)
    if st in ("bun", "set", "long", "short", "slick"):
        d.chord(top, 180, 360, fill=hair, outline=LINE, width=5)
        if st in ("long", "set", "short"):      # fringe
            for k in range(-2, 3):
                x = cx + k * 52
                d.polygon([(x - 40, 180), (x + 40, 180), (x + 8, 240)], fill=hair)
        if st == "slick":                        # neat side parting
            d.line((cx - 60, 95, cx - 30, 180), fill=tuple(min(255, c + 40) for c in hair), width=6)
    elif st == "spiky":
        d.chord(top, 180, 360, fill=hair, outline=LINE, width=5)
        for k in range(-3, 4):
            x = cx + k * 45
            d.polygon([(x - 34, 170), (x + 34, 170), (x + 10 * k, 15 + abs(k) * 22)], fill=hair, outline=LINE)
    elif st == "buzz":
        d.chord((cx - 146, 95, cx + 146, 260), 180, 360, fill=hair)
    if spec.get("grey"):
        for sx in (-1, 1):
            d.line((cx + sx * 120, 150, cx + sx * 150, 250), fill=(200, 196, 192), width=14)
        d.ellipse((cx - 20, 40, cx + 30, 80), fill=(200, 196, 192))
    if spec.get("bow"):
        b = spec["bow"]
        d.polygon([(cx + 70, 110), (cx + 150, 70), (cx + 150, 150)], fill=b, outline=LINE)
        d.polygon([(cx + 70, 110), (cx - 10, 70), (cx - 10, 150)], fill=b, outline=LINE)
        d.ellipse((cx + 52, 92, cx + 88, 128), fill=b, outline=LINE)
    # eyes
    ey = 300
    for sx in (-1, 1):
        ex = cx + sx * 62
        d.ellipse((ex - 30, ey - 38, ex + 30, ey + 38), fill=(255, 255, 255), outline=LINE, width=5)
        d.ellipse((ex - 22, ey - 26, ex + 22, ey + 32), fill=spec["eye"])
        d.ellipse((ex - 11, ey - 12, ex + 11, ey + 14), fill=(20, 16, 20))
        d.ellipse((ex - 14, ey - 22, ex - 2, ey - 10), fill=(255, 255, 255))
        # brows
        by = ey - 60
        if spec["brows"] == "angry":
            # inner end (toward the nose) low, outer end high
            d.line((ex - 34 * sx, by + 12, ex + 30 * sx, by - 14), fill=LINE, width=10)
        elif spec["brows"] == "stern":
            d.line((ex - 34, by, ex + 34, by), fill=LINE, width=10)
        else:
            d.arc((ex - 36, by - 10, ex + 36, by + 20), 200, 340, fill=LINE, width=8)
        if spec.get("glasses"):
            d.ellipse((ex - 46, ey - 48, ex + 46, ey + 48), outline=(170, 180, 195), width=7)
    if spec.get("glasses"):
        d.line((cx - 16, ey - 10, cx + 16, ey - 10), fill=(170, 180, 195), width=7)
    if spec.get("age"):
        for sx in (-1, 1):
            d.arc((cx + sx * 62 - 30, ey + 30, cx + sx * 62 + 30, ey + 60), 20, 160, fill=(200, 160, 140), width=4)
    # nose + mouth
    d.line((cx, 360, cx - 6, 380), fill=(200, 150, 130), width=5)
    my = 405
    m = spec["mouth"]
    if m == "smile":
        d.arc((cx - 40, my - 30, cx + 40, my + 15), 20, 160, fill=LINE, width=7)
    elif m == "grin":
        d.chord((cx - 45, my - 25, cx + 45, my + 30), 0, 180, fill=(255, 255, 255), outline=LINE, width=6)
    elif m == "lipstick":
        d.chord((cx - 32, my - 18, cx + 32, my + 18), 0, 180, fill=(190, 50, 80), outline=LINE, width=4)
    elif m == "smirk":
        d.line((cx - 30, my + 4, cx + 34, my - 10), fill=LINE, width=7)
    elif m == "frown":
        d.arc((cx - 36, my, cx + 36, my + 40), 200, 340, fill=LINE, width=7)
    else:  # flat
        d.line((cx - 28, my, cx + 28, my), fill=LINE, width=7)
    return im.resize((256, 256), Image.LANCZOS)


os.makedirs(OUT, exist_ok=True)
for cid, spec in FACES.items():
    path = os.path.join(OUT, f"decal_{cid}.png")
    draw(spec).save(path)
    print("wrote", os.path.normpath(path))
