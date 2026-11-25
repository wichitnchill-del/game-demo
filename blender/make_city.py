"""Modern city street block for Core Blaker (references: Bangkok skytrain street,
a Japanese waterfront avenue with curved residential towers, round street trees).

Builds, in metres (Z up, street runs along Y):
  - divided road (2 x 3 lanes) with a hedge median, lane markings, raised sidewalks + hedges
  - street trees (round leafy canopies + slim columnar trees) and street lamps
  - a curved residential tower with balcony bands, a glass office tower with fins,
    a white glass tower, a low mall with a canopy, and background towers
  - an elevated skytrain viaduct over the median with a 3-car train (white / blue / red)

Run:
  Blender --background --python blender/make_city.py
Outputs:
  godot/assets/models/city_block.glb      (for Godot)
  blender/city_block.blend                 (editable)
  godot/screenshots/city_preview*.png      (Eevee renders)
"""
import math
import os
import random

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
GODOT = os.path.join(HERE, "..", "godot")
rnd = random.Random(42)

LENGTH = 140.0          # street length (Y)
ROAD_HALF = 7.5         # carriageway half-width incl. median
MEDIAN = 1.0            # median half-width
WALK = 5.0              # sidewalk width


# ---------------------------------------------------------------- materials
def _lin(hexcol):
    c = [int(hexcol[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple((v / 12.92) if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c) + (1.0,)


def mat(name, hexcol, rough=0.8, metal=0.0, emit=0.0):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = _lin(hexcol)
    b.inputs["Roughness"].default_value = rough
    b.inputs["Metallic"].default_value = metal
    if emit:
        b.inputs["Emission Color"].default_value = _lin(hexcol)
        b.inputs["Emission Strength"].default_value = emit
    return m


M = {}


def init_materials():
    M.update({
        "asphalt": mat("asphalt", "3a3c42", 0.9),
        "marking": mat("marking", "f2f2ee", 0.6),
        "yellow": mat("yellow_line", "e8b030", 0.6),
        "walk": mat("sidewalk", "b8b4aa", 0.85),
        "curb": mat("curb", "d8d6d0", 0.8),
        "hedge": mat("hedge", "3f7a2c", 0.9),
        "leaf": mat("leaf", "4f9a2e", 0.85),
        "leaf2": mat("leaf_light", "78bf3a", 0.85),
        "leaf3": mat("leaf_dark", "2f6e24", 0.9),
        "bark": mat("bark", "6a5040", 0.9),
        "pole": mat("pole", "9aa0a8", 0.4, 0.6),
        "lamp": mat("lamp", "fff4d0", 0.3, 0.0, 2.0),
        "concrete": mat("concrete", "c8c6c0", 0.85),
        "white": mat("white_facade", "f0f0ec", 0.6),
        "glass": mat("glass", "5a8ab8", 0.08, 0.3),
        "glass_dark": mat("glass_dark", "2e4a66", 0.1, 0.3),
        "glass_teal": mat("glass_teal", "5aa8a0", 0.1, 0.3),
        "copper": mat("copper_fin", "c8642e", 0.5, 0.5),
        "train_white": mat("train_white", "eef0f2", 0.35),
        "train_blue": mat("train_blue", "1e4aa0", 0.4),
        "train_red": mat("train_red", "d02a2a", 0.4),
        "train_window": mat("train_window", "1a222e", 0.1, 0.2),
        "rail": mat("rail", "7a7a80", 0.3, 0.8),
        "grass": mat("grass", "5a8a3a", 0.95),
        "plaza": mat("plaza", "a8a49a", 0.9),
    })


# ---------------------------------------------------------------- primitives
def box(name, loc, size, m, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    o.data.materials.append(M[m] if isinstance(m, str) else m)
    if parent:
        o.parent = parent
    return o


def cyl(name, loc, r, depth, m, verts=16, rot=(0, 0, 0), r2=None):
    if r2 is None:
        bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=loc, rotation=rot)
    else:
        bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r, radius2=r2, depth=depth, location=loc, rotation=rot)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(M[m])
    return o


def blob(name, loc, r, m):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=r, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(M[m])
    bpy.ops.object.shade_smooth()
    return o


def array_y(o, count, step):
    md = o.modifiers.new("arr", "ARRAY")
    md.count = count
    md.use_relative_offset = False
    md.use_constant_offset = True
    md.constant_offset_displace = (0, step / o.scale.y if o.scale.y else step, 0)
    return o


def collection(name):
    c = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(c)
    return c


def into(col, objs):
    for o in objs:
        for c in o.users_collection:
            c.objects.unlink(o)
        col.objects.link(o)


# ---------------------------------------------------------------- street
def street():
    objs = [box("ground", (0, 0, -0.12), (320, 320, 0.1), "plaza")]   # paved city ground under everything
    y0 = -LENGTH / 2
    objs.append(box("road", (0, 0, -0.05), (ROAD_HALF * 2, LENGTH, 0.1), "asphalt"))
    # median: curb + hedge
    objs.append(box("median_curb", (0, 0, 0.08), (MEDIAN * 2, LENGTH, 0.16), "curb"))
    objs.append(box("median_hedge", (0, 0, 0.45), (MEDIAN * 1.6, LENGTH, 0.6), "hedge"))
    # sidewalks + curbs + hedges, both sides
    for s in (-1, 1):
        xw = s * (ROAD_HALF + WALK / 2)
        objs.append(box(f"walk_{s}", (xw, 0, 0.08), (WALK, LENGTH, 0.16), "walk"))
        objs.append(box(f"curb_{s}", (s * (ROAD_HALF + 0.1), 0, 0.09), (0.2, LENGTH, 0.18), "curb"))
        objs.append(box(f"hedge_{s}", (s * (ROAD_HALF + 0.8), 0, 0.5), (0.9, LENGTH, 0.7), "hedge"))
        objs.append(box(f"verge_{s}", (s * (ROAD_HALF + WALK + 4), 0, 0.02), (8, LENGTH, 0.04), "grass"))
        # lane markings: 2 dashed lines per carriageway + solid edge
        for lane in (1, 2):
            x = s * (MEDIAN + lane * 2.15)
            d = box(f"dash_{s}_{lane}", (x, y0 + 2, 0.005), (0.15, 3.0, 0.01), "marking")
            array_y(d, int(LENGTH / 8), 8.0)
            objs.append(d)
        objs.append(box(f"edge_{s}", (s * (ROAD_HALF - 0.35), 0, 0.005), (0.15, LENGTH, 0.01), "marking"))
        objs.append(box(f"centre_{s}", (s * (MEDIAN + 0.2), 0, 0.005), (0.12, LENGTH, 0.01), "yellow"))
    # pedestrian crossing near the camera end
    for i in range(10):
        objs.append(box(f"zebra_{i}", (-ROAD_HALF + 0.75 + i * 1.5, y0 + 14, 0.006), (0.7, 4.0, 0.01), "marking"))
    into(collection("street"), objs)


# ---------------------------------------------------------------- trees / lamps
def round_tree(name, loc, h):
    """Leafy deciduous tree (like the reference): trunk + forked branches + clustered canopy."""
    x, y, z = loc
    parts = [cyl(name + "_trunk", (x, y, z + h * 0.22), 0.16 * h / 6, h * 0.45, "bark", 8, r2=0.1 * h / 6)]
    cr = h * 0.33
    cz = z + h * 0.62
    leaf = ["leaf", "leaf2", "leaf3"]
    parts.append(blob(name + "_c0", (x, y, cz), cr, "leaf"))
    for k in range(7):
        a = k / 7 * math.tau + rnd.uniform(-0.3, 0.3)
        rr = cr * rnd.uniform(0.45, 0.65)
        parts.append(blob(f"{name}_c{k+1}",
                          (x + math.cos(a) * cr * 0.7, y + math.sin(a) * cr * 0.7, cz + rnd.uniform(-0.3, 0.6) * cr),
                          rr, leaf[k % 3]))
    parts.append(blob(name + "_top", (x, y, cz + cr * 0.75), cr * 0.55, "leaf2"))
    return parts


def column_tree(name, loc, h):
    """Slim upright street tree (ginkgo-like, as in the avenue reference)."""
    x, y, z = loc
    parts = [cyl(name + "_trunk", (x, y, z + h * 0.2), 0.12, h * 0.4, "bark", 8)]
    parts.append(cyl(name + "_crown", (x, y, z + h * 0.6), h * 0.17, h * 0.75, "leaf3", 10, r2=h * 0.03))
    for k in range(4):
        a = k * math.pi / 2
        parts.append(blob(f"{name}_tuft{k}", (x + math.cos(a) * h * 0.1, y + math.sin(a) * h * 0.1, z + h * (0.45 + 0.08 * k)),
                          h * 0.12, "leaf"))
    return parts


def lamp(name, x, y, side):
    parts = [cyl(name + "_pole", (x, y, 4.5), 0.09, 9.0, "pole", 10)]
    arm = cyl(name + "_arm", (x - side * 1.1, y, 8.9), 0.05, 2.4, "pole", 8, rot=(0, math.pi / 2, 0))
    parts.append(arm)
    parts.append(box(name + "_head", (x - side * 2.2, y, 8.8), (0.7, 0.3, 0.14), "lamp"))
    return parts


def greenery():
    objs = []
    y = -LENGTH / 2 + 6
    i = 0
    while y < LENGTH / 2 - 4:
        for s in (-1, 1):
            x = s * (ROAD_HALF + 2.2)
            h = rnd.uniform(6.5, 8.5)
            objs += (round_tree if (i + (s > 0)) % 3 else column_tree)(f"tree_{i}_{s}", (x, y + rnd.uniform(-0.6, 0.6), 0.16), h)
        if i % 2 == 0:
            for s in (-1, 1):
                objs += lamp(f"lamp_{i}_{s}", s * (ROAD_HALF + 0.6), y + 4, s)
        y += 9.0
        i += 1
    # a few big round trees on the verges
    for k in range(6):
        s = -1 if k % 2 else 1
        objs += round_tree(f"verge_tree_{k}", (s * (ROAD_HALF + WALK + 3), -50 + k * 18, 0.04), rnd.uniform(9, 12))
    into(collection("greenery"), objs)


# ---------------------------------------------------------------- buildings
def curved_tower(name, cx, cy, floors=28, fh=3.2):
    """Residential tower with a rounded plan and white balcony bands (like the reference)."""
    objs = []
    # core (glass) as a rounded slab: a cylinder squashed in X
    core = cyl(name + "_core", (cx, cy, floors * fh / 2), 9.0, floors * fh, "glass_dark", 40)
    core.scale = (0.75, 1.0, 1.0)
    objs.append(core)
    band = cyl(name + "_band", (cx, cy, 0.9), 9.6, 0.35, "white", 40)
    band.scale = (0.75, 1.0, 1.0)
    md = band.modifiers.new("floors", "ARRAY")
    md.count = floors
    md.use_relative_offset = False
    md.use_constant_offset = True
    md.constant_offset_displace = (0, 0, fh)
    objs.append(band)
    # balcony rail strip a little above each slab
    rail = cyl(name + "_rail", (cx, cy, 1.9), 9.65, 0.9, "glass", 40)
    rail.scale = (0.75, 1.0, 1.0)
    md = rail.modifiers.new("floors", "ARRAY")
    md.count = floors
    md.use_relative_offset = False
    md.use_constant_offset = True
    md.constant_offset_displace = (0, 0, fh)
    objs.append(rail)
    objs.append(cyl(name + "_roof", (cx, cy, floors * fh + 0.6), 9.0, 1.2, "white", 40))
    objs[-1].scale = (0.75, 1.0, 1.0)
    return objs


def grid_tower(name, cx, cy, w, d, h, glass="glass", fin="white", fin_step=2.0, floor_h=3.6, crown=None):
    """Glass box tower with vertical fins and floor bands."""
    objs = [box(name + "_glass", (cx, cy, h / 2), (w, d, h), glass)]
    for face in (-1, 1):
        # fins on the street-facing (x) faces
        fx = cx + face * (w / 2 + 0.12)
        f = box(f"{name}_fin{face}", (fx, cy - d / 2 + 0.2, h / 2), (0.25, 0.3, h), fin)
        md = f.modifiers.new("fins", "ARRAY")
        md.count = int(d / fin_step) + 1
        md.use_relative_offset = False
        md.use_constant_offset = True
        md.constant_offset_displace = (0, fin_step / 0.3, 0)
        objs.append(f)
    fl = box(name + "_floors", (cx, cy, floor_h), (w + 0.3, d + 0.3, 0.3), fin)
    md = fl.modifiers.new("floors", "ARRAY")
    md.count = int(h / floor_h) - 1
    md.use_relative_offset = False
    md.use_constant_offset = True
    md.constant_offset_displace = (0, 0, floor_h / 0.3)
    objs.append(fl)
    objs.append(box(name + "_cap", (cx, cy, h + 0.6), (w + 0.6, d + 0.6, 1.2), fin))
    if crown == "copper":
        # copper fins crowning the top (like the cylindrical building in the BTS reference)
        for k in range(10):
            a = k / 10 * math.tau
            objs.append(box(f"{name}_crown{k}", (cx + math.cos(a) * w * 0.45, cy + math.sin(a) * d * 0.45, h + 5),
                            (0.6, 0.6, 10), "copper"))
    return objs


def mall(name, cx, cy):
    objs = [box(name + "_body", (cx, cy, 6), (16, 40, 12), "white")]
    objs.append(box(name + "_glass", (cx - 8.05, cy, 5), (0.1, 36, 7), "glass"))
    objs.append(box(name + "_canopy", (cx - 9.5, cy, 9.5), (5, 42, 0.4), "concrete"))
    for k in range(12):   # vertical louvres on the upper wall
        objs.append(box(f"{name}_louvre{k}", (cx - 8.1, cy - 16 + k * 3, 11), (0.15, 0.4, 2.0), "concrete"))
    return objs


def buildings():
    objs = []
    left = -(ROAD_HALF + WALK + 14)
    right = ROAD_HALF + WALK + 14
    objs += curved_tower("res_tower", left, 8, floors=30)
    objs += grid_tower("glass_left", left + 2, -32, 20, 16, 34, "glass", "white", crown=None)
    objs += grid_tower("office_right", right, 30, 16, 18, 62, "glass_teal", "white", 1.6)
    objs += grid_tower("round_glass", right + 2, -14, 14, 14, 30, "glass_teal", "white", 1.4, crown="copper")
    objs += mall("mall", right + 4, -48)
    # background towers further back
    for k in range(10):
        s = -1 if k % 2 else 1
        x = s * rnd.uniform(48, 70)
        y = rnd.uniform(-60, 60)
        h = rnd.uniform(25, 75)
        g = ["glass", "glass_dark", "glass_teal"][k % 3]
        objs += grid_tower(f"bg_{k}", x, y, rnd.uniform(12, 20), rnd.uniform(12, 20), h, g, "white", 2.0)
    # distant tall obelisk-like monument (as in the BTS photo)
    objs.append(cyl("monument", (-40, 62, 22), 2.2, 44, "concrete", 4, r2=0.6))
    into(collection("buildings"), objs)


# ---------------------------------------------------------------- skytrain
VIADUCT_Z = 11.0


def skytrain():
    objs = []
    # piers + crossheads every 24 m along the median
    for k in range(int(LENGTH / 24) + 1):
        y = -LENGTH / 2 + 6 + k * 24
        objs.append(box(f"pier_{k}", (0, y, VIADUCT_Z / 2), (1.6, 1.6, VIADUCT_Z), "concrete"))
        objs.append(box(f"crosshead_{k}", (0, y, VIADUCT_Z - 0.4), (9.5, 2.0, 1.2), "concrete"))
    objs.append(box("deck", (0, 0, VIADUCT_Z + 0.5), (9.0, LENGTH, 0.8), "concrete"))
    for s in (-1, 1):
        objs.append(box(f"parapet_{s}", (s * 4.4, 0, VIADUCT_Z + 1.4), (0.25, LENGTH, 1.2), "concrete"))
        for r in (-0.72, 0.72):        # two rails per track
            objs.append(box(f"rail_{s}_{r}", (s * 2.1 + r, 0, VIADUCT_Z + 1.0), (0.1, LENGTH, 0.15), "rail"))
    objs += train("train", x=-2.1, y=-10)
    into(collection("skytrain"), objs)


def train(name, x, y, cars=3, car_len=20.0):
    objs = []
    z = VIADUCT_Z + 1.0
    for c in range(cars):
        cy = y + c * (car_len + 0.8)
        body = box(f"{name}_car{c}", (x, cy, z + 2.0), (3.1, car_len, 3.3), "train_white")
        bev = body.modifiers.new("bevel", "BEVEL")
        bev.width = 0.35
        bev.segments = 3
        objs.append(body)
        objs.append(box(f"{name}_blue{c}", (x, cy, z + 0.75), (3.14, car_len - 0.4, 0.8), "train_blue"))
        objs.append(box(f"{name}_red{c}", (x, cy, z + 1.25), (3.15, car_len - 0.4, 0.14), "train_red"))
        for s in (-1, 1):  # window band + doors on both sides
            objs.append(box(f"{name}_win{c}_{s}", (x + s * 1.56, cy, z + 2.45), (0.04, car_len - 1.5, 1.0), "train_window"))
            for dk in (-1, 0, 1):
                objs.append(box(f"{name}_door{c}_{s}_{dk}", (x + s * 1.57, cy + dk * 6.0, z + 1.9),
                                (0.04, 1.3, 2.3), "train_window"))
        objs.append(box(f"{name}_bogie{c}", (x, cy, z + 0.2), (2.4, car_len - 4, 0.4), "rail"))
    # cab face on the leading car (facing -Y, toward the camera)
    fy = y - car_len / 2 - 0.05
    objs.append(box(name + "_windshield", (x, fy, z + 2.55), (2.4, 0.06, 1.2), "train_window"))
    objs.append(box(name + "_noseblue", (x, fy, z + 0.9), (3.0, 0.08, 1.1), "train_blue"))
    for s in (-1, 1):
        objs.append(box(f"{name}_light{s}", (x + s * 1.0, fy - 0.03, z + 1.25), (0.4, 0.04, 0.16), "train_red"))
    return objs


# ---------------------------------------------------------------- scene / render
def lights_and_world():
    sun = bpy.data.lights.new("sun", "SUN")
    sun.energy = 4.5
    sun.color = (1.0, 0.95, 0.86)
    sun.angle = math.radians(2)
    so = bpy.data.objects.new("sun", sun)
    so.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    bpy.context.scene.collection.objects.link(so)
    w = bpy.data.worlds.new("sky")
    bpy.context.scene.world = w
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = _lin("6aa8ec")
    bg.inputs["Strength"].default_value = 0.35   # sky colour, but don't let it tint everything blue


def camera(name, loc, target):
    cam = bpy.data.cameras.new(name)
    cam.lens = 24
    co = bpy.data.objects.new(name, cam)
    bpy.context.scene.collection.objects.link(co)
    co.location = loc
    d = [t - l for t, l in zip(target, loc)]
    co.rotation_euler = (math.atan2(math.hypot(d[0], d[1]), -d[2]), 0, math.atan2(d[1], d[0]) - math.pi / 2)
    return co


def render(cam, path):
    sc = bpy.context.scene
    sc.camera = cam
    for eng in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            sc.render.engine = eng
            break
        except TypeError:
            continue
    sc.render.resolution_x = 1280
    sc.render.resolution_y = 720
    sc.render.filepath = path
    sc.view_settings.view_transform = "Standard"
    bpy.ops.render.render(write_still=True)
    print("rendered", os.path.normpath(path))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    init_materials()
    street()
    greenery()
    buildings()
    skytrain()
    lights_and_world()
    shots = [
        ("street_level", (11.6, -59.5, 1.7), (3, 30, 9)),         # pedestrian on the sidewalk, looking down the avenue
        ("skytrain", (16, -38, 15), (-2.1, -8, 13)),              # from a footbridge across the road: the train on the viaduct
        ("aerial", (-55, -90, 60), (0, 0, 10)),                   # overview
    ]
    cams = [camera(n, l, t) for n, l, t in shots]
    shots_dir = os.path.join(GODOT, "screenshots")
    os.makedirs(shots_dir, exist_ok=True)
    for c, (n, _, _) in zip(cams, shots):
        render(c, os.path.join(shots_dir, f"city_preview_{n}.png"))
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, "city_block.blend"))
    # export without cameras/lights; modifiers (arrays, bevels) applied
    for c in cams:
        c.select_set(False)
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.context.scene.objects:
        if o.type == "MESH":
            o.select_set(True)
    out = os.path.normpath(os.path.join(GODOT, "assets", "models", "city_block.glb"))
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=True, export_apply=True)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    print("exported", out, len(meshes), "objects")


main()
