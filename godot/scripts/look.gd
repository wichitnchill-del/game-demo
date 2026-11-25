extends RefCounted
## Shared "nice but cheap" look for every 3D scene (cutscenes, story battles, Battle Royale).
##
## Everything here works in the Compatibility (GL) renderer this project uses for
## phones/tablets, and nothing is a per-pixel heavy effect:
##   - filmic tone mapping + a light colour grade      (one fullscreen pass)
##   - soft directional shadows, limited distance       (shadow map already existed)
##   - a shadowless rim/fill light from behind          (one extra light, no shadow map)
##   - light depth fog toward the background colour     (per-pixel math in the main pass)
##   - anime cel shading + outlines on characters      (toon(): shader switches + one extra pass)
## Deliberately NOT used: glow (washes out the whole frame in Compatibility), SSAO,
## SSR, SSIL, SDFGI, volumetric fog (not available in Compatibility and/or too heavy).
##
## Use:  Look.apply(env, sun, owner_node, fog_color, fog_density)
## Turn off for comparison / very weak devices with the user arg  --plain-look

static func quality() -> String:
	if "--plain-look" in OS.get_cmdline_user_args():
		return "off"
	if OS.has_feature("mobile") or "--touch" in OS.get_cmdline_user_args():
		return "low"
	return "high"


static func apply(e: Environment, sun: DirectionalLight3D, owner: Node, fog_color := Color(0, 0, 0, 0), fog_density := 0.006) -> void:
	var q := quality()
	if q == "off":
		return
	# linear tone mapping: our scenes are bright, flat-coloured (anime); filmic/ACES
	# compressed them into a washed-out grey look, so keep linear and grade instead
	e.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	e.tonemap_exposure = 1.0
	# light grade: a little more colour and contrast for the anime look
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.15
	e.adjustment_contrast = 1.1
	e.adjustment_brightness = 1.0
	# depth fog: far things fade toward the background -> depth without extra geometry
	if fog_color.a > 0.0:
		e.fog_enabled = true
		e.fog_light_color = Color(fog_color.r, fog_color.g, fog_color.b)
		e.fog_density = fog_density * (0.8 if q == "low" else 1.0)
		e.fog_sky_affect = 0.0
	# no glow: in the Compatibility renderer it ignores the HDR threshold and
	# lightens the whole frame (navy arena sky turned lavender, city went hazy)
	e.glow_enabled = false
	# soft, stable sun shadows
	if sun:
		sun.shadow_enabled = true
		sun.shadow_blur = 1.6 if q == "high" else 1.0
		sun.shadow_bias = 0.04
		sun.shadow_normal_bias = 1.2
		sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if q == "high" else DirectionalLight3D.SHADOW_ORTHOGONAL
		if sun.directional_shadow_max_distance > 80.0:
			sun.directional_shadow_max_distance = 80.0
		# rim/fill light: from behind and opposite the sun, cool tint, no shadows.
		# Outlines characters against the background and lifts the shadow side.
		if owner and owner.get_node_or_null("RimLight") == null:
			var rim := DirectionalLight3D.new()
			rim.name = "RimLight"
			rim.rotation_degrees = Vector3(-25, sun.rotation_degrees.y + 160.0, 0)
			rim.light_color = Color("b8c8ff")
			rim.light_energy = 0.8 if q == "high" else 0.6
			rim.light_specular = 0.6
			rim.shadow_enabled = false
			owner.add_child(rim)


## Anime cel look for character materials: hard light/shadow bands (toon diffuse),
## a small toon highlight, a soft rim, and optionally a thin dark outline drawn as an
## inverted hull (second pass of the same mesh, front faces culled). All cheap:
## toon/rim are shader switches; the outline redraws only the characters.
const OUTLINE_COLOR := Color("2a1c1c")


static func toon(m: StandardMaterial3D, outline := true, outline_width := 0.012) -> StandardMaterial3D:
	if quality() == "off":
		return m
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.55
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	if outline and m.next_pass == null and m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED:
		var o := StandardMaterial3D.new()
		o.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		o.albedo_color = OUTLINE_COLOR
		o.cull_mode = BaseMaterial3D.CULL_FRONT
		o.grow = true
		o.grow_amount = outline_width
		m.next_pass = o
	return m


## Toon every material on an imported model (e.g. Blender temp characters).
static func toon_model(root: Node, outline_width := 0.012) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i) as StandardMaterial3D
			if src:
				(mi as MeshInstance3D).set_surface_override_material(i, toon(src.duplicate(), true, outline_width))
