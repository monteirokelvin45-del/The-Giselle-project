extends Node3D
## O Sistema — Sala Branca (v0.1).
## Um lugar que não existe, onde Kael aprende o que lhe esconderam.

var _player: Node3D = null
var _time: float = 0.0
var _subtitle_label: Label
var _subtitle_layer: CanvasLayer
var _subtitle_index: int = 0
var _subtitle_timer: float = 0.8
var _eval_layer: CanvasLayer
var _eval_panel: PanelContainer
var _eval_stats: Label
var _eval_bonus: Label
var _eval_number: Label

const SUBTITLES := [
	"Bem-vindo, Kael Noro.",
	"Sem Núcleo Arcano. Sem emissão. Sem registo.",
	"Ambiente: Treino Básico. Armamento: físico.",
	"Tu és a exceção... e as exceções são interessantes.",
]

func _ready() -> void:
	_build_environment()
	_build_room()
	_spawn_dummies()
	_spawn_portal()
	var player_scene := preload("res://scenes/player.tscn")
	var player := player_scene.instantiate()
	player.position = Vector3(0.0, 1.3, 5.0)
	add_child(player)
	_player = player
	player.hp = GameState.max_hp()
	player.stamina = GameState.max_stamina()
	if player.has_method("reset_combat_stats"):
		player.reset_combat_stats()
	UI.set_in_game(true)
	_build_subtitles()
	_build_evaluation_ui()

func _build_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.96, 0.96, 0.98)
	env.fog_enabled = true
	env.fog_density = 0.028
	env.fog_light_color = Color(0.97, 0.97, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.9, 0.9, 0.96)
	env.ambient_light_energy = 1.15
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	sun.light_energy = 0.9
	sun.light_color = Color(1.0, 1.0, 1.0)
	add_child(sun)

func _build_room() -> void:
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.93, 0.93, 0.96)
	floor_mat.roughness = 0.32
	floor_mat.metallic = 0.08
	var floor_body := StaticBody3D.new()
	var floor_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 90.0
	cyl.bottom_radius = 90.0
	cyl.height = 0.4
	floor_mesh.mesh = cyl
	floor_mesh.material_override = floor_mat
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
	# Pilares brancos distantes (profundidade antes do vazio)
	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.85, 0.85, 0.9)
	pillar_mat.roughness = 0.5
	for i in range(6):
		var angle := TAU * float(i) / 6.0 + 0.4
		var pillar := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 2.6
		pm.bottom_radius = 3.1
		pm.height = 42.0
		pillar.mesh = pm
		pillar.material_override = pillar_mat
		pillar.position = Vector3(cos(angle) * 34.0, 21.0, sin(angle) * 34.0)
		add_child(pillar)

func _spawn_dummies() -> void:
	var dummy_script := preload("res://src/system/dummy.gd")
	for pos in [Vector3(-6.0, 0.0, -3.0), Vector3(0.0, 0.0, -8.0), Vector3(6.0, 0.0, -3.0)]:
		var dummy := Node3D.new()
		dummy.set_script(dummy_script)
		dummy.position = pos
		add_child(dummy)

func _spawn_portal() -> void:
	var portal_scene := preload("res://scenes/exit_portal.tscn")
	var portal := portal_scene.instantiate()
	portal.position = Vector3(0.0, 1.7, -13.5)
	add_child(portal)

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
	_subtitle_label.add_theme_font_size_override("font_size", 19)
	_subtitle_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.2))
	_subtitle_label.visible = false
	_subtitle_layer.add_child(_subtitle_label)

func _process(delta: float) -> void:
	if _subtitle_index >= SUBTITLES.size():
		_time += delta
	# Legendas dramáticas de entrada
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
	_eval_panel.offset_left = -280.0
	_eval_panel.offset_right = 280.0
	_eval_panel.offset_top = -230.0
	_eval_panel.offset_bottom = 230.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.95, 0.98, 0.97)
	style.border_color = Color(0.6, 0.6, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 24.0
	style.content_margin_right = 24.0
	style.content_margin_top = 20.0
	style.content_margin_bottom = 20.0
	_eval_panel.add_theme_stylebox_override("panel", style)
	_eval_panel.visible = false
	_eval_layer.add_child(_eval_panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_eval_panel.add_child(vbox)
	_eval_number = Label.new()
	_eval_number.text = "AVALIAÇÃO DO SISTEMA"
	_eval_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_eval_number.add_theme_font_size_override("font_size", 21)
	_eval_number.add_theme_color_override("font_color", Color(0.16, 0.16, 0.22))
	vbox.add_child(_eval_number)
	_eval_stats = Label.new()
	_eval_stats.add_theme_font_size_override("font_size", 16)
	_eval_stats.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3))
	_eval_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_eval_stats)
	_eval_bonus = Label.new()
	_eval_bonus.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_eval_bonus.add_theme_font_size_override("font_size", 15)
	_eval_bonus.add_theme_color_override("font_color", Color(0.1, 0.35, 0.4))
	vbox.add_child(_eval_bonus)
	var continue_btn := Button.new()
	continue_btn.text = "Continuar a treinar"
	continue_btn.custom_minimum_size = Vector2(0, 36)
	continue_btn.pressed.connect(_close_evaluation)
	vbox.add_child(continue_btn)
	var leave_btn := Button.new()
	leave_btn.text = "Regressar ao Vale"
	leave_btn.custom_minimum_size = Vector2(0, 36)
	leave_btn.pressed.connect(_return_to_vale)
	vbox.add_child(leave_btn)

func open_evaluation() -> void:
	if _player == null:
		return
	var swings: int = int(_player.get("total_swings"))
	var hits: int = int(_player.get("total_hits"))
	var damage: float = float(_player.get("total_damage_taken"))
	var accuracy := float(hits) / float(maxi(1, swings))
	var minutes := int(_time) / 60
	var seconds := int(_time) % 60
	_eval_number.text = "AVALIAÇÃO Nº %d" % (GameState.evaluations_used + 1)
	_eval_stats.text = "Tempo de simulação: %02d:%02d\nGolpes desferidos: %d\nGolpes acertados: %d\nPrecisão: %d%%\nDano sofrido: %d" % [minutes, seconds, swings, hits, int(accuracy * 100.0), int(damage)]
	if GameState.evaluations_used >= 5:
		_eval_bonus.text = "Bónus do Sistema esgotado (5/5).\nQue bom… ou que medíocre, dependendo da perspetiva."
	elif hits >= 10 and accuracy >= 0.5:
		GameState.attribute_points += 1
		GameState.evaluations_used += 1
		GameState.stats_changed.emit()
		_eval_bonus.text = "ANÁLISE COMPLETA.\nForça, velocidade, reflexos… melhorias mínimas registadas.\nBÓNUS: +1 ponto de atributo (Esc → Atributos). [%d/5]" % GameState.evaluations_used
	else:
		_eval_bonus.text = "ANÁLISE INCONCLUSIVA.\nPara o bónus do Sistema: pelo menos 10 acertos com precisão de 50%% ou mais."
	_eval_panel.visible = true
	UI.external_block = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_evaluation() -> void:
	_eval_panel.visible = false
	UI.external_block = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _return_to_vale() -> void:
	GameState.system_return_pending = true
	_eval_panel.visible = false
	UI.external_block = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")
