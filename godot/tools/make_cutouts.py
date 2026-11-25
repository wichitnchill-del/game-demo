"""Make transparent-background cutouts of each character sheet.

Background = near-white pixels connected to the image border (flood fill), so
white clothing inside the outline is kept. Output: assets/cutouts/<id>.png
Run: python3 tools/make_cutouts.py ../sheets assets/cutouts
"""
import sys, pathlib
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

src, dst = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
dst.mkdir(parents=True, exist_ok=True)
GHOST = {"null"}  # drawn almost all in white: alpha from darkness instead (fades like he does)
for f in sorted(src.glob("*.webp")):
    im = Image.open(f).convert("RGB")
    a = np.asarray(im).astype(np.int16)
    if f.stem in GHOST:
        dark = 255 - a.min(axis=2)
        alpha = np.clip((dark - 6) * 5, 0, 255).astype(np.uint8)
        alpha = Image.fromarray(alpha).filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(1))
        out = im.convert("RGBA"); out.putalpha(alpha)
        out.save(dst / (f.stem + ".png"), optimize=True)
        print(f.stem, "ghost cutout")
        continue
    # "light and unsaturated" = paper background (sheets have noisy off-white paper)
    light = a.min(axis=2) > 222
    flat = (a.max(axis=2) - a.min(axis=2)) < 14
    cand = light & flat
    cand = ndimage.binary_opening(cand, iterations=1)
    lab, _ = ndimage.label(cand)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    bg = ndimage.binary_fill_holes(~bg) == 0  # keep only outer background
    alpha = Image.fromarray(np.where(bg, 0, 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.2))
    out = im.convert("RGBA"); out.putalpha(alpha)
    out.save(dst / (f.stem + ".png"), optimize=True)
    print(f.stem, f"{bg.mean():.0%} background")
