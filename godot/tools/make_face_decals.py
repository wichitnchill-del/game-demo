"""Face decals for 3D cutscene close-ups.

assets/faces/<id>.png are round portraits on a white background. This flood-fills
the near-white background from the border (so white inside the face — eyes,
teeth, shirt — is kept) and writes assets/faces/decal_<id>.png with alpha.

Run: python3 tools/make_face_decals.py
"""
import glob
import os
from collections import deque

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
FACES = os.path.join(HERE, "..", "assets", "faces")


def cut(path: str) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    w, h = im.size
    px = im.load()
    seen = bytearray(w * h)
    q = deque()
    for x in range(w):
        q.append((x, 0)); q.append((x, h - 1))
    for y in range(h):
        q.append((0, y)); q.append((w - 1, y))

    def bg(p):
        r, g, b, a = p
        return a < 20 or (r > 228 and g > 228 and b > 228)

    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y * w + x]:
            continue
        seen[y * w + x] = 1
        if not bg(px[x, y]):
            continue
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)))
    return im


def main():
    for f in sorted(glob.glob(os.path.join(FACES, "*.png"))):
        name = os.path.basename(f)
        if name.startswith("decal_"):
            continue
        out = os.path.join(FACES, "decal_" + name)
        cut(f).save(out)
        print("wrote", out)


if __name__ == "__main__":
    main()
