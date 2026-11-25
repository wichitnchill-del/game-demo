"""Temporary low-poly character models for Core Blaker cutscenes.

Characters that have no 3D model yet get a simple stylized figure built from
primitives, so the story cutscene stage can show them instead of a capsule.
Replace with real models later — the game picks up assets/models/<id>.glb.

Run:
  Blender --background --python blender/make_temp_models.py -- piang clover
  (no ids = build every character in SPECS)

Blender is Z-up with the character facing -Y; the glTF exporter converts that
to Godot's Y-up / +Z-forward, which is how HumanModel actors face.
"""
import math
import os
import sys

import bpy

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "godot", "assets", "models")
SKIN = "f6cdb0"   # warm peach, matches human_model.gd

# height in metres; colours are hex; extras switch on optional parts.
SPECS = {
    # ป้าเพียง — late 50s, small, hair tied in a bun (greying), old cream apron
    "piang": dict(height=1.50, top="9a6a5a", bottom="6a4a3a", legs="d8c0a8", shoes="5a4a3a",
                  hair="3a3430", hair_style="bun", hair_grey=True, skirt=True, apron="efe6d0",
                  build=1.05),
    # แม่ (เอเลน) — luxury dress, perfectly set hair
    "mom": dict(height=1.66, top="7a2a4a", bottom="7a2a4a", legs="f2d2b4", shoes="2a1a1a",
                hair="3a2418", hair_style="set", skirt=True, build=0.92, necklace="f0e0a0"),
    # วิกเตอร์ — Oli's father, company president: dark grey suit, slicked hair, never smiles
    "victor": dict(height=1.84, top="3a3c44", bottom="3a3c44", legs="3a3c44", shoes="141418",
                   hair="1e1a18", hair_style="short", tie="5a1a2a", build=1.08),
    # ลิลี่ — 10, the favourite: long brown hair like Oli's, doll-like dress
    "lily": dict(height=1.36, top="f4c8d8", bottom="f4c8d8", legs="f8f0f0", shoes="c83a5a",
                 hair="8a3a22", hair_style="long", skirt=True, build=0.85, bow="e8506a"),
    # ครู — plain school teacher
    "teacher": dict(height=1.72, top="e8e8ee", bottom="3a4058", legs="3a4058", shoes="2a2a2e",
                    hair="2a2420", hair_style="short", tie="3a5a8a", build=1.0, glasses=True),
    # เอ็นจิ — 17, spiky red hair, open uniform, wrapped hands
    "enji": dict(height=1.80, top="f0f0f0", bottom="22242e", legs="22242e", shoes="2a2a2e",
                 hair="c8281a", hair_style="spiky", wraps="e8e0d0", build=1.1),
    # คาอิ — tall, buzz cut, sports jersey
    "kai": dict(height=1.86, top="2a6ad0", bottom="1e2a48", legs="1e2a48", shoes="f0f0f0",
                hair="1e1a16", hair_style="buzz", build=1.05, number=True),
    # ลูกน้อง (เอ็นจิ's gang) — generic thug
    "thug": dict(height=1.76, top="3a3a40", bottom="2a2a30", legs="2a2a30", shoes="1a1a1e",
                 hair="1a1a1e", hair_style="buzz", build=1.12),
}


# ---------------------------------------------------------------- helpers
def mat(hexcol, emission=0.0, alpha=1.0):
    key = f"{hexcol}_{emission}_{alpha}"
    if key in bpy.data.materials:
        return bpy.data.materials[key]
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    c = tuple(int(hexcol[i:i + 2], 16) / 255 for i in (0, 2, 4)) + (1.0,)
    # sRGB -> linear for the base colour
    lin = tuple((v / 12.92) if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c[:3]) + (1.0,)
    bsdf.inputs["Base Color"].default_value = lin
    bsdf.inputs["Roughness"].default_value = 0.8
    if emission > 0:
        bsdf.inputs["Emission Color"].default_value = lin
        bsdf.inputs["Emission Strength"].default_value = emission
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        m.blend_method = "BLEND" if hasattr(m, "blend_method") else None
    return m


def _finish(obj, colour, smooth=True, **mk):
    obj.data.materials.append(mat(colour, **mk))
    if smooth:
        bpy.ops.object.shade_smooth()
    return obj


def sphere(loc, scale, colour, segs=20, **mk):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segs, ring_count=segs // 2, location=loc)
    o = bpy.context.active_object
    o.scale = scale
    return _finish(o, colour, **mk)


def cyl(loc, r, depth, colour, rot=(0, 0, 0), r2=None, verts=16, smooth=True):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot)
    return _finish(bpy.context.active_object, colour, smooth)


def box(loc, size, colour, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = size
    return _finish(o, colour, smooth=False)


def limb(a, b, r, colour, r2=None):
    """Cylinder from point a to point b."""
    ax, ay, az = a
    bx, by, bz = b
    dx, dy, dz = bx - ax, by - ay, bz - az
    length = math.sqrt(dx * dx + dy * dy + dz * dz)
    mid = ((ax + bx) / 2, (ay + by) / 2, (az + bz) / 2)
    pitch = math.acos(dz / length)
    yaw = math.atan2(dy, dx)
    bpy.ops.mesh.primitive_cone_add(vertices=14, radius1=r, radius2=r2 if r2 else r, depth=length, location=mid)
    o = bpy.context.active_object
    # cone axis is +Z; point it along (dx,dy,dz)
    o.rotation_euler = (0, pitch, yaw)
    return _finish(o, colour)


# ---------------------------------------------------------------- humanoid
def humanoid(spec):
    s = spec["height"] / 1.75          # proportions are authored for 1.75 m
    w = spec.get("build", 1.0)
    P = lambda x, y, z: (x * s * w, y * s, z * s)

    # legs + shoes
    for side in (-1, 1):
        limb(P(side * 0.09, 0, 0.86), P(side * 0.09, 0, 0.10), 0.068 * s * w, spec["legs"], r2=0.055 * s * w)
        box(P(side * 0.09, -0.04, 0.045), (0.11 * s * w, 0.24 * s, 0.09 * s), spec["shoes"])
    # hips / skirt
    if spec.get("skirt"):
        cyl(P(0, 0, 0.72), 0.30 * s * w, 0.52 * s, spec["bottom"], r2=0.17 * s * w, verts=24)
    else:
        sphere(P(0, 0, 0.92), (0.19 * s * w, 0.13 * s, 0.13 * s), spec["bottom"])
    # torso
    sphere(P(0, 0, 1.22), (0.20 * s * w, 0.13 * s, 0.30 * s), spec["top"])
    if spec.get("apron"):
        box(P(0, -0.125, 0.86), (0.36 * s * w, 0.02 * s, 0.66 * s), spec["apron"])
        box(P(0, -0.135, 1.36), (0.20 * s * w, 0.02 * s, 0.10 * s), spec["apron"])  # bib
    if spec.get("tie"):
        box(P(0, -0.13, 1.25), (0.05 * s, 0.015 * s, 0.30 * s), spec["tie"])
    if spec.get("number"):
        box(P(0, -0.13, 1.24), (0.12 * s, 0.012 * s, 0.14 * s), "f0f0f0")
    if spec.get("necklace"):
        cyl(P(0, -0.02, 1.47), 0.10 * s, 0.015 * s, spec["necklace"], verts=20)
    # arms (slightly away from the body, relaxed)
    for side in (-1, 1):
        sh = P(side * 0.23, 0, 1.44)
        el = P(side * 0.29, 0.01, 1.14)
        wr = P(side * 0.31, -0.03, 0.88)
        sphere(sh, (0.075 * s * w,) * 3, spec["top"])
        limb(sh, el, 0.058 * s * w, spec["top"], r2=0.05 * s * w)
        limb(el, wr, 0.048 * s * w, spec.get("wraps", SKIN) if spec.get("wraps") else SKIN, r2=0.04 * s * w)
        sphere(P(side * 0.315, -0.035, 0.83), (0.05 * s,) * 3, spec.get("wraps", SKIN))
    # neck + head
    cyl(P(0, 0, 1.53), 0.05 * s, 0.10 * s, SKIN)
    hz = 1.66
    sphere(P(0, 0, hz), (0.115 * s, 0.12 * s, 0.135 * s), SKIN)
    for side in (-1, 1):   # eyes
        sphere(P(side * 0.042, -0.105, hz + 0.01), (0.017 * s, 0.01 * s, 0.022 * s), "1e1a1a", segs=10)
    if spec.get("glasses"):
        for side in (-1, 1):
            cyl((side * 0.042 * s, -0.12 * s, (hz + 0.01) * s), 0.03 * s, 0.006 * s, "c0c0c8",
                rot=(math.pi / 2, 0, 0), verts=16)
    hair(spec, s, hz)


def hair(spec, s, hz):
    col = spec["hair"]
    style = spec.get("hair_style", "short")
    # hair sits slightly back so its front edge stays behind the face
    top = lambda sc, dz=0.02, dy=0.035: sphere((0, dy * s, (hz + dz) * s), tuple(v * s for v in sc), col)
    if style == "bun":
        top((0.125, 0.13, 0.13))
        sphere((0, 0.12 * s, (hz + 0.08) * s), (0.07 * s,) * 3, col)
        if spec.get("hair_grey"):
            for side in (-1, 1):   # grey at the temples, swept back toward the bun
                box((side * 0.112 * s, 0.03 * s, (hz + 0.03) * s), (0.02 * s, 0.11 * s, 0.035 * s), "c8c4c0",
                    rot=(0.35, 0, 0))
            sphere((0.03 * s, 0.15 * s, (hz + 0.1) * s), (0.03 * s,) * 3, "c8c4c0")
    elif style == "long":
        top((0.125, 0.13, 0.13))
        sphere((0, 0.07 * s, (hz - 0.14) * s), (0.13 * s, 0.07 * s, 0.24 * s), col)   # hair down the back
        for side in (-1, 1):
            sphere((side * 0.1 * s, 0.0, (hz - 0.08) * s), (0.04 * s, 0.05 * s, 0.13 * s), col)
        if spec.get("bow"):
            sphere((0, 0.1 * s, (hz + 0.1) * s), (0.08 * s, 0.03 * s, 0.04 * s), spec["bow"])
    elif style == "set":
        top((0.13, 0.135, 0.14))
        sphere((0, 0.04 * s, (hz - 0.06) * s), (0.14 * s, 0.11 * s, 0.10 * s), col)
    elif style == "spiky":
        top((0.12, 0.125, 0.12), dz=0.03)
        for i in range(9):
            a = i / 9 * math.tau
            r = 0.08 * s
            cyl((math.cos(a) * r, math.sin(a) * r + 0.02 * s, (hz + 0.12) * s), 0.04 * s, 0.14 * s, col,
                rot=(math.sin(a) * -0.6, math.cos(a) * 0.6, 0), r2=0.0, verts=8, smooth=False)
    elif style == "buzz":
        top((0.118, 0.123, 0.12), dz=0.025)
    else:  # short
        top((0.124, 0.128, 0.125), dz=0.03)


# ---------------------------------------------------------------- spirit
def clover():
    """ใบสี่ — thumb-sized glowing spirit, shown enlarged so it reads in a shot.
    Hovers at chest height; four heart-shaped leaves around a tiny girl's face."""
    g = "2ec060"
    cz = 1.35
    for i in range(4):
        a = i * math.pi / 2 + math.pi / 4
        for k in (-1, 1):   # two lobes make a heart leaf
            b = a + k * 0.32
            sphere((math.cos(b) * 0.14, 0.0, cz + math.sin(b) * 0.14), (0.085, 0.02, 0.085), g, emission=0.35)
    limb((0, 0.0, cz - 0.05), (0.03, 0.0, cz - 0.38), 0.012, "3ac86a")    # stem
    sphere((0, -0.02, cz), (0.07, 0.065, 0.075), "d8f8e0", emission=0.15)   # face
    for side in (-1, 1):
        sphere((side * 0.025, -0.08, cz + 0.005), (0.009, 0.006, 0.013), "1e3a2a", segs=10)
    # clover-shaped hair tufts
    for side in (-1, 1):
        sphere((side * 0.05, 0.0, cz + 0.07), (0.035, 0.02, 0.035), "1e9a4a", emission=0.3)


# ---------------------------------------------------------------- build/export
def build(char_id):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if char_id == "clover":
        clover()
    else:
        humanoid(SPECS[char_id])
    objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    body = bpy.context.active_object
    body.name = char_id
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.abspath(os.path.join(OUT, f"{char_id}.glb"))
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=False)
    print("exported", path, len(body.data.polygons), "faces")


ids = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
for cid in ids or (list(SPECS) + ["clover"]):
    build(cid)
