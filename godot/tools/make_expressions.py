"""Emotion faces for 3D cutscenes, cropped from the character sheets.

Each sheet has several head shots (smile / neutral / sad / angry …). This crops
them (regions measured per sheet, like sheets.gd), removes the white background
the same way as make_face_decals.py, and writes
assets/faces/decal_<id>_<emotion>.png. A story line picks one with a third
element: ["oli", "text", "sad"].

Run: python3 tools/make_expressions.py
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image  # noqa: E402

from make_face_decals import FACES, cut  # noqa: E402

SHEETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sheets")

# id -> emotion -> (left, top, right, bottom) on the 2000x1500 sheet
EXPRESSIONS = {
    "oli": {
        "smile": (990, 30, 1450, 490),
        "neutral": (1460, 30, 1920, 490),
        "sad": (990, 545, 1450, 1005),
        "angry": (1460, 545, 1920, 1005),
    },
    # ฮารุ: holds her face still — feelings leak out as water first
    "haru": {
        "neutral": (780, 210, 1160, 590),
        "sad": (1165, 210, 1545, 590),       # one tear
        "cry": (1560, 210, 1960, 610),       # water pouring from her
    },
    # เลออน: grin / sideways smirk / caught off guard / calm half-smile
    "leon": {
        "smile": (930, 30, 1450, 550),
        "smirk": (1490, 40, 1960, 510),
        "surprised": (880, 760, 1400, 1280),
        "neutral": (1480, 760, 1970, 1250),
    },
}


def main():
    tmp = os.path.join(FACES, "_crop_tmp.png")
    for cid, emos in EXPRESSIONS.items():
        sheet = Image.open(os.path.join(SHEETS, f"{cid}.webp")).convert("RGBA")
        for emo, box in emos.items():
            sheet.crop(box).resize((256, 256), Image.LANCZOS).save(tmp)
            out = os.path.join(FACES, f"decal_{cid}_{emo}.png")
            cut(tmp).save(out)
            print("wrote", os.path.normpath(out))
    os.remove(tmp)


if __name__ == "__main__":
    main()
