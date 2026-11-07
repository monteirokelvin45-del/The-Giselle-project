extends Node3D
## Região de expedição (v0.5) — mundo paramétrico por const REGIONS do GameState.
## Cada visita: seis inimigos escalados, clima aleatório e um ciclo dia/noite.

const KIT := "res://assets/models/env/decoration/nature/"
const GOBKIT := "res://assets/models/nature/"

var _cfg: Dictionary = {}
var _sun: DirectionalLight3D
var _env: Environment
var _sky_mat: ProceduralSkyMaterial
var _alive: int = 0
var _day_t: float = 0.3
var _clears: int = 0
var _banner: Label
var _banner_layer: CanvasLayer
var _banner_timer: float = 0.0
var _player: Node3D = null
var _env_mf := preload("res://src/visuals/model_factory.gd")
var _storm: bool = false
var _music_timer: float = 0.0
var _rain_follow: Node3D = null
var _lightning_timer: float = 6.0
var _flash_time: float = 0.0

func _ready() -> void:
	var region_id := GameState.current_region
	_cfg = GameState.region_config(region_id)
	_storm = randf() < 0.3
	_clears = int(GameState.region_clears.get(region_id, 0))
	_build_environment()
	_build_ground_and_props()
	_spawn_enemies()
	_spawn_exit_portal()
	_build_banner()
	var player_scene := preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.position = respawn_position()
	add_child(player)
	_player = player
	if _storm:
		_build_storm()
	UI.set_in_game(true)
	Audio.play_music("exploration")
	var text := tr("%s — %s") % [String(_cfg["name"]).to_upper(), tr(String(_cfg["desc"]))]
	if _storm:
		text += tr("  ·  TEMPESTADE À MEDIDA")
	_show_banner(text, 4.5)

func respawn_position() -> Vector3:
	return Vector3(0.0, 1.3, 6.0)

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	_env = Environment.new()
	var sky := Sky.new()
	_sky_mat = ProceduralSkyMaterial.new()
	_sky_mat.sky_top_color = _cfg["sky_top"]
	_sky_mat.sky_horizon_color = _cfg["sky_horizon"]
	_sky_mat.ground_bottom_color = Color(_cfg["ground"]).darkened(0.4)
	_sky_mat.ground_horizon_color = Color(_cfg["sky_horizon"]).darkened(0.25)
	sky.sky_material = _sky_mat
	_env.sky = sky
	_env.background_mode = Environment.BG_SKY
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	_env.ambient_light_energy = 0.62
	_env.fog_enabled = true
	_env.fog_density = float(_cfg["fog_density"]) * (1.55 if _storm else 1.0)
	_env.fog_light_color = _cfg["fog"]
	world_env.environment = _env
	add_child(world_env)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-35.0, -25.0, 0.0)
	_sun.light_energy = (0.78 if _storm else 1.15)
	_sun.light_color = _cfg["sun"]
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 80.0
	_sun.directional_shadow_max_distance = 90.0
	add_child(_sun)

## Tempestade (v0.5): chuva visível que acompanha o jogador + relâmpagos com
## trovoada. A tempestade é sorteada à chegada (30% das visitas).
func _build_storm() -> void:
	_rain_follow = Node3D.new()
	add_child(_rain_follow)
	var rain := GPUParticles3D.new()
	rain.amount = 900
	rain.lifetime = 1.1
	rain.local_coords = false
	rain.visibility_aabb = AABB(Vector3(-24.0, -6.0, -24.0), Vector3(48.0, 26.0, 48.0))
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(18.0, 1.0, 18.0)
	mat.direction = Vector3(0.12, -1.0, 0.03)
	mat.spread = 3.0
	mat.gravity = Vector3(0.0, -28.0, 0.0)
	mat.initial_velocity_min = 15.0
	mat.initial_velocity_max = 22.0
	rain.process_material = mat
	var drop := BoxMesh.new()
	drop.size = Vector3(0.045, 0.9, 0.045)
	var drop_mat := StandardMaterial3D.new()
	drop_mat.albedo_color = Color(0.72, 0.8, 0.95, 0.55)
	drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	drop_mat.disable_receive_shadows = true
	drop.material = drop_mat
	rain.draw_pass_1 = drop
	_rain_follow.add_child(rain)
	_rain_follow.global_position = respawn_position() + Vector3(0.0, 15.0, 0.0)
	_lightning_timer = randf_range(3.0, 8.0)

func _build_ground_and_props() -> void:
	var ground := StandardMaterial3D.new()
	ground.albedo_color = _cfg["ground"]
	ground.roughness = 0.97
	ground.metallic = 0.02
	var body := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(180.0, 1.0, 180.0)
	mesh.mesh = bm
	mesh.material_override = ground
	body.add_child(mesh)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = bm.size
	col.shape = cs
	body.add_child(col)
	body.position = Vector3(0, -0.5, 0)
	add_child(body)
	_compose_biome(String(_cfg["id"]))

## Composição v1.0 de cada região: densidade alta + POIs originais
## (ver docs/WORLD.md). Respeita a exclusão do spawn/portal em (0, 8).
func _compose_biome(region_id: String) -> void:
	var mk = preload("res://src/world/map_kit.gd").new(self, 9001 + region_id.hash())
	const AVOID := Vector3(0.0, 0.0, 8.0)
	var rocks: Array[String] = ["decoration/nature/rock_single_A.gltf", "decoration/nature/rock_single_C.gltf"]
	var mountains: Array[String] = ["decoration/nature/mountain_A.gltf", "decoration/nature/mountain_B.gltf", "decoration/nature/mountain_C.gltf"]
	match region_id:
		"ruun":
			# Floresta primeva: dupla copa + sob-bosque denso + acampamento e templo engolido
			mk.mountain_ring(80.0, 96.0, 15, mountains, 0.0, 5.5, 8.5, 5)
			mk.rock_scatter(26, 15.0, 66.0, AVOID, 9.0, rocks, 0.7, 2.0, 5)
			mk.flora_scatter(72, 44, 9.0, 68.0, AVOID, 8.0, 5)
			mk.double_canopy(66, 34, 13.0, 66.0, AVOID, 9.0, 5)
			mk.tent_camp(Vector3(-19.0, 0.0, -13.0), false)
			mk.engineer_ruins(Vector3(17.0, 0.0, -21.0))
		"sahr":
			# Dunas mortas: oásis de pedra, túmulos e um obelisco solar
			mk.mountain_ring(74.0, 94.0, 15, [mountains[0], mountains[1]], 0.0, 4.0, 7.0, 6)
			mk.rock_scatter(48, 11.0, 68.0, AVOID, 9.0, rocks, 0.9, 3.0, 6)
			mk.flora_scatter(16, 26, 10.0, 64.0, AVOID, 9.0, 6)
			mk.engineer_ruins(Vector3(16.0, 0.0, -17.0))
			mk.obelisk(Vector3(-19.0, 0.0, -12.0), 7.2, Color(1.0, 0.82, 0.35))
			mk.tent_camp(Vector3(-9.0, 0.0, 15.0), true)
		"khar":
			# Vale fechado de atrito e gelo: paredes altas, para-raios e um posto
			mk.mountain_ring(70.0, 88.0, 19, mountains, 0.0, 6.0, 10.0, 7)
			mk.rock_scatter(52, 12.0, 64.0, AVOID, 9.0, rocks, 0.9, 3.4, 7)
			mk.flora_scatter(22, 12, 10.0, 58.0, AVOID, 9.0, 7)
			mk.flora("Cliff001.glb", Vector3(52.0, 0.0, 44.0), 0.7, 2.4)
			mk.flora("Cliff002.glb", Vector3(-56.0, 0.0, -32.0), 2.1, 2.8)
			mk.flora("Cliff003.glb", Vector3(-50.0, 0.0, 46.0), 1.2, 2.2)
			mk.flora("Cliff001.glb", Vector3(55.0, 0.0, -44.0), 4.4, 2.6)
			mk.watchtower(Vector3(-23.0, 0.0, 12.0))
			mk.obelisk(Vector3(18.0, 0.0, -15.0), 6.4, Color(0.72, 0.87, 1.0))
		"lume":
			# Atoll de pedra clara: recife partido, farol de fósforo, doca
			mk.mountain_ring(76.0, 90.0, 11, [mountains[0], mountains[1]], 0.0, 2.5, 4.2, 8)
			mk.rock_scatter(44, 11.0, 66.0, AVOID, 9.0, rocks, 0.8, 2.4, 8)
			for i in range(16):
				var angle := TAU * float(i) / 16.0
				var atoll_r := 24.0 + 26.0 * fmod(absf(sin(angle * 3.7 + 1.3)), 1.0)
				var atoll_pos := Vector3(cos(angle) * atoll_r, 0.0, sin(angle) * atoll_r)
				var atoll_s := 1.5 + 1.2 * fmod(absf(sin(angle * 5.3 + 0.7)), 1.0)
				mk.flora("Cliff002.glb", atoll_pos, angle + PI * 0.5, atoll_s)
			mk.flora_scatter(34, 14, 8.0, 56.0, AVOID, 8.0, 8)
			mk.lighthouse(Vector3(23.0, 0.0, -16.0))
			mk.dock(Vector3(-14.0, 0.0, 14.0))
		"aer":
			# Arquipélago celeste: ilhas invertidas, arco quebrado, posto de observação
			mk.floating_islands(9, 7.0, 24.0, 9)
			mk.rock_scatter(30, 11.0, 64.0, AVOID, 9.0, rocks, 0.8, 2.6, 9)
			mk.flora_scatter(22, 9, 9.0, 56.0, AVOID, 9.0, 9)
			mk.sky_arch(Vector3(17.0, 0.0, -14.0))
			mk.watchtower(Vector3(-19.0, 0.0, -12.0))
			mk.obelisk(Vector3(12.0, 0.0, -19.0), 6.2, Color(0.88, 0.85, 1.0))
		"orun":
			# Fim do Abismo: basalt negro, altar e a fenda que nunca fecha
			mk.rock_scatter(38, 11.0, 66.0, AVOID, 9.0, rocks, 0.9, 3.2, 10)
			mk.floating_islands(6, 9.0, 28.0, 10)
			mk.abyss_altar(Vector3(0.0, 0.0, -20.0))
			mk.crack_glow(Vector3(2.0, 0.0, 2.0), 30.0)
			mk.obelisk(Vector3(-24.0, 0.0, -6.0), 4.6, Color(0.55, 0.3, 0.9))
			mk.obelisk(Vector3(25.0, 0.0, -8.0), 4.1, Color(0.55, 0.3, 0.9))
		_:
			mk.mountain_ring(74.0, 92.0, 13, mountains, 0.0, 5.0, 8.0, 42)
			mk.rock_scatter(24, 12.0, 70.0, AVOID, 9.0, rocks, 0.8, 2.2, 42)
			mk.flora_scatter(40, 18, 9.0, 66.0, AVOID, 8.0, 42)


func _spawn_enemies() -> void:
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var types: Array = _cfg["types"]
	for i in range(types.size()):
		var enemy = enemy_scene.instantiate()
		enemy.set("enemy_type", String(types[i]))
		enemy.set("power_mult", float(_cfg["power"]))
		var angle := TAU * float(i) / float(types.size()) + randf() * 0.8
		var radius := 15.0 + randf() * 25.0
		enemy.position = Vector3(cos(angle) * radius, 0.3, sin(angle) * radius)
		enemy.died.connect(_on_enemy_died)
		add_child(enemy)
	_alive = types.size()

func _spawn_exit_portal() -> void:
	var portal_scene := preload("res://scenes/scene_portal.tscn")
	var portal = portal_scene.instantiate()
	portal.set("target_scene", "res://scenes/main.tscn")
	portal.set("prompt_text", "E — Voltar ao Vale de Noro")
	portal.set("ring_color", Color(0.6, 0.85, 1.0))
	portal.set("glow_color", Color(0.4, 0.7, 0.95))
	portal.position = Vector3(0.0, 1.7, 10.0)
	add_child(portal)

func _build_banner() -> void:
	_banner_layer = CanvasLayer.new()
	_banner_layer.layer = 17
	add_child(_banner_layer)
	_banner = Label.new()
	_banner.anchor_left = 0.5
	_banner.anchor_right = 0.5
	_banner.anchor_top = 0.16
	_banner.anchor_bottom = 0.16
	_banner.offset_left = -520.0
	_banner.offset_right = 520.0
	_banner.offset_top = 0.0
	_banner.offset_bottom = 46.0
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 22)
	_banner.add_theme_color_override("font_color", Color(0.95, 0.9, 0.7))
	_banner.add_theme_constant_override("outline_size", 6)
	_banner.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.9))
	_banner.visible = false
	_banner_layer.add_child(_banner)

func _show_banner(text: String, duration: float) -> void:
	_banner.text = tr(text)
	_banner.visible = true
	_banner.modulate.a = 1.0
	_banner_timer = duration

func _process(delta: float) -> void:
	_music_timer -= delta
	if _music_timer <= 0.0:
		_music_timer = 2.0
		var threat := false
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy is Node3D and float(enemy.get("hp")) > 0.0:
				if _player != null and enemy.global_position.distance_to(_player.global_position) < 14.0:
					threat = true
					break
		Audio.play_music("combat" if threat else "exploration")
	if _rain_follow != null and _player != null:
		_rain_follow.global_position = _player.global_position + Vector3(0.0, 15.0, 0.0)
	if _storm:
		_lightning_timer -= delta
		if _lightning_timer <= 0.0:
			_lightning_timer = randf_range(5.0, 14.0)
			_flash_time = 0.35
			Audio.play("thunder", -6.0, randf_range(0.85, 1.15))
		# (o flash é aplicado abaixo, onde a luz é escrita)
	# Ciclo dia/noite (compressão: ~4 minutos por ciclo completo)
	_day_t += delta / 240.0
	if _day_t > 1.0:
		_day_t -= 1.0
	var day_angle: float = lerp(-20.0, -160.0, _day_t)
	_sun.rotation_degrees.x = day_angle
	var daylight := clampf(sin(_day_t * PI), 0.0, 1.0)
	var storm_flash := 1.0
	if _flash_time > 0.0:
		_flash_time -= delta
		var fade := clampf(_flash_time / 0.35, 0.0, 1.0)
		var flicker: float = 0.5 + 0.5 * sin(_flash_time * 47.0)
		storm_flash = 1.0 + 2.1 * flicker * fade
	_sun.light_energy = (0.3 + 0.85 * daylight) * (0.65 if _storm else 1.0) * storm_flash
	_env.ambient_light_energy = (0.3 + 0.5 * daylight) * storm_flash
	_env.fog_density = float(_cfg["fog_density"]) * (1.55 if _storm else 1.0) * (1.0 + 0.5 * (1.0 - daylight))
	var horizon_day: Color = _cfg["sky_horizon"]
	var horizon_night := Color(0.02, 0.02, 0.06)
	_sky_mat.sky_horizon_color = horizon_day.lerp(horizon_night, 1.0 - daylight)
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 1.0:
			_banner.modulate.a = clampf(_banner_timer, 0.0, 1.0)
		if _banner_timer <= 0.0:
			_banner.visible = false

func _on_enemy_died(_enemy: Node3D, _enemy_type: String) -> void:
	_alive -= 1
	if _alive <= 0:
		_region_complete()

func _region_complete() -> void:
	var region_id := GameState.current_region
	GameState.region_clears[region_id] = int(GameState.region_clears.get(region_id, 0)) + 1
	GameState.region_known[region_id] = true
	var xp := int(_cfg["xp"]) + 25 * int(GameState.region_clears[region_id])
	var marcos := int(_cfg["marcos"]) + 15 * int(GameState.region_clears[region_id])
	GameState.add_xp(xp)
	GameState.add_marcos(marcos)
	GameState.add_reputation("ordem", 4)
	GameState.stats_changed.emit()
	_show_banner(tr("REGIÃO CONCLUÍDA — %s  ·  +%d XP  ·  +%d marcos") % [String(_cfg["name"]), xp, marcos], 5.0)
	Audio.play("levelup")

func portal_exit() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
