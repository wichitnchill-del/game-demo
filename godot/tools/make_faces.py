"""Round face portraits for the HUD: assets/faces/<id>.png (256x256, transparent outside the circle).
Uses the face regions in scripts/sheets.gd. Run: python3 tools/make_faces.py"""
import re, pathlib
from PIL import Image, ImageDraw, ImageFilter
root = pathlib.Path(__file__).resolve().parent.parent
src = (root / "scripts/sheets.gd").read_text()
out = root / "assets/faces"; out.mkdir(parents=True, exist_ok=True)
for m in re.finditer(r'"(\w+)":\s*\{"face": Rect2\(([\d, ]+)\)', src):
    cid = m.group(1); x, y, w, h = [int(v) for v in m.group(2).split(",")]
    sheet = root.parent / "sheets" / f"{cid}.webp"
    if not sheet.exists(): continue
    im = Image.open(sheet).convert("RGB").crop((x, y, x + w, y + h)).resize((256, 256), Image.LANCZOS)
    bg = Image.new("RGB", (256, 256), (246, 240, 255))           # soft lavender behind the face
    bg.paste(im, (0, 0))
    mask = Image.new("L", (1024, 1024), 0)
    ImageDraw.Draw(mask).ellipse((8, 8, 1016, 1016), fill=255)
    mask = mask.resize((256, 256), Image.LANCZOS)
    face = bg.convert("RGBA"); face.putalpha(mask)
    face.save(out / f"{cid}.png")
    print("face", cid)
