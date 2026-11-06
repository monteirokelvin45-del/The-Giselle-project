extends Node3D
## O Sistema — Sala Branca (v0.3).
## Configurador de simulação: ambiente, ameaça, inimigos, tempo e poções.
## Após a simulação: avaliação completa (precisão, parries, reação, estilo)
## e memória do Sistema — ele lembra-se, e tem opiniões.

var _player: Node3D = null
var _time: float = 0.0
var _sim_running: bool = false
var _sim_time: float = 0.0
var _sim_limit: float = 0.0
var _sim_start_msec: int = 0
var _dummies: Array = []
var _spawned_enemies: Array = []
var _potion_nodes: Array = []

var _subtitle_label: Label
var _subtitle_layer: CanvasLayer
var _subtitle_index: int = 0
var _subtitle_timer: float = 0.8

var _sun: DirectionalLight3D
var _env: Environment
var _floor_mat: StandardMaterial3D
var _pillar_mat: StandardMaterial3D

# --- UI: configurador ---
var _setup_layer: CanvasLayer
var _setup_panel: PanelContainer
var _env_value: Label
var _threat_buttons: Array[Button] = []
var _count_value: Label
var _time_value: Label
var _potions_value: Button
var _reward_label: Label
const TIME_OPTIONS := [0.0, 45.0, 60.0, 90.0, 120.0]
const TIME_LABELS := ["∞", "45s", "60s", "90s", "120s"]
var _time_idx: int = 2

# --- UI: avaliação ---
var _eval_layer: CanvasLayer
var _eval_panel: PanelContainer
var _eval_stats: Label
var _eval_bonus: Label
var _eval_number: Label
var _eval_history: Label

const SUBTITLES := [
	"Bem-vindo, Kael Noro.",
	"Sem Núcleo Arcano. Sem emissão. Sem registo.",
	"Ambiente: à tua escolha. Ameaça: por tua conta e risco.",
	"Tu és a exceção... e as exceções são interessantes.",
]

# --------------------------------------------------------------- arranque ---
func _ready() -> void:
	_build_environment()
	_build_room()
	_respawn_dummies()
	_spawn_portal()
	var player_scene := preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector3(0.0, 1.3, 5.0)
	add_child(player)
	_player = player
	player.hp = GameState.max_hp()
	player.stamina = GameState.max_stamina()
	if player.has_method("reset_combat_stats"):
		player.reset_combat_stats()
	UI.set_in_game(true)
	_build_subtitles()
	_build_setup_ui()
	_build_evaluation_ui()
	_apply_configuration()

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.fog_enabled = true
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_energy = 1.15
	world_env.environment = _env
	add_child(world_env)
	_sun = DirectionalLight3D.new()
	_sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	_sun.light_energy = 0.9
	_sun.shadow_enabled = true
	_sun.directional_shadow_max_distance = 60.0
	_sun.shadow_map_size = 2048
	add_child(_sun)

func _build_room() -> void:
	_floor_mat = StandardMaterial3D.new()
	_floor_mat.roughness = 0.32
	_floor_mat.metallic = 0.08
	var floor_body := StaticBody3D.new()
	var floor_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 90.0
	cyl.bottom_radius = 90.0
	cyl.height = 0.4
	floor_mesh.mesh = cyl
	floor_mesh.material_override = _floor_mat
	floor_mesh.position.y = -0.2
	floor_body.add_child(floor_mesh)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 90.0
	cs.height = 0.4
	col.shape = cs
	col.position.y = -0.2
	floor_body.add_child(col)
	add_child(floor_body)
	_pillar_mat = StandardMaterial3D.new()
	_pillar_mat.roughness = 0.5
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + 0.4
		var pillar := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 2.6
		pm.bottom_radius = 3.1
		pm.height = 42.0
		pillar.mesh = pm
		pillar.material_override = _pillar_mat
		pillar.position = Vector3(cos(angle) * 34.0, 21.0, sin(angle) * 34.0)
		add_child(pillar)

## Aplica a configuração atual (ambiente) ao quarto e à luz.
func _apply_configuration() -> void:
	var cfg := GameState.environment_config()
	var ground: Color = cfg["ground"]
	_floor_mat.albedo_color = ground
	_pillar_mat.albedo_color = ground.lightened(0.18)
	_env.background_color = cfg["fog"]
	_env.fog_light_color = cfg["fog"]
	_env.fog_density = float(cfg["fog_density"])
	_env.ambient_light_color = cfg["ambient"]
	_sun.light_color = cfg["light"]

func _spawn_dummies_inner(positions: Array) -> void:
	var dummy_script := preload("res://src/system/dummy.gd")
	for pos in positions:
		var dummy := Node3D.new()
		dummy.set_script(dummy_script)
		dummy.position = pos
		add_child(dummy)
		_dummies.append(dummy)

func _respawn_dummies() -> void:
	for d in _dummies:
		if is_instance_valid(d):
			d.queue_free()
	_dummies.clear()
	_spawn_dummies_inner([Vector3(-6.0, 0.0, -3.0), Vector3(0.0, 0.0, -8.0), Vector3(6.0, 0.0, -3.0)])

func _spawn_portal() -> void:
	var portal_scene := preload("res://scenes/exit_portal.tscn")
	var portal = portal_scene.instantiate()
	portal.position = Vector3(0.0, 1.7, -13.5)
	add_child(portal)

# ------------------------------------------------------------- legendas ----
func _build_subtitles() -> void:
	_subtitle_layer = CanvasLayer.new()
	_subtitle_layer.layer = 18
	add_child(_subtitle_layer)
	_subtitle_label = Label.new()
	_subtitle_label.anchor_left = 0.5
	_subtitle_label.anchor_right = 0.5
	_subtitle_label.anchor_top = 1.0
	_subtitle_label.anchor_bottom = 1.0
	_subtitle_label.offset_left = -460.0
	_subtitle_label.offset_right = 460.0
	_subtitle_label.offset_top = -300.0
	_subtitle_label.offset_bottom = -260.0
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.add_theme_font_size_override("font_size", int(19.0 * GameState.subtitle_scale))
	_subtitle_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	_subtitle_label.visible = false
	_subtitle_layer.add_child(_subtitle_label)

func _process(delta: float) -> void:
	if _subtitle_index >= SUBTITLES.size():
		_time += delta
	if _subtitle_index < SUBTITLES.size():
		_subtitle_timer -= delta
		if _subtitle_timer <= 0.0:
			_subtitle_label.text = SUBTITLES[_subtitle_index]
			_subtitle_label.visible = true
			_subtitle_label.modulate.a = 1.0
			_subtitle_index += 1
			_subtitle_timer = 2.5
			var tween := create_tween()
			tween.tween_interval(1.7)
			tween.tween_property(_subtitle_label, "modulate:a", 0.0, 0.7)
	elif _subtitle_label.visible and _subtitle_label.modulate.a <= 0.01:
		_subtitle_label.visible = false
	# Temporizador da simulação
	if _sim_running:
		_sim_time += delta
		if _sim_limit > 0.0 and _sim_time >= _sim_limit:
			_finish_simulation()

# ------------------------------------------------------- UI: configurador ---
func _build_setup_ui() -> void:
	_setup_layer = CanvasLayer.new()
	_setup_layer.layer = 22
	_setup_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_setup_layer)
	_setup_panel = PanelContainer.new()
	_setup_panel.anchor_left = 0.5
	_setup_panel.anchor_right = 0.5
	_setup_panel.anchor_top = 0.5
	_setup_panel.anchor_bottom = 0.5
	_setup_panel.offset_left = -310.0
	_setup_panel.offset_right = 310.0
	_setup_panel.offset_top = -330.0
	_setup_panel.offset_bottom = 330.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.98, 0.97)
	style.border_color = Color(0.6, 0.6, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	_setup_panel.add_theme_stylebox_override("panel", style)
	_setup_panel.visible = false
	_setup_layer.add_child(_setup_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_setup_panel.add_child(vbox)

	var title := Label.new()
	title.text = "O SISTEMA — SIMULAÇÃO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", Color(0.16, 0.16, 0.22))
	vbox.add_child(title)

	# Ambiente
	var env_row := _cycle_row(vbox, "Ambiente")
	_env_value = env_row

	# Ameaça (5 níveis com requisitos)
	var threat_label := Label.new()
	threat_label.text = "Ameaça"
	threat_label.add_theme_font_size_override("font_size", 15)
	threat_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.36))
	vbox.add_child(threat_label)
	var threat_grid := GridContainer.new()
	threat_grid.columns = 5
	threat_grid.add_theme_constant_override("h_separation", 6)
	vbox.add_child(threat_grid)
	for i in range(5):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_threat_pressed.bind(i))
		threat_grid.add_child(btn)
		_threat_buttons.append(btn)

	# Nº de inimigos
	var count_row := _cycle_row(vbox, "Inimigos")
	_count_value = count_row

	# Tempo limite
	var time_row := _cycle_row(vbox, "Tempo limite")
	_time_value = time_row

	# Poções
	var pot_row := HBoxContainer.new()
	var pot_label := Label.new()
	pot_label.text = "Poções no chão"
	pot_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pot_label.add_theme_font_size_override("font_size", 15)
	pot_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.36))
	pot_row.add_child(pot_label)
	_potions_value = Button.new()
	_potions_value.custom_minimum_size = Vector2(90, 32)
	_potions_value.pressed.connect(_on_potions_toggled)
	pot_row.add_child(_potions_value)
	vbox.add_child(pot_row)

	_reward_label = Label.new()
	_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reward_label.add_theme_font_size_override("font_size", 12)
	_reward_label.add_theme_color_override("font_color", Color(0.2, 0.4, 0.45))
	vbox.add_child(_reward_label)

	var run_btn := Button.new()
	run_btn.text = "▶  EXECUTAR SIMULAÇÃO"
	run_btn.custom_minimum_size = Vector2(0, 42)
	run_btn.add_theme_font_size_override("font_size", 17)
	run_btn.pressed.connect(_on_execute)
	vbox.add_child(run_btn)
	var train_btn := Button.new()
	train_btn.text = "Voltar a treinar"
	train_btn.custom_minimum_size = Vector2(0, 32)
	train_btn.pressed.connect(_close_setup)
	vbox.add_child(train_btn)
	var leave_btn := Button.new()
	leave_btn.text = "Regressar ao Vale"
	leave_btn.custom_minimum_size = Vector2(0, 32)
	leave_btn.pressed.connect(_return_to_vale)
	vbox.add_child(leave_btn)
	_refresh_setup()

## Linha com botões ◀ valor ▶ — devolve o Label do valor.
func _cycle_row(parent: VBoxContainer, label_text: String) -> Label:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.36))
	row.add_child(label)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(38, 32)
	row.add_child(prev)
	var value := Label.new()
	value.custom_minimum_size = Vector2(170, 0)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 15)
	value.add_theme_color_override("font_color", Color(0.1, 0.1, 0.14))
	row.add_child(value)
	var next := Button.new()
	next.text = "▶"
	next.custom_minimum_size = Vector2(38, 32)
	row.add_child(next)
	parent.add_child(row)
	match label_text:
		"Ambiente":
			prev.pressed.connect(_cycle_environment.bind(-1))
			next.pressed.connect(_cycle_environment.bind(1))
		"Inimigos":
			prev.pressed.connect(_cycle_count.bind(-1))
			next.pressed.connect(_cycle_count.bind(1))
		"Tempo limite":
			prev.pressed.connect(_cycle_time.bind(-1))
			next.pressed.connect(_cycle_time.bind(1))
	return value

func _env_name() -> String:
	var cfg := GameState.environment_config()
	return String(cfg["name"])

func _cycle_environment(dir: int) -> void:
	var ids: Array = []
	for env in GameState.ARENA_ENVIRONMENTS:
		ids.append(String(env["id"]))
	var idx := maxi(0, ids.find(GameState.arena_environment))
	idx = (idx + dir + ids.size()) % ids.size()
	GameState.arena_environment = ids[idx]
	_apply_configuration()
	_refresh_setup()

func _cycle_count(dir: int) -> void:
	GameState.arena_enemy_count = clampi(GameState.arena_enemy_count + dir, 1, 5)
	_refresh_setup()

func _cycle_time(dir: int) -> void:
	_time_idx = clampi(_time_idx + dir, 0, TIME_OPTIONS.size() - 1)
	GameState.arena_time_limit = TIME_OPTIONS[_time_idx]
	_refresh_setup()

func _on_potions_toggled() -> void:
	GameState.arena_potions = not GameState.arena_potions
	_refresh_setup()

func _on_threat_pressed(idx: int) -> void:
	if idx == GameState.threat_level:
		return
	if not GameState.can_threat(idx):
		GameState.system_memory["refusals"] = int(GameState.system_memory.get("refusals", 0)) + 1
		GameState.stats_changed.emit()
		GameState.notify("«Não. O teu nível não justifica esse risco — recusa %d registada.»" % int(GameState.system_memory["refusals"]))
		return
	GameState.threat_level = idx
	_refresh_setup()

func _refresh_setup() -> void:
	_env_value.text = _env_name()
	for i in range(_threat_buttons.size()):
		var btn := _threat_buttons[i]
		var req: int = int(GameState.THREAT_LEVELS[i]["level_req"])
		var tname := String(GameState.THREAT_LEVELS[i]["name"])
		if GameState.can_threat(i):
			btn.text = "%s%s\nNv %d+" % [tname, "" if i != GameState.threat_level else " ✓", req]
			btn.disabled = false
		else:
			btn.text = "🔒 %s\nNv %d" % [tname, req]
			btn.disabled = true
	_count_value.text = str(GameState.arena_enemy_count)
	_time_value.text = TIME_LABELS[_time_idx]
	_potions_value.text = "Sim" if GameState.arena_potions else "Não"
	_reward_label.text = "Recompensa: ×%.2f XP  ·  Vida dos inimigos: ×%.2f" % [GameState.threat_reward_mult(), GameState.threat_hp_mult()]

func open_setup() -> void:
	if _player == null:
		return
	# sincronizar índice de tempo com o valor guardado
	_time_idx = TIME_OPTIONS.find(GameState.arena_time_limit)
	if _time_idx < 0:
		_time_idx = 2
	_refresh_setup()
	_setup_panel.visible = true
	UI.external_block = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Compatibilidade com o portal de saída.
func open_evaluation() -> void:
	open_setup()

func _close_setup() -> void:
	_setup_panel.visible = false
	UI.external_block = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# -------------------------------------------------------- simulação ---------
func _pool_for_threat(idx: int) -> Array:
	match idx:
		0: return ["wolf", "salteador", "wolf", "salteador", "wolf"]
		1: return ["salteador", "cinza", "wolf", "salteador", "cinza"]
		2: return ["cinza", "salteador", "cinza", "salteador", "wolf"]
		3: return ["cinza", "guardiao", "salteador", "cinza", "cinza"]
		_: return ["guardiao", "cinza", "guardiao", "cinza", "cinza"]

func _on_execute() -> void:
	if not GameState.can_threat(GameState.threat_level):
		GameState.system_memory["refusals"] = int(GameState.system_memory.get("refusals", 0)) + 1
		GameState.stats_changed.emit()
		GameState.notify("«O Sistema recusa. Recusa %d registada.»" % int(GameState.system_memory["refusals"]))
		return
	_start_simulation()

func _start_simulation() -> void:
	_close_setup()
	for d in _dummies:
		if is_instance_valid(d):
			d.queue_free()
	_dummies.clear()
	for e in _spawned_enemies:
		if is_instance_valid(e):
			e.queue_free()
	_spawned_enemies.clear()
	for p in _potion_nodes:
		if is_instance_valid(p):
			p.queue_free()
	_potion_nodes.clear()
	if _player != null and _player.has_method("reset_combat_stats"):
		_player.reset_combat_stats()
	if _player != null:
		_player.hp = GameState.max_hp()
		_player.stamina = GameState.max_stamina()
	_apply_configuration()
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var pool := _pool_for_threat(GameState.threat_level)
	var n := GameState.arena_enemy_count
	for i in range(n):
		var type := String(pool[i % pool.size()])
		var enemy = enemy_scene.instantiate()
		enemy.set("enemy_type", type)
		enemy.set("power_mult", GameState.threat_hp_mult())
		var angle := TAU * float(i) / float(n) + 0.7
		enemy.position = Vector3(cos(angle) * 6.5, 0.2, sin(angle) * 6.5)
		enemy.died.connect(_on_sim_enemy_died)
		add_child(enemy)
		_spawned_enemies.append(enemy)
	if GameState.arena_potions:
		_spawn_potion(Vector3(-3.5, 0.5, 1.5))
		_spawn_potion(Vector3(3.5, 0.5, 1.5))
	_sim_time = 0.0
	_sim_limit = GameState.arena_time_limit
	_sim_start_msec = Time.get_ticks_msec()
	_sim_running = true
	GameState.notify("Simulação iniciada — %s · Ameaça %s" % [_env_name(), GameState.threat_name()])
	Audio.play("rupture", -6.0)

func _spawn_potion(pos: Vector3) -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.position = pos
	var mesh_inst := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.14
	bm.bottom_radius = 0.18
	bm.height = 0.4
	mesh_inst.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.15, 0.8, 0.3)
	mat.emission_energy_multiplier = 2.0
	mesh_inst.material_override = mat
	area.add_child(mesh_inst)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.75
	shape.shape = sphere
	area.add_child(shape)
	area.body_entered.connect(_on_potion_body_entered.bind(area))
	add_child(area)
	_potion_nodes.append(area)

func _on_potion_body_entered(body: Node3D, potion: Area3D) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("heal_external"):
		body.heal_external(30.0)
	else:
		body.set("hp", minf(GameState.max_hp(), float(body.get("hp")) + 30.0))
	GameState.notify("+30 vida (poção da simulação)")
	Audio.play("potion")
	if is_instance_valid(potion):
		potion.queue_free()

func _alive_enemies() -> int:
	var alive := 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(e) and e is Node3D and float(e.get("hp")) > 0.0:
			alive += 1
	return alive

func _on_sim_enemy_died(_enemy: Node3D, _enemy_type: String) -> void:
	if not _sim_running:
		return
	await get_tree().create_timer(2.4).timeout
	if _sim_running and _alive_enemies() == 0:
		_finish_simulation()

# ----------------------------------------------------------- avaliação ------
func _build_evaluation_ui() -> void:
	_eval_layer = CanvasLayer.new()
	_eval_layer.layer = 22
	_eval_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_eval_layer)
	_eval_panel = PanelContainer.new()
	_eval_panel.anchor_left = 0.5
	_eval_panel.anchor_right = 0.5
	_eval_panel.anchor_top = 0.5
	_eval_panel.anchor_bottom = 0.5
	_eval_panel.offset_left = -300.0
	_eval_panel.offset_right = 300.0
	_eval_panel.offset_top = -310.0
	_eval_panel.offset_bottom = 310.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.98, 0.97)
	style.border_color = Color(0.6, 0.6, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 18.0
	style.content_margin_bottom = 18.0
	_eval_panel.add_theme_stylebox_override("panel", style)
	_eval_panel.visible = false
	_eval_layer.add_child(_eval_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_eval_panel.add_child(vbox)
	_eval_number = Label.new()
	_eval_number.text = "AVALIAÇÃO DO SISTEMA"
	_eval_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eval_number.add_theme_font_size_override("font_size", 21)
	_eval_number.add_theme_color_override("font_color", Color(0.16, 0.16, 0.22))
	vbox.add_child(_eval_number)
	_eval_stats = Label.new()
	_eval_stats.add_theme_font_size_override("font_size", 14)
	_eval_stats.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3))
	_eval_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_eval_stats)
	_eval_bonus = Label.new()
	_eval_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eval_bonus.add_theme_font_size_override("font_size", 14)
	_eval_bonus.add_theme_color_override("font_color", Color(0.1, 0.35, 0.4))
	vbox.add_child(_eval_bonus)
	_eval_history = Label.new()
	_eval_history.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eval_history.add_theme_font_size_override("font_size", 11)
	_eval_history.add_theme_color_override("font_color", Color(0.42, 0.42, 0.48))
	vbox.add_child(_eval_history)
	var continue_btn := Button.new()
	continue_btn.text = "Voltar a treinar"
	continue_btn.custom_minimum_size = Vector2(0, 34)
	continue_btn.pressed.connect(_close_evaluation)
	vbox.add_child(continue_btn)
	var sim_btn := Button.new()
	sim_btn.text = "Nova simulação…"
	sim_btn.custom_minimum_size = Vector2(0, 34)
	sim_btn.pressed.connect(_open_setup_from_eval)
	vbox.add_child(sim_btn)
	var leave_btn := Button.new()
	leave_btn.text = "Regressar ao Vale"
	leave_btn.custom_minimum_size = Vector2(0, 34)
	leave_btn.pressed.connect(_return_to_vale)
	vbox.add_child(leave_btn)

func _open_setup_from_eval() -> void:
	_eval_panel.visible = false
	open_setup()

func _style_label(light_hits: int, heavy_hits: int, parries: int) -> String:
	var total := light_hits + heavy_hits
	if parries >= 4:
		return "Artista do Parry"
	if total >= 6 and float(heavy_hits) / float(total) >= 0.55:
		return "Colosso de Guerra"
	if total >= 6 and float(light_hits) / float(total) >= 0.7:
		return "Dança de Lâminas"
	return "Gladiador do Vazio"

func _verdict_line(accuracy: float, errors: int) -> String:
	if accuracy >= 0.75 and errors <= 1:
		return "Desempenho... aceitável para uma anomalia sem magia."
	elif accuracy >= 0.5:
		return "Mediano. Os Núcleos não aplaudem — mas eu não sou os Núcleos."
	return "Notas: melhorar. Tudo. E depressa."

func _finish_simulation() -> void:
	_sim_running = false
	var swings: int = int(_player.get("total_swings"))
	var hits: int = int(_player.get("total_hits"))
	var damage: float = float(_player.get("total_damage_taken"))
	var parries: int = int(_player.get("total_parries"))
	var errors: int = int(_player.get("hits_taken_attacking"))
	var light_hits: int = int(_player.get("light_hits"))
	var heavy_hits: int = int(_player.get("heavy_hits"))
	var first_hit: int = int(_player.get("first_hit_msec"))
	var accuracy := float(hits) / float(maxi(1, swings))
	var style := _style_label(light_hits, heavy_hits, parries)
	var reaction := "—"
	if first_hit >= 0:
		reaction = "%.1fs" % (float(first_hit - _sim_start_msec) / 1000.0)
	var minutes := int(_sim_time) / 60
	var seconds := int(_sim_time) % 60
	# Recompensa por ameaça
	var reward := int(60.0 * GameState.threat_reward_mult())
	GameState.add_xp(reward)
	# O Sistema observa — a Academia reconhece, a Irmandade sorri
	GameState.add_reputation("academia", 2)
	GameState.add_reputation("irmandade", 1)
	# Bónus de avaliação (regra v0.1 mantida)
	var bonus_text := ""
	if GameState.evaluations_used >= 5:
		bonus_text = "Bónus do Sistema esgotado (5/5).\nQue bom… ou que medíocre, dependendo da perspetiva."
	elif hits >= 10 and accuracy >= 0.5:
		GameState.attribute_points += 1
		GameState.evaluations_used += 1
		bonus_text = "BÓNUS: +1 ponto de atributo. [%d/5]" % GameState.evaluations_used
	else:
		bonus_text = "Bónus: precisas de ≥10 acertos e ≥50%% precisão."
	# Memória do Sistema
	var mem: Dictionary = GameState.system_memory
	var prev_best := String(mem.get("best_style", ""))
	mem["evaluations"] = int(mem.get("evaluations", 0)) + 1
	if prev_best == "" or accuracy >= 0.6:
		mem["best_style"] = style
	GameState.system_memory = mem
	# Histórico (últimas 5)
	var entry := {
		"env": _env_name(), "threat": GameState.threat_name(),
		"accuracy": int(accuracy * 100.0), "style": style, "reward": reward,
	}
	var history: Array = GameState.evaluation_history.duplicate()
	history.append(entry)
	while history.size() > 5:
		history.pop_front()
	GameState.evaluation_history = history
	GameState.stats_changed.emit()
	# Preencher painel
	_eval_number.text = "AVALIAÇÃO Nº %d" % int(mem["evaluations"])
	_eval_stats.text = "Ambiente: %s · Ameaça: %s\nTempo de simulação: %02d:%02d\nGolpes: %d · Acertos: %d · Precisão: %d%%\nParries perfeitos: %d\nPrimeiro impacto: %s\nErros repetidos (atingido a atacar): %d\nDano sofrido: %d\nEstilo dominante: %s\nRecompensa: +%d XP" % [
		_env_name(), GameState.threat_name(), minutes, seconds, swings, hits,
		int(accuracy * 100.0), parries, reaction, errors, int(damage), style, reward,
	]
	var memory_text := "«%s»" % _verdict_line(accuracy, errors)
	if int(mem.get("refusals", 0)) > 0:
		memory_text += "\nRecusas anteriores: %d. A prudência é um músculo — o teu ainda é fraco." % int(mem["refusals"])
	if prev_best != "" and prev_best != style:
		memory_text += "\nAntes: %s. Agora: %s. O Sistema regista." % [prev_best, style]
	_eval_bonus.text = memory_text + "\n" + bonus_text
	var hist_lines: Array[String] = []
	for h in history:
		hist_lines.append("· %s · %s · %d%% precisão · %s" % [String(h.get("threat", "?")), String(h.get("env", "?")), int(h.get("accuracy", 0)), String(h.get("style", "?"))])
	_eval_history.text = "Histórico:\n" + "\n".join(hist_lines)
	_eval_panel.visible = true
	UI.external_block = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_evaluation() -> void:
	_eval_panel.visible = false
	UI.external_block = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_respawn_dummies()

func _return_to_vale() -> void:
	GameState.system_return_pending = true
	_eval_panel.visible = false
	_setup_panel.visible = false
	UI.external_block = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
