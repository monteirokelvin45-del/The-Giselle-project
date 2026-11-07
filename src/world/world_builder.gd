extends RefCounted
## Constrói o Vale de Noro e os arredores: vila, estrada, floresta, portão da
## Academia e a arena. Modelos KayKit Medieval Hexagon (CC0) para edifícios,
## árvores e props; vegetação baixa gobkit (CC0); primitivos de código para
## terreno, estradas e detalhes. Colisores invisíveis garantem a geometria de
## jogo (independente do modelo).

const SEED := 20240613
const ENV := "res://assets/models/env/"
const GOBKIT := "res://assets/models/nature/"

static func build(root: Node3D) -> void:
	var wb := preload("res://src/world/world_builder.gd").new()
	wb.root = root
	wb._mk = preload("res://src/world/map_kit.gd").new(root, 13579)
	wb._build_environment()
	wb._build_ground_and_road()
	wb._build_flora()
	wb._build_village()
	wb._build_forest()
	wb._build_landmarks()
	wb._build_academy_and_arena()
	wb._build_mountains()
	wb._spawn_npcs()
	wb._spawn_pickups()
	wb._spawn_enemies()
	wb._build_ambience()
	wb._spawn_night()

var root: Node3D
var _mk  # MapKit (RefCounted) — composición v1.0
var rng := RandomNumberGenerator.new()
var _env_mf := preload("res://src/visuals/model_factory.gd")
var _sun: DirectionalLight3D
var _env_ref: Environment
var _sky_mat: ProceduralSkyMaterial
var _fog_day: float = 0.0058

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

# --------------------------------------------------------------- modelos ----
func _env(path: String, pos: Vector3, rot_y: float = 0.0, scale_factor: float = 1.0) -> Node3D:
	return _env_mf.spawn_env(root, ENV + path, pos, rot_y, scale_factor)

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

func _collider_box(size: Vector3, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation.y = rot_y
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	col.shape = cs
	body.add_child(col)
	root.add_child(body)
	return body

func _collider_cyl(r: float, height: float, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = r
	cs.height = height
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
	root.add_child(sun)
	_sun = sun
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
	_env_ref = env
	_sky_mat = sky_mat
	_fog_day = 0.0058

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

func _flora(file: String, pos: Vector3, rot_y: float, scale_factor: float) -> Node3D:
	return _env_mf.spawn_env(root, GOBKIT + file, pos, rot_y, scale_factor, 55.0)

## Vegetação baixa gobkit (CC0): relva ao longo da estrada e da floresta,
## arbustos nos remates das construções e escarpas a enquadrar o fundo.
## Apenas visual — sem colisores (porte baixo, fora do percurso do jogador).
func _build_flora() -> void:
	rng.seed = SEED + 97
	var grasses := ["Grass001.glb", "Grass002.glb", "Grass003.glb"]
	# Relva ao longo da estrada (ambos os lados)
	for i in range(26):
		var z := rng.randf_range(2.0, 33.5)
		var side := 1.0 if rng.randf() > 0.5 else -1.0
		var x := 1.2 + side * rng.randf_range(2.6, 4.3) + rng.randf_range(-0.6, 0.6)
		_flora(grasses[rng.randi() % grasses.size()], Vector3(x, 0, z), rng.randf_range(0.0, TAU), rng.randf_range(0.8, 1.4))
	# Relva na floresta (evita estrada e clareira da emboscada)
	for i in range(42):
		var x := rng.randf_range(-29.0, 29.0)
		var z := rng.randf_range(-33.0, 0.0)
		if absf(x) < 4.2:
			continue
		_flora(grasses[rng.randi() % grasses.size()], Vector3(x, 0, z), rng.randf_range(0.0, TAU), rng.randf_range(0.9, 1.5))
	# Relva no acesso à Academia
	for i in range(14):
		var z := rng.randf_range(-53.0, -36.0)
		var side := 1.0 if rng.randf() > 0.5 else -1.0
		var x := -1.0 + side * rng.randf_range(2.7, 5.0)
		_flora(grasses[rng.randi() % grasses.size()], Vector3(x, 0, z), rng.randf_range(0.0, TAU), rng.randf_range(0.8, 1.3))
	# Arbustos como remate visual das construções e do acampamento
	var bushes := [
		Vector3(-8.4, 0, 27.0), Vector3(8.6, 0, 34.0), Vector3(-13.8, 0, 27.2),
		Vector3(14.9, 0, 38.6), Vector3(-9.4, 0, -12.2), Vector3(5.4, 0, -52.2),
		Vector3(11.8, 0, 30.5), Vector3(-14.5, 0, 37.3), Vector3(2.5, 0, 40.5),
		Vector3(-6.5, 0, 17.0), Vector3(6.8, 0, 12.0), Vector3(-2.8, 0, -8.0),
		Vector3(12.5, 0, -6.5), Vector3(-13.2, 0, -33.0),
	]
	# Marcos de pedra ao longo da estrada (contagem de milhas do Vale)
	for p in [Vector3(3.4, 0, 26.0), Vector3(-3.2, 0, 16.0), Vector3(4.6, 0, 6.0),
			Vector3(-3.4, 0, -4.0), Vector3(3.0, 0, -14.0), Vector3(-3.8, 0, -24.0),
			Vector3(4.4, 0, -34.0), Vector3(-2.4, 0, -45.0)]:
		_mk.milestone(p)
	for p in bushes:
		var bush := "Bush001.glb" if rng.randf() > 0.5 else "Bush002.glb"
		_flora(bush, p, rng.randf_range(0.0, TAU), rng.randf_range(1.0, 1.5))
	# Escarpas a enquadrar o portão da Academia e a margem da floresta
	_flora("Cliff001.glb", Vector3(-23.0, 0, -56.5), 0.4, 2.7)
	_flora("Cliff002.glb", Vector3(23.4, 0, -55.5), 2.2, 2.5)
	_flora("Cliff003.glb", Vector3(-26.0, 0, -18.0), 1.1, 3.0)

# ----------------------------------------------------------------- vila -----
func _build_village() -> void:
	rng.seed = SEED
	var timber := _mat(Color(0.38, 0.26, 0.16), 0.0, 0.85)

	# Casas KayKit em volta da praça (colisor invisível, modelo visível)
	var houses := [
		{"model": "buildings/red/building_home_A_red.gltf", "pos": Vector3(-7.5, 0, 25.5), "rot": 0.5, "col": Vector3(3.4, 2.6, 2.9), "scale": 0.62},
		{"model": "buildings/yellow/building_home_B_yellow.gltf", "pos": Vector3(7.0, 0, 24.8), "rot": -0.4, "col": Vector3(3.1, 2.5, 2.7), "scale": 0.62},
		{"model": "buildings/green/building_home_A_green.gltf", "pos": Vector3(-10.5, 0, 34.0), "rot": 1.35, "col": Vector3(3.6, 2.6, 3.0), "scale": 0.62},
		{"model": "buildings/blue/building_home_B_blue.gltf", "pos": Vector3(10.0, 0, 33.5), "rot": -1.3, "col": Vector3(3.2, 2.5, 2.7), "scale": 0.62},
		{"model": "buildings/yellow/building_home_A_yellow.gltf", "pos": Vector3(-5.5, 0, 39.5), "rot": 2.9, "col": Vector3(3.8, 2.7, 3.2), "scale": 0.62},  # casa da mãe
		{"model": "buildings/red/building_home_A_red.gltf", "pos": Vector3(5.5, 0, 39.0), "rot": -2.8, "col": Vector3(3.1, 2.4, 2.6), "scale": 0.6},
		{"model": "buildings/red/building_home_B_red.gltf", "pos": Vector3(13.0, 0, 28.5), "rot": -1.05, "col": Vector3(2.8, 2.5, 2.5), "scale": 0.6},
	]
	for h in houses:
		var col: Vector3 = h["col"]
		var pos: Vector3 = h["pos"]
		_collider_box(col, pos + Vector3(0, col.y * 0.5, 0), h["rot"])
		_env(h["model"], pos, h["rot"], h["scale"])

	# Taverna a nascente da praça
	var tavern_pos := Vector3(12.5, 0, 37.0)
	_collider_box(Vector3(4.1, 2.8, 3.3), tavern_pos + Vector3(0, 1.4, 0), -2.2)
	_env("buildings/red/building_tavern_red.gltf", tavern_pos, -2.2, 0.62)

	# Capela no caminho (santuário)
	var church_pos := Vector3(-8.5, 0, 8.0)
	_collider_box(Vector3(4.6, 3.6, 3.8), church_pos + Vector3(0, 1.8, 0), 0.18)
	_env("buildings/yellow/building_church_yellow.gltf", church_pos, 0.18, 0.66)

	# Forja do Garr (poente)
	var forge_pos := Vector3(-11.5, 0, 24.5)
	_collider_box(Vector3(3.6, 2.5, 3.0), forge_pos + Vector3(0, 1.25, 0), 0.35)
	_env("buildings/red/building_blacksmith_red.gltf", forge_pos, 0.35, 0.62)
	_visual_cyl(0.32, 0.34, 0.18, forge_pos + Vector3(-0.6, 0.28, 1.35), _mat(Color(0.18, 0.18, 0.2), 0.6, 0.4))  # bigorna
	_visual_box(Vector3(0.6, 0.18, 0.6), forge_pos + Vector3(-0.6, 0.11, 1.35), timber)
	_visual_box(Vector3(0.9, 0.12, 0.9), forge_pos + Vector3(0.4, 0.35, 1.3), _mat(Color(1.0, 0.45, 0.1), 0.0, 0.6, Color(1.0, 0.4, 0.05), 2.6))  # brasas
	var fire_light := OmniLight3D.new()
	fire_light.position = forge_pos + Vector3(0.4, 1.1, 1.3)
	fire_light.light_color = Color(1.0, 0.55, 0.2)
	fire_light.light_energy = 2.2
	fire_light.omni_range = 6.5
	root.add_child(fire_light)
	# Roda de carro, caixa e sacos junto à forja
	_env("decoration/props/wheelbarrow.gltf", forge_pos + Vector3(2.4, 0, 1.2), 1.1, 0.9)
	_env("decoration/props/pallet.gltf", forge_pos + Vector3(2.1, 0, -0.8), 0.4, 0.9)
	_env("decoration/props/barrel.gltf", forge_pos + Vector3(-2.0, 0, 0.7), 0.0, 0.9)
	_env("decoration/props/barrel.gltf", forge_pos + Vector3(-2.4, 0, -0.5), 0.7, 0.75)
	_env("decoration/props/ladder.gltf", forge_pos + Vector3(-1.3, 0, -1.9), 2.1, 0.9)

	# Poço no centro da praça
	_collider_cyl(1.0, 0.9, Vector3(0, 0.45, 31))
	_env("buildings/yellow/building_well_yellow.gltf", Vector3(0, 0, 31), 0.0, 0.5)

	# Banca de mercado com mercadorias
	var stall := Vector3(5.6, 0, 29.6)
	_collider_box(Vector3(2.3, 1.7, 1.8), stall + Vector3(0, 0.85, 0), 0.0)
	_env("buildings/yellow/building_market_yellow.gltf", stall, 0.0, 0.62)
	_env("decoration/props/crate_A_big.gltf", stall + Vector3(1.9, 0, 0.9), 0.4, 0.9)
	_env("decoration/props/crate_open.gltf", stall + Vector3(-1.4, 0, 0.7), 1.3, 0.9)
	_env("decoration/props/sack.gltf", stall + Vector3(1.3, 0, -1.2), 0.0, 0.9)
	_env("decoration/props/pallet.gltf", stall + Vector3(-1.6, 0, -1.4), 0.9, 0.85)

	# Postes de luz na praça
	for p in [Vector3(-4.5, 0, 27.5), Vector3(4.5, 0, 34.5), Vector3(-4.5, 0, 34.5), Vector3(4.5, 0, 27.5)]:
		_visual_cyl(0.09, 0.11, 2.6, p + Vector3(0, 1.3, 0), timber)
		_visual_cyl(0.16, 0.22, 0.24, p + Vector3(0, 2.7, 0), _mat(Color(0.9, 0.75, 0.3), 0.0, 0.5, Color(0.9, 0.7, 0.25), 1.8))

	# Cercas de madeira ao longo da estrada
	for i in range(6):
		var z := 12.0 - i * 3.5
		var x := 3.1 if i % 2 == 0 else -3.3
		var rot := 0.15 * (1 if i % 2 == 0 else -1)
		_env("buildings/neutral/fence_wood_straight.gltf", Vector3(x, 0, z), rot + PI * 0.5, 0.85)


	# Corda de roupa entre as casas da praça (norte)
	var line_from := Vector3(-5.5, 3.0, 39.4)
	var line_to := Vector3(5.0, 2.95, 39.0)
	var ldir := line_to - line_from
	var line := _visual_box(Vector3(0.05, 0.05, ldir.length()), (line_from + line_to) * 0.5, _mat(Color(0.15, 0.12, 0.1), 0.0, 0.9))
	line.rotation.y = atan2(ldir.x, ldir.z)
	var cloth_cols := [Color(0.92, 0.9, 0.86), Color(0.72, 0.3, 0.26), Color(0.85, 0.68, 0.32), Color(0.36, 0.48, 0.66)]
	for i in range(4):
		var t := (float(i) + 0.75) / 4.75
		var p := line_from.lerp(line_to, t) + Vector3(0.0, -0.34 - 0.12 * sin(t * PI), 0.0)
		var cloth := _visual_box(Vector3(0.44, 0.66, 0.05), p, _mat(cloth_cols[i], 0.0, 0.85))
		cloth.rotation.y = atan2(ldir.x, ldir.z)
	# Placa da taverna (âmbar, visível da praça)
	_visual_cyl(0.07, 0.09, 2.6, Vector3(9.0, 1.3, 34.0), timber)
	_visual_box(Vector3(0.8, 0.6, 0.1), Vector3(9.0, 2.32, 34.0), _mat(Color(0.5, 0.3, 0.16), 0.0, 0.8))
	_visual_box(Vector3(0.03, 0.3, 0.5), Vector3(8.93, 2.34, 34.0), _mat(Color(0.9, 0.6, 0.2), 0.0, 0.6, Color(1.0, 0.65, 0.22), 1.5))
	# Festões da festa do mercado entre os postes da praça (sul)
	_mk.pennant_string(Vector3(-4.5, 3.2, 27.5), Vector3(4.5, 3.2, 27.5), [Color(0.85, 0.28, 0.24), Color(0.9, 0.72, 0.3), Color(0.36, 0.5, 0.68), Color(0.92, 0.9, 0.86)])
	# Alvos de treino junto ao portão norte e à forja
	_env("decoration/props/target.gltf", Vector3(-6.3, 0, -50.0), 0.5, 1.0)
	_env("decoration/props/target.gltf", Vector3(6.3, 0, -50.0), -0.4, 1.0)
	_env("decoration/props/target.gltf", Vector3(7.8, 0, -45.5), -0.9, 1.0)

# -------------------------------------------------------------- floresta ----
func _build_forest() -> void:
	rng.seed = SEED + 7
	var tree_models := [
		"decoration/nature/tree_single_A.gltf",
		"decoration/nature/tree_single_B.gltf",
		"decoration/nature/trees_A_medium.gltf",
		"decoration/nature/trees_B_medium.gltf",
	]
	# Saplings sob a copa (sem colisão — porte felino)
	for i in range(38):
		var sx := rng.randf_range(-29.0, 29.0)
		var sz := rng.randf_range(-33.0, 0.0)
		if absf(sx) < 3.6 or (absf(sx) < 4.5 and sz > -18.0 and sz < -8.0):
			continue
		var sap := "decoration/nature/tree_single_A.gltf" if rng.randf() > 0.5 else "decoration/nature/tree_single_B.gltf"
		_env(sap, Vector3(sx, 0, sz), rng.randf_range(0.0, TAU), rng.randf_range(0.5, 0.75))
	var tree_positions: Array[Vector3] = []
	for i in range(96):
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
		var s := rng.randf_range(0.85, 1.45)
		var model: String = tree_models[rng.randi_range(0, tree_models.size() - 1)]
		_collider_cyl(0.32, 1.6, p + Vector3(0, 0.8, 0))
		_env(model, p, rng.randf_range(0.0, TAU), s)
	# Rochas KayKit
	var rock_models := ["decoration/nature/rock_single_A.gltf", "decoration/nature/rock_single_C.gltf"]
	for i in range(22):
		var x := rng.randf_range(-28.0, 28.0)
		var z := rng.randf_range(-33.0, 2.0)
		if absf(x) < 3.8:
			continue
		var s := rng.randf_range(0.6, 1.5)
		_collider_box(Vector3(s, s * 0.7, s * 0.8), Vector3(x, s * 0.3, z), rng.randf_range(0, PI))
		_env(rock_models[rng.randi_range(0, 1)], Vector3(x, 0, z), rng.randf_range(0, TAU), s)

# --------------------------------------------------- academia e arena -------
func _build_academy_and_arena() -> void:
	var stone := _mat(Color(0.78, 0.79, 0.82), 0.05, 0.7)
	var stone_dark := _mat(Color(0.52, 0.53, 0.58), 0.05, 0.75)

	# Muralha com portão (colisores invisíveis — visual nos modelos KayKit)
	_collider_box(Vector3(17.0, 5.2, 1.6), Vector3(-13.3, 2.6, -55.5))
	_collider_box(Vector3(17.0, 5.2, 1.6), Vector3(13.3, 2.6, -55.5))
	_collider_box(Vector3(5.2, 1.7, 1.6), Vector3(0, 4.35, -55.5))  # verga do portão
	_env("buildings/neutral/wall_straight.gltf", Vector3(-13.3, 0, -55.5), 0.0, 2.8)
	_env("buildings/neutral/wall_straight.gltf", Vector3(13.3, 0, -55.5), 0.0, 2.8)
	_env("buildings/neutral/wall_straight_gate.gltf", Vector3(0, 0, -55.4), 0.0, 2.6)
	# Torres gémeas de entrada
	_collider_cyl(1.6, 8.6, Vector3(-6.4, 4.3, -55.8))
	_collider_cyl(1.6, 8.6, Vector3(6.4, 4.3, -55.8))
	_env("buildings/yellow/building_tower_A_yellow.gltf", Vector3(-6.4, 0, -55.8), 0.0, 1.2)
	_env("buildings/yellow/building_tower_A_yellow.gltf", Vector3(6.4, 0, -55.8), 0.0, 1.2)
	# Bandeiras aos lados do portão
	for sx in [-1, 1]:
		_visual_cyl(0.07, 0.07, 3.6, Vector3(sx * 3.4, 1.8, -54.3), _mat(Color(0.35, 0.3, 0.2), 0.4, 0.5))
		_env("decoration/props/flag_yellow.gltf", Vector3(sx * 3.4, 3.5, -54.3), 0.0, 0.9)
	# A grande Academia ao fundo (colisor sólido)
	_collider_box(Vector3(21.0, 9.0, 7.0), Vector3(0, 4.5, -67.0))
	_env("buildings/yellow/building_castle_yellow.gltf", Vector3(0, 0, -68.0), 0.0, 1.55)
	# Portão fechado (visual) — grades
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
	# Suporte de armas e alvos de treino à entrada da arena
	_env("decoration/props/weaponrack.gltf", Vector3(arena_center.x - 5.6, 0, arena_center.z + 6.4), 2.6, 1.0)
	_env("decoration/props/target.gltf", Vector3(arena_center.x + 4.6, 0, arena_center.z + 6.8), PI + 0.35, 1.0)
	_env("decoration/props/target.gltf", Vector3(arena_center.x + 6.3, 0, arena_center.z + 5.4), PI - 0.5, 1.0)

	# Tenda de caçadores junto à clareira da emboscada
	_env("decoration/props/tent.gltf", Vector3(-7.5, 0, -13.5), 0.9, 1.15)

# ------------------------------------------------------------- montanhas ----
func _build_mountains() -> void:
	rng.seed = SEED + 31
	var mountain_models := [
		"decoration/nature/mountain_A.gltf",
		"decoration/nature/mountain_B.gltf",
		"decoration/nature/mountain_C.gltf",
	]
	for i in range(11):
		var angle := -PI / 2.0 + (float(i) - 5.0) * 0.62
		var dist := rng.randf_range(78.0, 96.0)
		var x := cos(angle) * dist
		var z := -10.0 + sin(angle) * dist
		var s := rng.randf_range(4.5, 7.0)
		var model: String = mountain_models[rng.randi_range(0, mountain_models.size() - 1)]
		_env(model, Vector3(x, 0, z), rng.randf_range(0.0, TAU), s)


# ------------------------------------------------------- marcos v1.0 -------
func _build_landmarks() -> void:
	## POIs originais: o mundo não é só cenário — conta história.
	# Acampamento de caçadores abandonado (extremo oeste da floresta)
	_mk.tent_camp(Vector3(-17.5, 0.0, -26.0), true)
	# Ruínas de engenharia engolidas pela mata (leste)
	_mk.engineer_ruins(Vector3(15.5, 0.0, -24.0))
	# Posto de observação colapsado, meio da mata norte
	_mk.post(Vector3(6.2, 0.0, -38.0), 1.5)


# -------------------------------------------------------- ambiente v1.1 ----
func _build_ambience() -> void:
	var amb = preload("res://src/world/ambience.gd").new()
	amb.name = "Ambience"
	root.add_child(amb)
	amb.add_emitter("leaves", Vector3(0.0, 8.5, -17.0), Vector3(15.0, 3.0, 15.0), 30)
	amb.add_emitter("embers", Vector3(-11.1, 1.8, 25.8), Vector3(1.2, 1.0, 1.2), 16)
	amb.add_emitter("embers", Vector3(12.5, 3.4, 37.0), Vector3(0.9, 0.8, 0.9), 10)
	amb.add_flock(Vector3(2.0, 20.5, 31.0), 12.0, 0.45)
	_mk.light_shaft(Vector3(3.0, 9.0, -12.0), 13.0, 2.2)
	_mk.light_shaft(Vector3(-5.0, 10.0, -21.0), 15.0, 2.6)
	# Lagoa dos patos: água baixa + caniço + nenúfares + doca
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.09, 0.24, 0.31, 0.9)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water.emission_enabled = true
	water.emission = Color(0.05, 0.13, 0.17)
	water.emission_energy_multiplier = 0.8
	var pond_mesh := CylinderMesh.new()
	pond_mesh.top_radius = 3.4
	pond_mesh.bottom_radius = 3.4
	pond_mesh.height = 0.07
	var pond := MeshInstance3D.new()
	pond.mesh = pond_mesh
	pond.material_override = water
	pond.position = Vector3(17.0, 0.055, 17.0)
	root.add_child(pond)
	for i in range(7):
		var ang := TAU * float(i) / 7.0 + 0.4
		_flora("Grass002.glb", Vector3(cos(ang) * 3.8 + 17.0, 0.0, sin(ang) * 3.8 + 17.0), randf() * TAU, 1.5)
	for i in range(3):
		var lily_mesh := CylinderMesh.new()
		lily_mesh.top_radius = 0.3 - float(i) * 0.07
		lily_mesh.bottom_radius = 0.3 - float(i) * 0.07
		lily_mesh.height = 0.025
		var lily := MeshInstance3D.new()
		lily.mesh = lily_mesh
		lily.material_override = _mat(Color(0.23, 0.46, 0.2), 0.0, 0.8)
		lily.position = Vector3(15.9 + float(i) * 1.25, 0.11, 16.4 + float(i % 2) * 1.15)
		root.add_child(lily)
	_mk.dock(Vector3(17.0, 0.0, 13.4))

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
		var npc = npc_scene.instantiate()
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
		var pickup = pickup_scene.instantiate()
		pickup.position = Vector3(x, 0.55, z)
		root.add_child(pickup)
		placed += 1

## Nós de mundo persistentes: o ciclo dia/noite e os ecos da noite na
## floresta (inimigos só à noite, em área delimitada).
func _spawn_night() -> void:
	var dn: Node3D = Node3D.new()
	dn.set_script(load("res://src/world/day_night.gd"))
	root.add_child(dn)
	dn.set("sun", _sun)
	dn.set("env", _env_ref)
	dn.set("sky_mat", _sky_mat)
	dn.set("fog_day", _fog_day)
	var ns: Node3D = Node3D.new()
	ns.set_script(load("res://src/world/night_spawns.gd"))
	root.add_child(ns)

func _spawn_enemies() -> void:
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var wolves := [Vector3(-7.0, 0.2, -13.0), Vector3(8.5, 0.2, -21.0), Vector3(3.5, 0.2, -5.0)]
	for pos in wolves:
		var wolf = enemy_scene.instantiate()
		wolf.set("enemy_type", "wolf")
		wolf.position = pos
		root.add_child(wolf)
