"""Core Blaker dust FX, generated in Blender.
Run:  Blender -b --factory-startup --python blender/make_dust.py
Makes low-poly stylised dust clouds and exports them as glTF for Godot:
  godot/assets/fx/dust_puff.glb   - one lumpy puff (footsteps, sprint)
  godot/assets/fx/dust_ring.glb   - ring of puffs (landing / slam)
  godot/assets/fx/dust_burst.glb  - flat star burst (jump take-off)
Also saves blender/dust_fx.blend so the shapes can be edited by hand.
"""
import bpy, bmesh, math, random, os
from mathutils import Vector, noise

random.seed(7)
here = os.path.dirname(os.path.abspath(__file__))
out_dir = os.path.join(here, "..", "godot", "assets", "fx")
os.makedirs(out_dir, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)

def material(name, rgb):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = 1.0
    return m

DUST = material("Dust", (0.86, 0.80, 0.70))

def lump(radius, center, seed):
    """Low-poly icosphere pushed around by noise = one cartoon dust lump."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=2, radius=radius)
    off = Vector((seed * 3.1, seed * 1.7, seed * 0.9))
    for v in bm.verts:
        n = noise.noise(v.co * 2.2 + off)
        v.co *= 1.0 + 0.28 * n
        v.co.z *= 0.8
        v.co += Vector(center)
    return bm

def build(name, lumps):
    bm = bmesh.new()
    for i, (r, c) in enumerate(lumps):
        b = lump(r, c, i + len(name))
        tmp = bpy.data.meshes.new("tmp")
        b.to_mesh(tmp)
        bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)
        b.free()
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = False   # faceted, stylised
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    me.materials.append(DUST)
    return ob

objs = []
# 1) puff: 4 lumps, ~0.5 m wide, sitting on the ground
objs.append(build("dust_puff", [(0.22, (0, 0, 0.18)), (0.16, (0.17, 0.05, 0.13)), (0.15, (-0.15, 0.07, 0.12)), (0.12, (0.03, -0.14, 0.11))]))
# 2) ring: 10 lumps around a 0.9 m circle
ring = []
for i in range(10):
    a = i / 10 * math.tau
    ring.append((random.uniform(0.14, 0.2), (math.cos(a) * 0.9, math.sin(a) * 0.9, 0.12)))
objs.append(build("dust_ring", ring))
# 3) burst: flat spiky star for take-off
bm = bmesh.new()
pts = []
for i in range(16):
    a = i / 16 * math.tau
    r = 0.75 if i % 2 == 0 else 0.3
    pts.append(bm.verts.new((math.cos(a) * r, math.sin(a) * r, 0.02)))
bm.faces.new(pts)
me = bpy.data.meshes.new("dust_burst")
bm.to_mesh(me); bm.free()
burst = bpy.data.objects.new("dust_burst", me)
bpy.context.collection.objects.link(burst)
me.materials.append(DUST)
objs.append(burst)

for i, ob in enumerate(objs):
    ob.location.x = i * 3.0   # lay them out side by side in the .blend
for ob in objs:
    bpy.ops.object.select_all(action="DESELECT")
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    loc = ob.location.copy()
    ob.location = (0, 0, 0)
    bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, ob.name + ".glb"), use_selection=True, export_format="GLB", export_yup=True)
    ob.location = loc
    print("exported", ob.name, len(ob.data.vertices), "verts")

bpy.ops.wm.save_as_mainfile(filepath=os.path.join(here, "dust_fx.blend"))
print("DONE")
