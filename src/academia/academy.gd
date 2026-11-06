extends Node3D
## A Academia Real de Veyra (v0.4).
## Pátio central, arena de provas, forja, jardins, biblioteca, torre e
## dormitórios. Aqui Kael passa nas provas, recruta companheiros e treina com
## os mestres.

const ENV := "res://assets/models/env/"

const EXAMS := {
	"duelo": {"name": "Prova de Duelo", "companion": "bram",
		"enemies": ["guardiao"], "power": 0.9, "xp": 250, "marcos": 80},
	"floresta": {"name": "Prova da Floresta", "companion": "sena",
		"enemies": ["wolf", "wolf", "wolf", "salteador"], "power": 1.0, "xp": 280, "marcos": 85},
	"equipas": {"name": "Prova de Equipas", "companion": "liora",
		"enemies": ["salteador", "salteador", "salteador", "salteador", "cinza"], "power": 0.85, "xp": 300, "marcos": 90},
	"labirinto": {"name": "Labirinto Arcano", "companion": "iven",
		"enemies": ["cinza", "cinza", "cinza", "cinza"], "power": 1.1, "xp": 260, "marcos": 85},
}

const COMPANION_NAMES := {
	"bram": "Bram Ferro", "sena": "Sena Raiz", "iven": "Iven Lago", "liora": "Liora Venn",
}

var _player: Node3D = null
var _active_exam: String = ""
var _exam_alive: int = 0
var _env_mf := preload("res://src/visuals/model_factory.gd")

func _ready() -> void:
	_build_environment()
	_build_ground()
	_build_buildings()
	_build_props()
	_build_npcs()
	_spawn_exit_portal()
	_spawn_rest_point()
	var player_scene := preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.position = respawn_position()
	add_child(player)
	_player = player
	UI.set_in_game(true)
	Audio.play_music("exploration")
	if not Dialogue.dialogue_finished.is_connected(_on_dialogue_action):
		Dialogue.dialogue_finished.connect(_on_dialogue_action)

func respawn_position() -> Vector3:
	return Vector3(0.0, 1.3, 38.0)

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _static_body(size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	col.shape = cs
	body.add_child(col)
	body.position = pos
	add_child(body)
	return body

func _visual_cyl(radius: float, height: float, pos: Vector3, mat: StandardMaterial3D, segments: int = 20) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = segments
	mesh.mesh = cyl
	mesh.material_override = mat
	mesh.position = pos
	add_child(mesh)
	return mesh

func _collider_box(size: Vector3, pos: Vector3, rot_y: float = 0.0) -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = size
	col.shape = cs
	col.position = pos
	body.add_child(col)
	body.rotation.y = rot_y
	add_child(body)

func _env(path: String, pos: Vector3, rot_y: float, scale_factor: float) -> void:
	_env_mf.spawn_env(self, ENV + path, pos, rot_y, scale_factor)

# ------------------------------------------------------------ ambiente ------
func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.24, 0.19, 0.42)
	sky_mat.sky_horizon_color = Color(0.85, 0.6, 0.38)
	sky_mat.ground_bottom_color = Color(0.18, 0.14, 0.12)
	sky_mat.ground_horizon_color = Color(0.6, 0.42, 0.3)
	sky_mat.sun_angle_max = 14.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.72
	env.fog_enabled = true
	env.fog_density = 0.0062
	env.fog_light_color = Color(0.72, 0.55, 0.42)
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-28.0, 155.0, 0.0)
	sun.light_energy = 1.15
	sun.light_color = Color(1.0, 0.82, 0.62)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	sun.shadow_map_size = 2048
	add_child(sun)

# -------------------------------------------------------------- chão --------
func _build_ground() -> void:
	var grass := _mat(Color(0.26, 0.34, 0.16), 0.0, 0.95)
	_static_body(Vector3(150.0, 1.0, 120.0), Vector3(0, -0.5, 0), grass)
	# Pátio central de pedra
	var stone := _mat(Color(0.52, 0.5, 0.46), 0.05, 0.8)
	_visual_cyl(13.0, 0.06, Vector3(0, 0.03, 12), stone, 26)
	# Caminhos
	_visual_cyl(4.4, 0.05, Vector3(0, 0.025, 32), stone, 12)   # entrada → pátio
	_visual_cyl(4.4, 0.05, Vector3(0, 0.025, 0), stone, 12)    # pátio → norte
	_visual_cyl(4.4, 0.05, Vector3(22, 0.025, 12), stone, 12)  # pátio → arena
	_visual_cyl(4.4, 0.05, Vector3(11, 0.025, 12), stone, 12)
	# Arena (disco elevado)
	var arena_mat := _mat(Color(0.4, 0.38, 0.34), 0.08, 0.7)
	_visual_cyl(11.0, 0.3, Vector3(44, 0.15, 0), arena_mat, 30)
	# Jardins de Sena
	var garden := _mat(Color(0.18, 0.36, 0.14), 0.0, 0.97)
	_visual_cyl(12.0, 0.05, Vector3(38, 0.025, 24), garden, 22)

# ----------------------------------------------------------- edifícios ------
func _build_buildings() -> void:
	# Forja de Bram (oestção-norte)
	_collider_box(Vector3(6.4, 3.4, 5.2), Vector3(-40, 1.7, -28), 0.3)
	_env("buildings/red/building_blacksmith_red.gltf", Vector3(-40, 0, -28), 0.3, 0.62)
	# Biblioteca / Arquivo de Voss (este-norte) — a igreja amarela impõe presença
	_collider_box(Vector3(6.6, 4.6, 5.4), Vector3(40, 2.3, -26), -0.35)
	_env("buildings/yellow/building_church_yellow.gltf", Vector3(40, 0, -26), -0.35, 0.72)
	# Torre dos Professores (norte)
	_collider_box(Vector3(4.6, 7.5, 4.6), Vector3(0, 3.75, -40), 0.0)
	_env("buildings/yellow/building_tower_A_yellow.gltf", Vector3(0, 0, -40), 0.0, 0.95)
	# Taverna de Veyra (oeste)
	_collider_box(Vector3(6.0, 3.6, 5.0), Vector3(-40, 1.8, 18), 0.55)
	_env("buildings/red/building_tavern_red.gltf", Vector3(-40, 0, 18), 0.55, 0.62)
	# Dormitórios / tenda (oeste)
	_env("decoration/props/tent.gltf", Vector3(-38, 0, 6.5), 1.2, 1.6)
	_collider_box(Vector3(3.4, 2.4, 3.0), Vector3(-38, 1.2, 6.5), 1.2)
	# Casas da academia (sul)
	_collider_box(Vector3(3.4, 2.6, 2.9), Vector3(-18, 1.3, 30), 0.4)
	_env("buildings/green/building_home_A_green.gltf", Vector3(-18, 0, 30), 0.4, 0.62)
	_collider_box(Vector3(3.2, 2.5, 2.7), Vector3(20, 1.25, 30), -0.5)
	_env("buildings/blue/building_home_B_blue.gltf", Vector3(20, 0, 30), -0.5, 0.62)

func _build_props() -> void:
	# Poço no centro do pátio
	_collider_box(Vector3(1.6, 1.2, 1.6), Vector3(0, 0.6, 12), 0.0)
	_env("buildings/yellow/building_well_yellow.gltf", Vector3(0, 0, 12), 0.0, 0.7)
	# Montanhas a enquadrar o campus
	_env("decoration/nature/mountain_A.gltf", Vector3(-58, 0, -44), 0.2, 3.4)
	_env("decoration/nature/mountain_B.gltf", Vector3(56, 0, -46), 1.1, 3.0)
	_env("decoration/nature/mountain_C.gltf", Vector3(12, 0, -62), 2.0, 3.6)
	_env("decoration/nature/mountain_A.gltf", Vector3(-62, 0, 26), 2.4, 2.8)
	# Armas e barris na forja e na arena
	_env("decoration/props/weaponrack.gltf", Vector3(-34.5, 0, -24.5), 2.2, 1.2)
	_env("decoration/props/barrel.gltf", Vector3(-44.5, 0, -22.5), 0.0, 1.1)
	if ResourceLoader.exists(ENV + "decoration/props/anvil.gltf"):
		_env("decoration/props/anvil.gltf", Vector3(-38.0, 0, -22.0), 0.5, 1.0)
	# Barris na arena (cantos)
	var barrel_positions := [
		Vector3(37, 0, -7), Vector3(51, 0, -7), Vector3(37, 0, 7), Vector3(51, 0, 7),
	]
	for p in barrel_positions:
		_env("decoration/props/barrel.gltf", p, randf() * TAU, 1.0)
	# Árvores espalhadas (kaykit nature)
	var tree_positions := [
		Vector3(-26, 0, -8), Vector3(-14, 0, -20), Vector3(14, 0, -14), Vector3(28, 0, 8),
		Vector3(-28, 0, 24), Vector3(28, 0, 30), Vector3(-8, 0, 22), Vector3(8, 0, 26),
	]
	for p in tree_positions:
		_env("decoration/nature/tree_single_A.gltf", p, randf() * TAU, randf_range(1.1, 1.7))
	# Relva e arbustos nos jardins de Sena
	_env("decoration/nature/trees_A_medium.gltf", Vector3(34, 0, 27), 0.4, 1.4)
	_env("decoration/nature/trees_B_medium.gltf", Vector3(43, 0, 21), 2.1, 1.3)

func _build_npcs() -> void:
	var npc_scene := preload("res://scenes/npc.tscn")
	var defs := [
		{"id": "bram", "name": "Bram Ferro", "pos": Vector3(-33.5, 0.3, -21.5), "robe": Color(0.45, 0.3, 0.18)},
		{"id": "voss", "name": "Arquivista Voss", "pos": Vector3(33.0, 0.3, -19.0), "robe": Color(0.3, 0.28, 0.42)},
		{"id": "dario_academia", "name": "Mestre Dario Vale", "pos": Vector3(0.0, 0.3, -30.5), "robe": Color(0.35, 0.38, 0.5)},
		{"id": "sena", "name": "Sena Raiz", "pos": Vector3(36.5, 0.3, 22.5), "robe": Color(0.28, 0.42, 0.22)},
		{"id": "iven", "name": "Iven Lago", "pos": Vector3(28.0, 0.3, -8.0), "robe": Color(0.22, 0.3, 0.48)},
		{"id": "liora_academia", "name": "Liora Venn", "pos": Vector3(22.0, 0.3, 12.0), "robe": Color(0.35, 0.32, 0.48)},
	]
	for d in defs:
		var npc = npc_scene.instantiate()
		npc.set("npc_name", d["name"])
		npc.set("dialogue_id", d["id"])
		npc.set("robe_color", d["robe"])
		npc.position = d["pos"]
		add_child(npc)

func _spawn_exit_portal() -> void:
	var portal_scene := preload("res://scenes/scene_portal.tscn")
	var portal = portal_scene.instantiate()
	portal.set("target_scene", "res://scenes/main.tscn")
	portal.set("prompt_text", "E — Voltar ao Vale de Noro")
	portal.set("ring_color", Color(0.55, 0.75, 1.0))
	portal.set("glow_color", Color(0.35, 0.6, 0.95))
	portal.position = Vector3(6.0, 1.7, 44.0)
	add_child(portal)

func _spawn_rest_point() -> void:
	var rp := Node3D.new()
	rp.set_script(preload("res://src/interaction/rest_point.gd"))
	rp.position = Vector3(-38.0, 0.0, 4.0)
	add_child(rp)

# ---------------------------------------------------------------- exames ----
func _on_dialogue_action(action: String) -> void:
	match action:
		"exam_duelo": _start_exam("duelo")
		"exam_floresta": _start_exam("floresta")
		"exam_equipas": _start_exam("equipas")
		"exam_labirinto": _start_exam("labirinto")
		"train_attr":
			if GameState.marcos >= 120:
				GameState.add_marcos(-120)
				GameState.attribute_points += 1
				GameState.notify("+1 ponto de atributo (Esc → Atributos). O Mestre aprova.")
				GameState.stats_changed.emit()
				Audio.play("levelup", -6.0)
			else:
				GameState.notify("Sem marcos suficientes (120).")
		"voss_meet":
			GameState.exams_done["voss_met"] = true
			GameState.add_reputation("arquivistas", 10)
			GameState.add_reputation("irmandade", 5)
			GameState.stats_changed.emit()
		"romance_bram": _romance("bram")
		"romance_sena": _romance("sena")
		"romance_iven": _romance("iven")
		"romance_liora": _romance("liora")

func _romance(id: String) -> void:
	GameState.romance_id = id
	GameState.add_companion_loyalty(id, 30)
	GameState.add_reputation("academia", 5)
	GameState.notify("O laço com %s aprofundou-se." % String(COMPANION_NAMES.get(id, id)))
	GameState.stats_changed.emit()

func _start_exam(exam_id: String) -> void:
	if GameState.exams_done.has(exam_id):
		GameState.notify("Já passaste esta prova. Vai com os deuses.")
		return
	if _active_exam != "":
		GameState.notify("A prova anterior ainda não terminou!")
		return
	var cfg: Dictionary = EXAMS[exam_id]
	_active_exam = exam_id
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var enemy_list: Array = cfg["enemies"]
	var power := float(cfg["power"])
	var arena_center := Vector3(44.0, 0.35, 0.0)
	for i in range(enemy_list.size()):
		var enemy = enemy_scene.instantiate()
		enemy.set("enemy_type", String(enemy_list[i]))
		enemy.set("power_mult", power)
		var angle := TAU * float(i) / float(enemy_list.size()) + 0.4
		enemy.position = arena_center + Vector3(cos(angle) * 5.0, 0.0, sin(angle) * 5.0)
		enemy.died.connect(_on_exam_enemy_died)
		add_child(enemy)
	_exam_alive = enemy_list.size()
	GameState.notify("%s iniciada! A arena a este." % String(cfg["name"]))
	Audio.play("rupture", -2.0)

func _on_exam_enemy_died(_enemy: Node3D, _enemy_type: String) -> void:
	if _active_exam == "":
		return
	_exam_alive -= 1
	if _exam_alive <= 0:
		_complete_exam(_active_exam)

func _complete_exam(exam_id: String) -> void:
	var cfg: Dictionary = EXAMS[exam_id]
	_active_exam = ""
	GameState.exams_done[exam_id] = true
	var companion := String(cfg["companion"])
	GameState.companions[companion] = maxi(GameState.companion_loyalty(companion), 60)
	GameState.add_xp(int(cfg["xp"]))
	GameState.add_marcos(int(cfg["marcos"]))
	GameState.add_reputation("academia", 15)
	GameState.notify("PROVA SUPERADA — %s junta-se a ti!" % String(COMPANION_NAMES.get(companion, companion)))
	GameState.stats_changed.emit()
	Audio.play("levelup")

# ------------------------------------------------------------------ portal ---
func portal_exit() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
