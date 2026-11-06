extends RefCounted
## Constrói o Vale de Noro e os arredores: vila, estrada, floresta, portão da
## Academia e a arena. Tudo por código (primitivos) — sem assets externos.

const SEED := 20240613

static func build(root: Node3D) -> void:
	var wb := preload("res://src/world/world_builder.gd").new()
	wb.root = root
	wb._build_environment()
	wb._build_ground_and_road()
	wb._build_village()
	wb._build_forest()
	wb._build_academy_and_arena()
	wb._build_mountains()
	wb._spawn_npcs()
	wb._spawn_pickups()
	wb._spawn_enemies()

var root: Node3D
var rng := RandomNumberGenerator.new()

# -------------------------------------------------------------- materiais ---
func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.9, emissive: Color = Color.BLACK, energy: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emissive != Color.BLACK:
		m.emission_enabled = true
		m.emission = emissive
		m.emission_energy_multiplier = energy
	return m

# --------------------------------------------------------------- helpers ----
func _static_body(size: Vector3, pos: Vector3, mat: StandardMaterial3D, rot_y: float = 0.0, shadow: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(mi)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	col.shape = cs
	body.add_child(col)
	root.add_child(body)
	return body

func _visual_box(size: Vector3, pos: Vector3, mat: StandardMaterial3D, rot_y: float = 0.0, rot_z: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	mi.rotation.z = rot_z
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	return mi

func _static_cyl(r: float, height: float, pos: Vector3, mat: StandardMaterial3D, collidable: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	body.add_child(mi)
	if collidable:
		var col := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = r
		cs.height = height
		col.shape = cs
		body.add_child(col)
	root.add_child(body)
	return body

func _visual_cyl(r_top: float, r_bottom: float, height: float, pos: Vector3, mat: StandardMaterial3D, rot_z: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.z = rot_z
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	return mi

func _visual_cone(r: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = r
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	return mi

func _roof(width: float, height: float, depth: float, pos: Vector3, mat: StandardMaterial3D, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = Vector3(width, height, depth)
	mi.mesh = pm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	return mi

func _road_segment(from_p: Vector3, to_p: Vector3, width: float) -> void:
	var delta := to_p - from_p
	var length := delta.length()
	var mid := (from_p + to_p) * 0.5
	var mat := _mat(Color(0.42, 0.35, 0.25), 0.0, 0.95)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, 0.06, length)
	mi.mesh = bm
	mi.material_override = mat
	mi.position = Vector3(mid.x, 0.03, mid.z)
	mi.rotation.y = atan2(delta.x, delta.z)
	root.add_child(mi)

# -------------------------------------------------------------- ambiente ----
func _build_environment() -> void:
	# Sol
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38.0, 28.0, 0.0)
	sun.light_energy = 1.25
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_map_size = 2048
	root.add_child(sun)
	# Ambiente + céu procedural + nevoeiro
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.18, 0.38, 0.68)
	sky_mat.sky_horizon_color = Color(0.82, 0.75, 0.6)
	sky_mat.ground_bottom_color = Color(0.24, 0.22, 0.18)
	sky_mat.ground_horizon_color = Color(0.55, 0.48, 0.38)
	sky_mat.sun_angle_max = 12.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.75
	env.fog_enabled = true
	env.fog_density = 0.0058
	env.fog_light_color = Color(0.78, 0.72, 0.58)
	env.volumetric_fog_enabled = false
	world_env.environment = env
	root.add_child(world_env)

# ------------------------------------------------------- chão e estrada -----
func _build_ground_and_road() -> void:
	var grass := _mat(Color(0.30, 0.44, 0.22), 0.0, 0.95)
	_static_body(Vector3(170.0, 1.0, 170.0), Vector3(0, -0.5, -10), grass, 0.0, false)
	# Terra na praça da vila
	_visual_cyl(9.5, 9.5, 0.05, Vector3(0, 0.03, 31), _mat(Color(0.45, 0.38, 0.26), 0.0, 0.97))
	# Prado mais escuro sob a floresta
	_visual_cyl(26.0, 26.0, 0.04, Vector3(0, 0.02, -18), _mat(Color(0.23, 0.36, 0.18), 0.0, 0.97))
	# Estrada: vila → portão, com curva suave
	_road_segment(Vector3(0, 0, 36), Vector3(2.2, 0, 4), 4.4)
	_road_segment(Vector3(2.2, 0, 4), Vector3(-1.6, 0, -27), 4.4)
	_road_segment(Vector3(-1.6, 0, -27), Vector3(0, 0, -55), 4.6)

# ----------------------------------------------------------------- vila -----
func _build_village() -> void:
	rng.seed = SEED
	var plaster := _mat(Color(0.82, 0.74, 0.58), 0.0, 0.9)
	var plaster2 := _mat(Color(0.72, 0.62, 0.48), 0.0, 0.9)
	var timber := _mat(Color(0.38, 0.26, 0.16), 0.0, 0.85)
	var roof_a := _mat(Color(0.55, 0.28, 0.16), 0.0, 0.8)
	var roof_b := _mat(Color(0.42, 0.33, 0.22), 0.0, 0.85)
	var door_mat := _mat(Color(0.25, 0.16, 0.09), 0.0, 0.9)

	# Casas simples em volta da praça
	var houses := [
		{"pos": Vector3(-7.5, 0, 25.5), "rot": 0.5, "size": Vector3(3.4, 2.3, 2.8)},
		{"pos": Vector3(7.0, 0, 24.8), "rot": -0.4, "size": Vector3(3.0, 2.2, 2.6)},
		{"pos": Vector3(-10.5, 0, 34.0), "rot": 1.35, "size": Vector3(3.6, 2.4, 3.0)},
		{"pos": Vector3(10.0, 0, 33.5), "rot": -1.3, "size": Vector3(3.2, 2.3, 2.7)},
		{"pos": Vector3(-5.5, 0, 39.5), "rot": 2.9, "size": Vector3(3.8, 2.5, 3.2)},  # casa da mãe
		{"pos": Vector3(5.5, 0, 39.0), "rot": -2.8, "size": Vector3(3.0, 2.1, 2.5)},
		{"pos": Vector3(13.0, 0, 28.5), "rot": -1.05, "size": Vector3(2.8, 2.2, 2.4)},
	]
	for h in houses:
		var size: Vector3 = h["size"]
		var pos: Vector3 = h["pos"]
		var rot: float = h["rot"]
		_static_body(size, pos + Vector3(0, size.y * 0.5, 0), plaster if rng.randf() > 0.45 else plaster2, rot)
		_roof(size.x + 0.7, size.y * 0.62, size.z + 0.7, pos + Vector3(0, size.y + size.y * 0.28, 0), roof_a if rng.randf() > 0.5 else roof_b, rot)
		# Porta (visual)
		var door_offset := Vector3(sin(rot), 0, cos(rot)) * (size.z * 0.51)
		_visual_box(Vector3(0.7, 1.15, 0.08), pos + Vector3(0, 0.58, 0) + door_offset, door_mat, rot)

	# Forja do Garr (poente)
	var forge_pos := Vector3(-11.5, 0, 24.5)
	_static_body(Vector3(3.6, 2.3, 3.0), forge_pos + Vector3(0, 1.15, 0), _mat(Color(0.35, 0.3, 0.27)), 0.35)
	_visual_cyl(0.42, 0.5, 1.6, forge_pos + Vector3(0.9, 3.1, -0.5), timber)
	_visual_cyl(0.32, 0.34, 0.18, forge_pos + Vector3(-0.6, 0.28, 1.35), _mat(Color(0.18, 0.18, 0.2), 0.6, 0.4))  # bigorna
	_visual_box(Vector3(0.6, 0.18, 0.6), forge_pos + Vector3(-0.6, 0.11, 1.35), timber)
	_visual_box(Vector3(0.9, 0.12, 0.9), forge_pos + Vector3(0.4, 0.35, 1.3), _mat(Color(1.0, 0.45, 0.1), 0.0, 0.6, Color(1.0, 0.4, 0.05), 2.6))  # brasas
	var fire_light := PointLight3D.new()
	fire_light.position = forge_pos + Vector3(0.4, 1.1, 1.3)
	fire_light.light_color = Color(1.0, 0.55, 0.2)
	fire_light.light_energy = 2.2
	fire_light.omni_range = 6.5
	root.add_child(fire_light)

	# Poço no centro da praça
	_static_cyl(0.95, 0.85, Vector3(0, 0.42, 31), _mat(Color(0.5, 0.5, 0.52)))
	_visual_cyl(0.72, 0.72, 0.1, Vector3(0, 0.9, 31), _mat(Color(0.2, 0.25, 0.3)))
	for sx in [-1, 1]:
		_visual_box(Vector3(0.12, 1.5, 0.12), Vector3(sx * 0.8, 1.5, 31), timber)
	_roof(2.1, 0.65, 1.6, Vector3(0, 2.45, 31), roof_b)

	# Banca de mercado
	var stall := Vector3(5.6, 0, 29.6)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_visual_box(Vector3(0.1, 1.5, 0.1), stall + Vector3(sx * 0.75, 0.75, sz * 0.55), timber)
	_visual_box(Vector3(2.0, 0.09, 1.5), stall + Vector3(0, 1.52, 0), _mat(Color(0.62, 0.18, 0.14)))
	_visual_box(Vector3(1.6, 0.35, 1.1), stall + Vector3(0, 0.78, 0), timber)
	_visual_box(Vector3(0.5, 0.3, 0.4), stall + Vector3(-0.4, 1.02, 0), _mat(Color(0.7, 0.55, 0.2)))   # fruta
	_visual_box(Vector3(0.45, 0.25, 0.4), stall + Vector3(0.35, 1.0, 0.1), _mat(Color(0.5, 0.28, 0.12))) # potes

	# Postes de luz na praça
	for p in [Vector3(-4.5, 0, 27.5), Vector3(4.5, 0, 34.5), Vector3(-4.5, 0, 34.5), Vector3(4.5, 0, 27.5)]:
		_visual_cyl(0.09, 0.11, 2.6, p + Vector3(0, 1.3, 0), timber)
		_visual_cyl(0.16, 0.22, 0.24, p + Vector3(0, 2.7, 0), _mat(Color(0.9, 0.75, 0.3), 0.0, 0.5, Color(0.9, 0.7, 0.25), 1.8))

	# Cerca da estrada (algumas tábuas)
	for i in range(6):
		var z := 12.0 - i * 3.5
		var x := 3.1 if i % 2 == 0 else -3.3
		_visual_box(Vector3(0.16, 0.85, 1.6), Vector3(x, 0.42, z), timber, 0.15 * (1 if i % 2 == 0 else -1))

# -------------------------------------------------------------- floresta ----
func _build_forest() -> void:
	rng.seed = SEED + 7
	var trunk := _mat(Color(0.36, 0.24, 0.14), 0.0, 0.9)
	var pine := _mat(Color(0.16, 0.34, 0.16), 0.0, 0.9)
	var pine_dark := _mat(Color(0.12, 0.27, 0.13), 0.0, 0.9)
	var oak := _mat(Color(0.2, 0.4, 0.17), 0.0, 0.9)
	var tree_positions: Array[Vector3] = []
	for i in range(80):
		var x := rng.randf_range(-30.0, 30.0)
		var z := rng.randf_range(-34.0, 1.0)
		# Manter a estrada livre
		if z > -2.0:
			if absf(x - 1.2) < 4.0:
				continue
		elif absf(x) < 3.6:
			continue
		# Manter a clareira da emboscada respirável
		if absf(x) < 4.5 and z > -18.0 and z < -8.0:
			continue
		tree_positions.append(Vector3(x, 0, z))
	for p in tree_positions:
		var h := rng.randf_range(1.1, 1.7)
		_visual_cyl(0.2, 0.26, h, p + Vector3(0, h * 0.5, 0), trunk)
		# Colisão no tronco
		var trunk_body := StaticBody3D.new()
		trunk_body.position = p + Vector3(0, h * 0.5, 0)
		var col := CollisionShape3D.new()
		var cs := CylinderShape3D.new()
		cs.radius = 0.32
		cs.height = h
		col.shape = cs
		trunk_body.add_child(col)
		root.add_child(trunk_body)
		var kind := rng.randf()
		if kind < 0.55:
			var c := pine_dark if rng.randf() < 0.5 else pine
			_visual_cone(rng.randf_range(1.3, 1.8), 2.4, p + Vector3(0, h + 1.1, 0), c)
			_visual_cone(rng.randf_range(0.85, 1.2), 1.7, p + Vector3(0, h + 2.3, 0), c)
		else:
			var canopy := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = rng.randf_range(1.2, 1.7)
			sm.height = sm.radius * 1.7
			canopy.mesh = sm
			canopy.material_override = oak
			canopy.position = p + Vector3(0, h + 1.3, 0)
			canopy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			root.add_child(canopy)
	# Rochas
	var rock := _mat(Color(0.42, 0.42, 0.46), 0.1, 0.85)
	for i in range(14):
		var x := rng.randf_range(-28.0, 28.0)
		var z := rng.randf_range(-33.0, 2.0)
		if absf(x) < 3.8:
			continue
		var s := rng.randf_range(0.5, 1.4)
		_static_body(Vector3(s, s * 0.7, s * 0.8), Vector3(x, s * 0.3, z), rock, rng.randf_range(0, PI))

# --------------------------------------------------- academia e arena -------
func _build_academy_and_arena() -> void:
	var stone := _mat(Color(0.78, 0.79, 0.82), 0.05, 0.7)
	var stone_dark := _mat(Color(0.52, 0.53, 0.58), 0.05, 0.75)
	var white_gold := _mat(Color(0.88, 0.85, 0.74), 0.15, 0.55)
	var gold := _mat(Color(0.85, 0.68, 0.25), 0.65, 0.3)
	var banner := _mat(Color(0.1, 0.3, 0.55), 0.0, 0.7)

	# Muralha com portão (abertura central de ~4.6 de largura)
	_static_body(Vector3(17.0, 5.2, 1.6), Vector3(-13.3, 2.6, -55.5), stone)
	_static_body(Vector3(17.0, 5.2, 1.6), Vector3(13.3, 2.6, -55.5), stone)
	_static_body(Vector3(5.2, 1.7, 1.6), Vector3(0, 4.35, -55.5), stone)  # verga do portão
	# Torres gémeas
	_static_cyl(1.7, 8.6, Vector3(-6.4, 4.3, -55.8), white_gold)
	_static_cyl(1.7, 8.6, Vector3(6.4, 4.3, -55.8), white_gold)
	_visual_cone(1.9, 2.2, Vector3(-6.4, 9.6, -55.8), gold)
	_visual_cone(1.9, 2.2, Vector3(6.4, 9.6, -55.8), gold)
	# Faixas da academia
	for sx in [-1, 1]:
		_visual_box(Vector3(0.9, 3.0, 0.12), Vector3(sx * 3.1, 3.1, -54.6), banner)
		_visual_box(Vector3(0.9, 0.35, 0.13), Vector3(sx * 3.1, 1.75, -54.6), gold)
	# Grande edifício principal (fundo, só visual)
	_visual_box(Vector3(23.0, 9.0, 8.0), Vector3(0, 4.5, -66.5), white_gold)
	_visual_box(Vector3(25.0, 1.1, 9.0), Vector3(0, 9.2, -66.5), gold)
	for tx in [-8.0, 0.0, 8.0]:
		_visual_cyl(1.15, 1.35, 6.5, Vector3(tx, 12.4, -66.5), white_gold)
		_visual_cone(1.45, 2.4, Vector3(tx, 17.0, -66.5), gold)
	# Domo central
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.4
	sphere.height = 2.4
	dome.mesh = sphere
	dome.material_override = gold
	dome.position = Vector3(0, 9.8, -66.5)
	root.add_child(dome)

	# Portão fechado (visual) + grades
	_visual_box(Vector3(4.2, 3.6, 0.3), Vector3(0, 1.8, -55.6), _mat(Color(0.18, 0.16, 0.2), 0.4, 0.5))

	# --- Arena do Guardião (nascente) ---
	var arena_center := Vector3(17.0, 0, -44.0)
	_visual_cyl(8.6, 8.6, 0.09, Vector3(arena_center.x, 0.045, arena_center.z), _mat(Color(0.55, 0.52, 0.48)))
	_visual_cyl(9.35, 9.35, 0.04, Vector3(arena_center.x, 0.02, arena_center.z), stone_dark, 0.0)
	# Pilares em anel
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var px := arena_center.x + cos(angle) * 7.3
		var pz := arena_center.z + sin(angle) * 7.3
		_static_cyl(0.42, 2.7, Vector3(px, 1.7, pz), stone)
		_visual_box(Vector3(1.0, 0.28, 1.0), Vector3(px, 3.15, pz), stone_dark)
	# Palanques (3 degraus) a sul
	for i in range(3):
		var w := 10.0 - float(i) * 2.2
		_visual_box(Vector3(w, 0.35, 1.6), Vector3(arena_center.x, 0.2 + float(i) * 0.35, arena_center.z + 9.6 - float(i) * 1.3), stone_dark)

# ------------------------------------------------------------- montanhas ----
func _build_mountains() -> void:
	rng.seed = SEED + 31
	var rock := _mat(Color(0.36, 0.4, 0.5), 0.05, 0.85)
	var snow := _mat(Color(0.85, 0.88, 0.94), 0.0, 0.6)
	for i in range(11):
		var angle := PI + (PI * float(i) / 10.0) - PI / 2.0  # semicírculo norte/lados
		if i % 2 == 0:
			angle = -PI / 2.0 + (float(i) - 5.0) * 0.62
		var dist := rng.randf_range(78.0, 96.0)
		var x := cos(angle) * dist
		var z := -10.0 + sin(angle) * dist
		var h := rng.randf_range(14.0, 32.0)
		var r := rng.randf_range(9.0, 17.0)
		_visual_cone(r, h, Vector3(x, h * 0.5 - 0.5, z), rock)
		_visual_cone(r * 0.42, h * 0.34, Vector3(x, h * 0.86 - 0.5, z), snow)

# ------------------------------------------------------------- spawns -------
func _spawn_npcs() -> void:
	var npc_scene := preload("res://scenes/npc.tscn")
	var defs := [
		{"name": "Elen Noro", "id": "elen", "color": Color(0.55, 0.32, 0.3), "pos": Vector3(-5.4, 0, 37.2)},
		{"name": "Garr, o Ferreiro", "id": "garr", "color": Color(0.32, 0.3, 0.32), "pos": Vector3(-10.3, 0, 26.3)},
		{"name": "Tomás, o Aldeão", "id": "aldeao", "color": Color(0.35, 0.42, 0.3), "pos": Vector3(2.2, 0, 29.0)},
		{"name": "Liora Venn", "id": "liora", "color": Color(0.85, 0.8, 0.88), "pos": Vector3(1.4, 0, -51.2)},
		{"name": "Mestre Dario Vale", "id": "dario", "color": Color(0.22, 0.28, 0.5), "pos": Vector3(17.0, 0.0, -42.6)},
	]
	for d in defs:
		var npc := npc_scene.instantiate()
		npc.set("npc_name", d["name"])
		npc.set("dialogue_id", d["id"])
		npc.set("robe_color", d["color"])
		npc.position = d["pos"]
		root.add_child(npc)

func _spawn_pickups() -> void:
	rng.seed = SEED + 77
	var pickup_scene := preload("res://scenes/pickup.tscn")
	var placed := 0
	while placed < 12:
		var x := rng.randf_range(-26.0, 26.0)
		var z := rng.randf_range(-32.0, -2.0)
		if absf(x) < 3.6:
			continue
		var pickup := pickup_scene.instantiate()
		pickup.position = Vector3(x, 0.55, z)
		root.add_child(pickup)
		placed += 1

func _spawn_enemies() -> void:
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var wolves := [Vector3(-7.0, 0.2, -13.0), Vector3(8.5, 0.2, -21.0), Vector3(3.5, 0.2, -5.0)]
	for pos in wolves:
		var wolf := enemy_scene.instantiate()
		wolf.set("enemy_type", "wolf")
		wolf.position = pos
		root.add_child(wolf)
