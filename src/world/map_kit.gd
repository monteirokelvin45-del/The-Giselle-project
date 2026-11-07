extends RefCounted
## Compõe os mapas em alta densidade (v1.0): anéis de montanha/rochas,
## vegetação alta+baixa, POIs originais (acampamentos, ruínas, torres,
## obeliscos, farol, altar) — tudo com o kit CC0 do repositório + primitivas
## nativas. Partilhado por Vale, expedições e Academia. Densidade-alvo:
## 250–400 nós por mapa (aceite pelo dono para máximo; ver docs/WORLD.md).

const ENV := "res://assets/models/env/"
const GOBKIT := "res://assets/models/nature/"

var root: Node3D
var rng: RandomNumberGenerator
var _env_mf := preload("res://src/visuals/model_factory.gd")

func _init(p_root: Node3D, seed_value: int) -> void:
	root = p_root
	rng = RandomNumberGenerator.new()
	rng.seed = seed_value

# ------------------------------------------------------------- helpers -----
func mat(color: Color, metallic: float = 0.0, roughness: float = 0.9, emissive: Color = Color.BLACK, energy: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emissive != Color.BLACK:
		m.emission_enabled = true
		m.emission = emissive
		m.emission_energy_multiplier = energy
	return m

func env(path: String, pos: Vector3, rot_y: float = 0.0, scale_factor: float = 1.0, far_cull: float = 0.0) -> Node3D:
	return _env_mf.spawn_env(root, ENV + path, pos, rot_y, scale_factor, far_cull)

func flora(file: String, pos: Vector3, rot_y: float, scale_factor: float, far_cull: float = 55.0) -> Node3D:
	return _env_mf.spawn_env(root, GOBKIT + file, pos, rot_y, scale_factor, far_cull)

func collider_box(size: Vector3, pos: Vector3, rot_y: float = 0.0) -> StaticBody3D:
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

func collider_cyl(radius: float, height: float, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = radius
	cs.height = height
	body.add_child(col)
	root.add_child(body)
	return body

func visual_box(size: Vector3, pos: Vector3, material: StandardMaterial3D, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = material
	mi.position = pos
	mi.rotation.y = rot_y
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	return mi

func visual_cyl(r_top: float, r_bottom: float, height: float, pos: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = height
	mi.mesh = cm
	mi.material_override = material
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(mi)
	return mi

func fire_light(pos: Vector3, color: Color = Color(1.0, 0.55, 0.2), power: float = 2.2, range_m: float = 7.0) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = power
	light.omni_range = range_m
	root.add_child(light)

# ------------------------------------------------------ anéis e bordas ----
## Anel de picos/rochas no horizonte (grupo: encobre a aresta do chão e
## enquadra o mapa). y = posição no chão.
func mountain_ring(radius_min: float, radius_max: float, count: int, models: Array[String], disc_z: float, scale_min: float, scale_max: float, seed_offset: int = 0) -> void:
	rng.seed = 991 + seed_offset
	for i in range(count):
		var angle := TAU * float(i) / float(count) + rng.randf_range(-0.14, 0.14)
		var dist := rng.randf_range(radius_min, radius_max)
		var pos := Vector3(cos(angle) * dist, 0.0, disc_z + sin(angle) * dist)
		var model: String = models[rng.randi_range(0, models.size() - 1)]
		env(model, pos, rng.randf_range(0.0, TAU), rng.randf_range(scale_min, scale_max))

## Pedras salpicadas respeitando um raio de exclusão (zona do jogador).
func rock_scatter(count: int, area_min: float, area_max: float, avoid: Vector3, avoid_radius: float, models: Array[String], scale_min: float, scale_max: float, seed_offset: int) -> void:
	rng.seed = 3141 + seed_offset
	for i in range(count):
		var pos := _ring_pos(area_min, area_max)
		if pos.distance_to(avoid) < avoid_radius:
			continue
		var s := rng.randf_range(scale_min, scale_max)
		var model: String = models[rng.randi_range(0, models.size() - 1)]
		collider_box(Vector3(s, s * 0.72, s * 0.82), Vector3(pos.x, s * 0.3, pos.z), rng.randf_range(0.0, PI))
		env(model, pos, rng.randf_range(0.0, TAU), s)

## Vegetação baixa: relva + arbustos. Sem colisores (porte baixo).
func flora_scatter(grass_count: int, bush_count: int, area_min: float, area_max: float, avoid: Vector3, avoid_radius: float, seed_offset: int) -> void:
	rng.seed = 271 + seed_offset
	var grasses := ["Grass001.glb", "Grass002.glb", "Grass003.glb"]
	for i in range(grass_count):
		var pos := _ring_pos(area_min, area_max)
		if pos.distance_to(avoid) < avoid_radius:
			continue
		flora(grasses[rng.randi_range(0, grasses.size() - 1)], pos, rng.randf_range(0.0, TAU), rng.randf_range(0.8, 1.5))
	for i in range(bush_count):
		var pos := _ring_pos(area_min, area_max)
		if pos.distance_to(avoid) < avoid_radius:
			continue
		var bush := "Bush001.glb" if rng.randf() > 0.5 else "Bush002.glb"
		flora(bush, pos, rng.randf_range(0.0, TAU), rng.randf_range(1.0, 1.6))

func tree_scatter(count: int, area_min: float, area_max: float, avoid: Vector3, avoid_radius: float, models: Array[String], scale_min: float, scale_max: float, seed_offset: int) -> void:
	rng.seed = 1618 + seed_offset
	for i in range(count):
		var pos := _ring_pos(area_min, area_max)
		if pos.distance_to(avoid) < avoid_radius:
			continue
		var s := rng.randf_range(scale_min, scale_max)
		var model: String = models[rng.randi_range(0, models.size() - 1)]
		collider_cyl(0.32 * s, 1.6 * s, pos + Vector3(0, 0.8 * s, 0))
		env(model, pos, rng.randf_range(0.0, TAU), s)

func _ring_pos(r_min: float, r_max: float) -> Vector3:
	var angle := rng.randf_range(0.0, TAU)
	var dist := sqrt(rng.randf_range(r_min * r_min, r_max * r_max))
	return Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)

## Passagem dupla (camada a camada): primeiro a vegetação baixa,
## depois as árvores — o ring_pos mantém a exclusão central.
func double_canopy(tree_count: int, sapling_count: int, area_min: float, area_max: float, avoid: Vector3, avoid_radius: float, seed_offset: int) -> void:
	# copa alta
	for i in range(sapling_count):
		var models: Array[String] = ["decoration/nature/tree_single_A.gltf", "decoration/nature/tree_single_B.gltf"]
		var pos := _ring_pos(area_min, area_max * 0.9)
		if pos.distance_to(avoid) < avoid_radius:
			continue
		var s := rng.randf_range(0.55, 0.8)
		var model: String = models[rng.randi_range(0, models.size() - 1)]
		env(model, pos, rng.randf_range(0.0, TAU), s)
	tree_scatter(tree_count, area_min, area_max, avoid, avoid_radius,
		["decoration/nature/tree_single_A.gltf", "decoration/nature/tree_single_B.gltf",
		 "decoration/nature/trees_A_medium.gltf", "decoration/nature/trees_B_medium.gltf"],
		0.9, 2.3, seed_offset)

# ---------------------------------------------------------- POIs -----------
## Ruínas de engenheiro: arco partido + parede meia-partida + obelisco.
func engineer_ruins(pos: Vector3) -> void:
	var stone := mat(Color(0.62, 0.6, 0.56), 0.05, 0.8)
	var dark := mat(Color(0.3, 0.3, 0.32), 0.1, 0.7)
	# Arco (dois postes + verga torta)
	visual_box(Vector3(1.2, 5.2, 1.2), pos + Vector3(-2.6, 2.6, 0.0), stone)
	visual_box(Vector3(1.2, 4.0, 1.2), pos + Vector3(2.6, 2.0, 0.0), stone)
	visual_box(Vector3(6.6, 1.0, 1.4), pos + Vector3(0.0, 4.6, 0.0) + Vector3(0.0, 0.0, 0.0), stone).rotation.z = 0.06
	collider_box(Vector3(1.3, 5.3, 1.3), pos + Vector3(-2.6, 2.65, 0.0))
	collider_box(Vector3(1.3, 4.1, 1.3), pos + Vector3(2.6, 2.05, 0.0))
	# Anel de lajes no chão (sem colisão)
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		visual_cyl(0.55, 0.62, 0.16, pos + Vector3(cos(angle) * 3.4, 0.08, sin(angle) * 3.4), dark)

## Obelisco com runa incandescente (centro visual do mapa).
func obelisk(pos: Vector3, height: float, glow: Color) -> void:
	var dark := mat(Color(0.16, 0.13, 0.24), 0.2, 0.6)
	var rune := mat(Color(0.05, 0.05, 0.08), 0.0, 0.9, glow, 3.2)
	visual_box(Vector3(2.6, 0.7, 2.6), pos + Vector3(0.0, 0.35, 0.0), dark)
	visual_box(Vector3(1.5, height, 1.5), pos + Vector3(0.0, 0.7 + height * 0.5, 0.0), dark)
	visual_box(Vector3(1.9, 0.9, 1.9), pos + Vector3(0.0, 0.7 + height + 0.45, 0.0), dark)
	visual_box(Vector3(0.34, height * 0.55, 0.1), pos + Vector3(0.0, 0.9 + height * 0.5, 0.79), rune)
	collider_box(Vector3(2.2, 0.8, 2.2), pos + Vector3(0.0, 0.4, 0.0))
	collider_box(Vector3(1.6, height, 1.6), pos + Vector3(0.0, 0.7 + height * 0.5, 0.0))

## Acampamento de caçadores/salteadores: tenda + fogueira + armação.
func tent_camp(center: Vector3, flip: bool = false) -> void:
	env("decoration/props/tent.gltf", center + Vector3(0.0, 0.0, 2.2 if flip else -2.2), 0.4 if flip else PI - 0.4, 1.25)
	visual_cyl(0.34, 0.4, 0.22, center + Vector3(1.9, 0.24, 0.8), mat(Color(0.14, 0.12, 0.1), 0.5, 0.5))
	visual_box(Vector3(0.9, 0.12, 0.9), center + Vector3(1.9, 0.09, 0.8), mat(Color(0.3, 0.24, 0.18), 0.0, 0.9))
	visual_box(Vector3(0.92, 0.14, 0.92), center + Vector3(1.9, 0.42, 0.8), mat(Color(1.0, 0.42, 0.08), 0.0, 0.6, Color(1.0, 0.4, 0.06), 2.4))
	fire_light(center + Vector3(1.9, 1.15, 0.8))
	env("decoration/props/weaponrack.gltf", center + Vector3(-2.3, 0.0, 1.4), 1.2, 1.0)
	env("decoration/props/crate_A_big.gltf", center + Vector3(-1.4, 0.0, -1.6), 0.6, 0.9)
	env("decoration/props/barrel.gltf", center + Vector3(2.6, 0.0, -1.3), 0.2, 0.85)
	env("decoration/props/sack.gltf", center + Vector3(0.4, 0.0, 2.6), 0.9, 0.9)
	collider_box(Vector3(1.6, 1.0, 1.6), center + Vector3(0.0, 0.5, (2.2 if flip else -2.2)))

## Torre de vigia partida: 4 paredes meia-partida + plataforma.
func watchtower(pos: Vector3) -> void:
	var stone := mat(Color(0.52, 0.53, 0.57), 0.05, 0.8)
	var wood := mat(Color(0.36, 0.25, 0.15), 0.0, 0.85)
	visual_box(Vector3(0.9, 5.6, 0.9), pos + Vector3(-1.9, 2.8, -1.9), stone)
	visual_box(Vector3(0.9, 3.8, 0.9), pos + Vector3(1.9, 1.9, -1.9), stone)
	visual_box(Vector3(0.9, 4.8, 0.9), pos + Vector3(-1.9, 2.4, 1.9), stone)
	visual_box(Vector3(0.9, 2.6, 0.9), pos + Vector3(1.9, 1.3, 1.9), stone)
	visual_box(Vector3(4.6, 0.35, 4.6), pos + Vector3(0.0, 5.75, 0.0), wood)
	for corner in [Vector3(-1.9, 0.0, -1.9), Vector3(1.9, 0.0, -1.9), Vector3(-1.9, 0.0, 1.9), Vector3(1.9, 0.0, 1.9)]:
		collider_box(Vector3(1.0, 6.0, 1.0), pos + corner + Vector3(0.0, 3.0, 0.0))
	env("decoration/props/weaponrack.gltf", pos + Vector3(3.4, 0.0, 0.6), 2.4, 1.0)
	env("decoration/props/crate_open.gltf", pos + Vector3(-3.2, 0.0, 1.4), 1.1, 0.9)

## Farol de atoll: torre clara + cúpula incandescente + feixe de luz azul.
func lighthouse(pos: Vector3) -> void:
	var shell := mat(Color(0.88, 0.86, 0.8), 0.05, 0.6)
	var stripe := mat(Color(0.55, 0.18, 0.14), 0.05, 0.7)
	visual_cyl(1.7, 2.1, 1.6, pos + Vector3(0.0, 0.8, 0.0), shell)
	visual_cyl(1.25, 1.45, 5.4, pos + Vector3(0.0, 4.1, 0.0), shell)
	visual_cyl(1.32, 1.32, 1.15, pos + Vector3(0.0, 3.3, 0.0), stripe)
	visual_cyl(0.95, 1.0, 1.5, pos + Vector3(0.0, 7.4, 0.0), stripe)
	visual_cyl(0.5, 0.62, 0.8, pos + Vector3(0.0, 8.4, 0.0), mat(Color(0.05, 0.07, 0.1), 0.0, 0.9, Color(0.45, 0.85, 1.0), 4.0))
	var beam := OmniLight3D.new()
	beam.position = pos + Vector3(0.0, 8.4, 0.0)
	beam.light_color = Color(0.5, 0.88, 1.0)
	beam.light_energy = 2.6
	beam.omni_range = 22.0
	root.add_child(beam)
	# Feixe visível a varrer o horizonte (lâmina aditiva, rotação lenta)
	var spinner := Node3D.new()
	spinner.position = pos + Vector3(0.0, 8.4, 0.0)
	root.add_child(spinner)
	var blade := MeshInstance3D.new()
	var bbm := BoxMesh.new()
	bbm.size = Vector3(11.0, 0.4, 0.62)
	blade.mesh = bbm
	blade.position = Vector3(5.5, 0.0, 0.0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.72, 0.94, 1.0, 0.32)
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.disable_receive_shadows = true
	bmat.emission_enabled = true
	bmat.emission = Color(0.6, 0.9, 1.0)
	bmat.emission_energy_multiplier = 1.7
	blade.material_override = bmat
	blade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	spinner.add_child(blade)
	preload("res://src/world/ambience.gd").spinner(spinner, 0.55)
	collider_cyl(1.9, 7.2, pos + Vector3(0.0, 3.6, 0.0))

## Altar do Abismo: anel de colunas negras + núcleo de luz ferida.
func abyss_altar(pos: Vector3) -> void:
	var basalt := mat(Color(0.09, 0.07, 0.16), 0.25, 0.55)
	var core := mat(Color(0.03, 0.02, 0.05), 0.0, 0.95, Color(0.62, 0.25, 1.0), 3.6)
	collider_cyl(2.6, 0.9, pos + Vector3(0.0, 0.45, 0.0))
	visual_cyl(2.6, 2.9, 0.9, pos + Vector3(0.0, 0.45, 0.0), basalt)
	visual_cyl(1.15, 1.7, 0.55, pos + Vector3(0.0, 1.16, 0.0), core)
	for i in range(7):
		var angle := TAU * float(i) / 7.0
		var p := pos + Vector3(cos(angle) * 5.2, 0.0, sin(angle) * 5.2)
		var h := 2.6 + 1.5 * sin(float(i) * 2.7)
		visual_cyl(0.5, 0.62, h, p + Vector3(0.0, h * 0.5, 0.0), basalt)
		collider_cyl(0.6, h, p + Vector3(0.0, h * 0.5, 0.0))

## Fenda incandescente no chão (plano vertical curto, luz emitida pelo material).
func crack_glow(pos: Vector3, length: float) -> void:
	var glow := mat(Color(0.02, 0.01, 0.04), 0.0, 0.9, Color(0.75, 0.3, 1.0), 4.5)
	visual_box(Vector3(length, 0.12, 0.42), pos + Vector3(0.0, 0.07, 0.0), glow)
	for i in range(5):
		var offset := (float(i) - 2.0) * length * 0.18
		visual_box(Vector3(0.24, 0.5 + 0.2 * absf(sin(float(i) * 1.7)), 0.24), pos + Vector3(offset, 0.25, 0.1 * sin(float(i) * 3.1)), glow)

## Ilhas flutuantes (reg. Aer): rochas invertidas/pedras suspensas no horizonte.
func floating_islands(count: int, y_min: float, y_max: float, seed_offset: int) -> void:
	rng.seed = 777 + seed_offset
	var models := ["decoration/nature/mountain_A.gltf", "decoration/nature/mountain_B.gltf", "decoration/nature/mountain_C.gltf"]
	for i in range(count):
		var angle := rng.randf_range(0.0, TAU)
		var dist := rng.randf_range(28.0, 78.0)
		var pos := Vector3(cos(angle) * dist, rng.randf_range(y_min, y_max), sin(angle) * dist)
		var island := env(models[rng.randi_range(0, models.size() - 1)], pos, rng.randf_range(0.0, TAU), rng.randf_range(1.2, 2.6))
		if island != null:
			island.rotation.z = PI
			preload("res://src/world/ambience.gd").bobber(island, 0.7, 0.38)

## Arco de pedra do céu quebrado (reg. Aer) — duas rochas colossais inclinadas.
func sky_arch(pos: Vector3) -> void:
	var stone := mat(Color(0.5, 0.48, 0.6), 0.05, 0.75)
	var rock_a := visual_box(Vector3(2.4, 13.0, 2.4), pos + Vector3(-3.4, 5.6, 0.0), stone)
	rock_a.rotation.z = 0.18
	var rock_b := visual_box(Vector3(2.0, 9.5, 2.0), pos + Vector3(3.2, 4.2, 0.0), stone)
	rock_b.rotation.z = -0.15
	collider_box(Vector3(2.5, 13.0, 2.5), pos + Vector3(-3.4, 5.6, 0.0))
	collider_box(Vector3(2.1, 9.5, 2.1), pos + Vector3(3.2, 4.2, 0.0))


## Cais de pescadores (Lume): pranchas + caixas e barril.
func dock(pos: Vector3) -> void:
	var plank := mat(Color(0.42, 0.31, 0.2), 0.0, 0.85)
	for i in range(3):
		visual_box(Vector3(5.6, 0.18, 0.62), pos + Vector3(0.0, 0.32, float(i - 1) * 0.78), plank)
	for i in range(4):
		visual_box(Vector3(0.28, 0.7, 0.28), pos + Vector3(-2.4 + float(i) * 1.6, 0.16, -1.15), mat(Color(0.3, 0.22, 0.14), 0.0, 0.9))
	env("decoration/props/crate_A_big.gltf", pos + Vector3(1.9, 0.0, 1.1), 0.4, 0.9)
	env("decoration/props/crate_open.gltf", pos + Vector3(-1.2, 0.0, 1.2), 1.2, 0.85)
	env("decoration/props/barrel.gltf", pos + Vector3(0.2, 0.0, 1.5), 0.0, 0.8)

## Marcos de proa/passagem (Vale): contador simples de guarda.
func post(pos: Vector3, height: float = 1.1) -> void:
	var wood := mat(Color(0.32, 0.23, 0.14), 0.0, 0.9)
	visual_cyl(0.09, 0.11, height, pos + Vector3(0.0, height * 0.5, 0.0), wood)
	visual_box(Vector3(0.34, 0.14, 0.34), pos + Vector3(0.0, height + 0.07, 0.0), wood)


## Orbe meio-soterrado — engrenagem arcaica avariada (Sahr).
func half_buried_orb(pos: Vector3, radius: float = 1.7) -> void:
	var hull := mat(Color(0.4, 0.36, 0.3), 0.85, 0.32)
	var eye := mat(Color(0.05, 0.06, 0.06), 0.0, 0.9, Color(0.3, 0.95, 0.75), 2.2)
	var orb := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	orb.mesh = sm
	orb.material_override = hull
	orb.position = pos + Vector3(0.0, radius * 0.42, 0.0)
	root.add_child(orb)
	visual_cyl(radius * 0.34, radius * 0.38, radius * 0.7, pos + Vector3(radius * 0.6, radius * 0.3, 0.3), hull)
	visual_box(Vector3(0.5, 0.2, 0.1), pos + Vector3(-radius * 0.5, radius * 0.62, radius * 0.78), eye)
	collider_cyl(radius * 0.75, radius * 1.2, pos + Vector3(0.0, radius * 0.5, 0.0))

## Aglomerado de cristais energizados (Khar, junto ao para-raios).
func crystal_cluster(pos: Vector3) -> void:
	var crystal := mat(Color(0.08, 0.2, 0.28), 0.1, 0.35, Color(0.3, 0.9, 1.0), 1.9)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 987654
	for i in range(5):
		var ang := TAU * float(i) / 5.0 + rng2.randf_range(-0.3, 0.3)
		var h := rng2.randf_range(0.9, 2.1)
		var shard := visual_box(Vector3(0.34, h, 0.34), pos + Vector3(cos(ang) * 0.85, h * 0.4, sin(ang) * 0.85), crystal)
		shard.rotation.z = rng2.randf_range(-0.4, 0.4)
		shard.rotation.x = rng2.randf_range(-0.3, 0.3)
	var glow := OmniLight3D.new()
	glow.position = pos + Vector3(0.0, 1.6, 0.0)
	glow.light_color = Color(0.4, 0.85, 1.0)
	glow.light_energy = 1.5
	glow.omni_range = 9.0
	root.add_child(glow)

## Feixes de luz do dossel (Ruun) — planos aditivos quentes, sem sombra.
func light_shaft(pos: Vector3, height: float = 15.0, width: float = 2.4) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.94, 0.75, 0.10)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_receive_shadows = true
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	for i in range(3):
		var shaft := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(width * (1.0 + float(i) * 0.35), height)
		shaft.mesh = pm
		shaft.material_override = m
		shaft.position = pos + Vector3(float(i - 1) * width * 0.75, height * 0.42, float(i) * 1.6 - 1.4)
		shaft.rotation.x = -0.38
		shaft.rotation.y = 0.35
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(shaft)

## Corda de festões coloridas entre dois posteiros (Vale/Academia).
func pennant_string(a: Vector3, b: Vector3, colors: Array) -> void:
	var delta := b - a
	var length := delta.length()
	var line := visual_box(Vector3(0.05, 0.05, length), (a + b) * 0.5, mat(Color(0.16, 0.12, 0.09), 0.0, 0.9))
	line.rotation.y = atan2(delta.x, delta.z)
	var count := int(length / 2.1)
	for i in range(1, count + 1):
		var t := float(i) / float(count + 1)
		var sag := sin(t * PI) * 0.55
		var p := a.lerp(b, t) - Vector3(0.0, sag, 0.0)
		var col: Color = colors[i % colors.size()]
		var flag_mat := mat(col, 0.0, 0.7)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.0
		cm.bottom_radius = 0.19
		cm.height = 0.42
		var cone := MeshInstance3D.new()
		cone.mesh = cm
		cone.material_override = flag_mat
		cone.position = p - Vector3(0.0, 0.24, 0.0)
		root.add_child(cone)

## Posts de ribeirão/passagem (Vale): marco de estrada baixo.
func milestone(pos: Vector3) -> void:
	var stone := mat(Color(0.58, 0.56, 0.53), 0.05, 0.85)
	visual_box(Vector3(0.42, 0.9, 0.42), pos + Vector3(0.0, 0.45, 0.0), stone)
	visual_box(Vector3(0.54, 0.18, 0.54), pos + Vector3(0.0, 0.95, 0.0), stone)
