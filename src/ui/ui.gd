extends Node
## Frente-de-caixa completa: HUD, notificações, menu de pausa, atributos,
## controlos, a Decisão final e os créditos. Autoload "UI".

var in_game := false
var pause_open := false
var attributes_open := false
var controls_open := false
var decision_open := false
var ending_open := false
var external_block := false

var _layer: CanvasLayer
var _hud: Control
var _pause_overlay: Control
var _attributes_overlay: Control
var _controls_overlay: Control
var _decision_overlay: Control
var _ending_overlay: Control

# HUD
var _level_label: Label
var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _stamina_bar: ProgressBar
var _rupture_bar: ProgressBar
var _marcos_label: Label
var _potions_label: Label
var _objective_label: Label
var _side_box: VBoxContainer
var _enemy_name_label: Label
var _posture_bar: ProgressBar
var _posture_box: VBoxContainer
var _prompt_label: Label
var _rupture_ready: Label
var _crosshair: ColorRect
var _controls_hint: Label
var _notif_label: Label

var _notif_queue: Array[String] = []
var _notif_time := 0.0
var _time := 0.0
var _player_cache: Node3D = null

const ENDINGS := {
	"academia": {
		"title": "O Reformado",
		"choice": "«Tomo o lugar na Academia Real de Veyra.»",
		"desc": "Mudar o sistema de dentro para fora.",
		"text": "Kael Noro atravessa os portões de Veyra ao amanhecer, com a Corrente de Âncora à cintura e o Sistema em silêncio.\n\nMudar um mundo que adora o Núcleo Arcano não será obra de um dia, nem de um ano. Será obra de uma vida: um currículo aberto aos sem-magia, um arquivo proibido a ser revelado, sala a sala, professor a professor.\n\nA Academia não esqueceu o Vazio. O Vazio, agora, faz parte dela.",
	},
	"vagabundo": {
		"title": "O Herói Errante",
		"choice": "«Recuso cargos. A estrada é minha.»",
		"desc": "Nem rei, nem governador, nem diretor.",
		"text": "Kael Noro sorri perante as propostas — e recusa-as.\n\nSoldados procuram-no. Aldeias inteiras falam dele em voz baixa: o homem que derrubou o Guardião da Prova com as próprias mãos. A estrada abre-se como um livro que ninguém escreveu ainda.\n\nHá sempre uma ponte a cair, uma aldeia esquecida, um monstro na montanha. E há sempre um rapaz sem magia a chegar.",
	},
	"revolta": {
		"title": "A Chama dos Sem-Núcleo",
		"choice": "«A igualdade não se pede. Constrói-se.»",
		"desc": "Liderar os que foram esquecidos pelo mundo.",
		"text": "Quando Kael levanta a voz na zona dos Sem-Núcleo, ninguém pede silêncio.\n\nNão há Núcleo nesta sala. Há mãos abertas, ferramentas em riste, filhos de curandeiras e forjados pelos ribeiros de Noro. Se a magia construiu um mundo de portas fechadas, então eles serão a chave — ou a porta deitada abaixo.\n\nO Sistema observa em silêncio. Pela primeira vez, parece... curioso.",
	},
}

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 15
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_build_hud()
	_build_pause()
	_build_attributes()
	_build_controls()
	_build_decision()
	_build_ending()
	GameState.notify.connect(notify)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.stats_changed.connect(_refresh_stats)

func is_blocking() -> bool:
	return pause_open or attributes_open or controls_open or decision_open or ending_open or external_block

func set_in_game(value: bool) -> void:
	in_game = value
	_hud.visible = value
	_crosshair.visible = value
	if value:
		_refresh_stats()
		_objective_label.text = GameState.objective_text()
		_rebuild_side_objectives()
	else:
		_close_all_overlays()
		get_tree().paused = false

func notify(text: String) -> void:
	_notif_queue.append(text)
	if _notif_queue.size() > 4:
		_notif_queue.pop_front()

# ------------------------------------------------------------------ HUD -----
func _make_bar(width: float, height: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.max_value = 100.0
	bar.min_value = 0.0
	bar.value = 100.0
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.06, 0.75)
	bg.corner_radius_top_left = int(height * 0.5)
	bg.corner_radius_bottom_left = int(height * 0.5)
	bg.corner_radius_top_right = int(height * 0.5)
	bg.corner_radius_bottom_right = int(height * 0.5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.corner_radius_top_left = bg.corner_radius_top_left
	fg.corner_radius_bottom_left = bg.corner_radius_bottom_left
	fg.corner_radius_top_right = bg.corner_radius_top_right
	fg.corner_radius_bottom_right = bg.corner_radius_bottom_right
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

func _build_hud() -> void:
	_hud = Control.new()
	_hud.anchor_right = 1.0
	_hud.anchor_bottom = 1.0
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	_layer.add_child(_hud)

	# Bloco superior esquerdo
	var left := MarginContainer.new()
	left.position = Vector2(18, 16)
	_hud.add_child(left)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	left.add_child(vbox)
	_level_label = _make_label("Nv 1", 15, Color(0.95, 0.87, 0.6))
	vbox.add_child(_level_label)
	_xp_bar = _make_bar(230, 5, Color(0.85, 0.68, 0.25))
	vbox.add_child(_xp_bar)
	_hp_bar = _make_bar(230, 16, Color(0.82, 0.25, 0.25))
	vbox.add_child(_hp_bar)
	_stamina_bar = _make_bar(230, 11, Color(0.42, 0.78, 0.38))
	vbox.add_child(_stamina_bar)
	_rupture_bar = _make_bar(230, 9, Color(0.95, 0.62, 0.15))
	vbox.add_child(_rupture_bar)
	_marcos_label = _make_label("◈ 75 marcos", 13, Color(0.9, 0.78, 0.35))
	vbox.add_child(_marcos_label)
	_potions_label = _make_label("Poções: 2  (R)", 13, Color(0.62, 0.82, 0.95))
	vbox.add_child(_potions_label)

	# Painel de objetivo (superior direito)
	var obj := PanelContainer.new()
	obj.anchor_left = 1.0
	obj.anchor_right = 1.0
	obj.offset_left = -356.0
	obj.offset_right = -16.0
	obj.offset_top = 16.0
	obj.custom_minimum_size = Vector2(340, 0)
	var obj_style := StyleBoxFlat.new()
	obj_style.bg_color = Color(0.08, 0.07, 0.06, 0.62)
	obj_style.corner_radius_top_left = 8
	obj_style.corner_radius_top_right = 8
	obj_style.corner_radius_bottom_left = 8
	obj_style.corner_radius_bottom_right = 8
	obj_style.set_content_margin_all(10.0)
	obj.add_theme_stylebox_override("panel", obj_style)
	_hud.add_child(obj)
	var obj_vbox := VBoxContainer.new()
	obj_vbox.add_theme_constant_override("separation", 4)
	obj.add_child(obj_vbox)
	var obj_title := _make_label("◈ OBJETIVO", 12, Color(0.87, 0.7, 0.3))
	obj_vbox.add_child(obj_title)
	_objective_label = _make_label("...", 14, Color(0.96, 0.94, 0.88))
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size = Vector2(310, 0)
	obj_vbox.add_child(_objective_label)
	_side_box = VBoxContainer.new()
	_side_box.add_theme_constant_override("separation", 2)
	obj_vbox.add_child(_side_box)

	# Prompt de interação (fundo centro)
	_prompt_label = _make_label("", 17, Color(0.98, 0.95, 0.8))
	_prompt_label.anchor_left = 0.5
	_prompt_label.anchor_right = 0.5
	_prompt_label.anchor_top = 1.0
	_prompt_label.anchor_bottom = 1.0
	_prompt_label.offset_left = -260.0
	_prompt_label.offset_right = 260.0
	_prompt_label.offset_top = -218.0
	_prompt_label.offset_bottom = -186.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_constant_override("outline_size", 6)
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_prompt_label.visible = false
	_hud.add_child(_prompt_label)

	# Bloco de postura do alvo (inferior centro)
	_posture_box = VBoxContainer.new()
	_posture_box.anchor_left = 0.5
	_posture_box.anchor_right = 0.5
	_posture_box.anchor_top = 1.0
	_posture_box.anchor_bottom = 1.0
	_posture_box.offset_left = -170.0
	_posture_box.offset_right = 170.0
	_posture_box.offset_top = -150.0
	_posture_box.offset_bottom = -120.0
	_posture_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_posture_box.visible = false
	_hud.add_child(_posture_box)
	_enemy_name_label = _make_label("Inimigo", 13, Color(0.95, 0.6, 0.4))
	_enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_posture_box.add_child(_enemy_name_label)
	_posture_bar = _make_bar(300, 10, Color(0.75, 0.55, 0.95))
	_posture_box.add_child(_posture_bar)

	# Aviso de Ruptura pronta
	_rupture_ready = _make_label("RUPTURA PRONTA — [F]", 19, Color(1.0, 0.75, 0.2))
	_rupture_ready.anchor_left = 0.5
	_rupture_ready.anchor_right = 0.5
	_rupture_ready.anchor_top = 1.0
	_rupture_ready.anchor_bottom = 1.0
	_rupture_ready.offset_left = -180.0
	_rupture_ready.offset_right = 180.0
	_rupture_ready.offset_top = -280.0
	_rupture_ready.offset_bottom = -248.0
	_rupture_ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rupture_ready.visible = false
	_hud.add_child(_rupture_ready)

	# Notificações (topo centro)
	_notif_label = _make_label("", 17, Color(0.98, 0.92, 0.7))
	_notif_label.anchor_left = 0.5
	_notif_label.anchor_right = 0.5
	_notif_label.anchor_top = 0.0
	_notif_label.anchor_bottom = 0.0
	_notif_label.offset_left = -370.0
	_notif_label.offset_right = 370.0
	_notif_label.offset_top = 84.0
	_notif_label.offset_bottom = 116.0
	_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_label.add_theme_constant_override("outline_size", 6)
	_notif_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_notif_label.modulate.a = 0.0
	_hud.add_child(_notif_label)

	# Mira (ponto central)
	_crosshair = ColorRect.new()
	_crosshair.color = Color(0.95, 0.93, 0.85, 0.9)
	_crosshair.anchor_left = 0.5
	_crosshair.anchor_right = 0.5
	_crosshair.anchor_top = 0.5
	_crosshair.anchor_bottom = 0.5
	_crosshair.offset_left = -2.5
	_crosshair.offset_right = 2.5
	_crosshair.offset_top = -2.5
	_crosshair.offset_bottom = 2.5
	_crosshair.visible = false
	_hud.add_child(_crosshair)

	# Dicas de controlos (inferior esquerdo)
	_controls_hint = _make_label("M1 ataque leve · M2 pesado · Espaço esquiva · Q bloquear/parry\nE interagir/Corrente · R poção · F Ruptura · Tab fixar · Esc menu", 11, Color(0.65, 0.66, 0.62, 0.9))
	_controls_hint.anchor_bottom = 1.0
	_controls_hint.anchor_top = 1.0
	_controls_hint.offset_left = 14.0
	_controls_hint.offset_top = -44.0
	_controls_hint.offset_bottom = -12.0
	_controls_hint.offset_right = 560.0
	_hud.add_child(_controls_hint)

func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _on_objective_changed(_text: String) -> void:
	_objective_label.text = GameState.objective_text()
	_rebuild_side_objectives()

func _rebuild_side_objectives() -> void:
	for child in _side_box.get_children():
		child.queue_free()
	for line in GameState.side_objectives():
		var l := _make_label("· " + line, 12, Color(0.72, 0.78, 0.65))
		_side_box.add_child(l)

func _refresh_stats() -> void:
	_level_label.text = "Nv %d  ·  %d/%d XP" % [GameState.level, GameState.xp, GameState.xp_needed()]
	_xp_bar.value = GameState.xp_progress() * 100.0
	_marcos_label.text = "◈ %d marcos" % GameState.marcos
	_potions_label.text = "Poções: %d  (R)" % GameState.potions
	_rebuild_side_objectives()

# ------------------------------------------------------------- processo -----
func _process(delta: float) -> void:
	_time += delta
	if _player_cache == null or not is_instance_valid(_player_cache):
		_player_cache = get_tree().get_first_node_in_group("player")
	if _player_cache != null and in_game:
		var p: Node3D = _player_cache
		var max_hp := GameState.max_hp()
		var max_st := GameState.max_stamina()
		_hp_bar.max_value = max_hp
		_hp_bar.value = clampf(float(p.get("hp")), 0.0, max_hp)
		_stamina_bar.max_value = max_st
		_stamina_bar.value = clampf(float(p.get("stamina")), 0.0, max_st)
		_rupture_bar.value = GameState.rupture
		_rupture_ready.visible = GameState.rupture >= 100.0
		if _rupture_ready.visible:
			_rupture_ready.modulate.a = 0.6 + 0.4 * sin(_time * 6.0)
		# Barra de postura do alvo fixado
		var locked: Node3D = p.get("locked_enemy")
		if locked != null and is_instance_valid(locked):
			_posture_box.visible = true
			_enemy_name_label.text = String(locked.get("display_name"))
			var max_posture := float(locked.get("max_posture"))
			if max_posture > 0.0:
				_posture_bar.value = clampf(float(locked.get("posture")) / max_posture * 100.0, 0.0, 100.0)
		else:
			_posture_box.visible = false
		# Prompt de interação
		var target: Node3D = p.get("current_interactable")
		if target != null and is_instance_valid(target) and target.has_method("get_prompt"):
			_prompt_label.text = target.get_prompt()
			_prompt_label.visible = not is_blocking() and not Dialogue.active
		else:
			_prompt_label.visible = false
	# Notificações
	if _notif_time > 0.0:
		_notif_time -= delta
		if _notif_time <= 0.35 and _notif_label.modulate.a > 0.0:
			_notif_label.modulate.a = clampf(_notif_time / 0.35, 0.0, 1.0)
		if _notif_time <= 0.0:
			_notif_label.modulate.a = 0.0
	elif not _notif_queue.is_empty():
		_notif_label.text = _notif_queue.pop_front()
		_notif_label.modulate.a = 1.0
		_notif_time = 2.8

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if ending_open or decision_open or external_block:
			return
		if attributes_open:
			_toggle_attributes(false)
			return
		if controls_open:
			_toggle_controls(false)
			return
		if Dialogue.active:
			return
		if pause_open:
			_close_pause()
		elif in_game:
			_open_pause()

# ---------------------------------------------------------------- pausa -----
func _build_pause() -> void:
	_pause_overlay = _make_dim_overlay()
	var panel := _make_panel(470, 560)
	_pause_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := _make_label("A ACADEMIA DO ZERO", 15, Color(0.87, 0.7, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := _make_label("— PAUSADO —", 24, Color(0.97, 0.95, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	vbox.add_child(_make_button("Continuar", _close_pause))
	vbox.add_child(_make_button("Atributos", func(): _toggle_attributes(true)))
	var system_btn := _make_button("Entrar no Sistema (Sala Branca)", _enter_system)
	system_btn.name = "SystemButton"
	vbox.add_child(system_btn)
	var decision_btn := _make_button("A DECISÃO", _open_decision)
	decision_btn.name = "DecisionButton"
	vbox.add_child(decision_btn)
	vbox.add_child(_make_button("Guardar Jogo", _save_game))
	var load_btn := _make_button("Carregar Jogo", _load_game)
	load_btn.name = "LoadButton"
	vbox.add_child(load_btn)
	vbox.add_child(_make_button("Controlos", func(): _toggle_controls(true)))
	vbox.add_child(_make_button("Sair para o Título", _quit_to_title))

func _make_dim_overlay() -> Control:
	var overlay := Control.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.62)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	overlay.add_child(dim)
	overlay.visible = false
	_layer.add_child(overlay)
	return overlay

func _make_panel(width: float, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.offset_top = -height * 0.5
	panel.offset_bottom = height * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.085, 0.1, 0.97)
	style.border_color = Color(0.72, 0.58, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	var m := 22.0
	style.content_margin_left = m
	style.content_margin_right = m
	style.content_margin_top = m
	style.content_margin_bottom = m
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.16, 0.15, 0.17, 1.0)
	normal.border_color = Color(0.35, 0.32, 0.3)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_left = 7
	normal.corner_radius_bottom_right = 7
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.22, 0.2, 1.0)
	hover.border_color = Color(0.82, 0.66, 0.3)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.3, 0.27, 0.22, 1.0)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(func(): Audio.play("click"); callback.call())
	return btn

func _open_pause() -> void:
	pause_open = true
	_pause_overlay.visible = true
	_refresh_pause_buttons()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_pause() -> void:
	pause_open = false
	_pause_overlay.visible = false
	get_tree().paused = false
	if in_game:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refresh_pause_buttons() -> void:
	var in_vale := get_tree().current_scene != null and get_tree().current_scene.name == "Main"
	var system_btn := _pause_overlay.find_child("SystemButton", true, false) as Button
	if system_btn:
		system_btn.visible = GameState.artifact_unlocked
		system_btn.disabled = not in_vale
		if GameState.artifact_unlocked and not in_vale:
			system_btn.text = "Sistema (disponível no Vale)"
		else:
			system_btn.text = "Entrar no Sistema (Sala Branca)"
	var decision_btn := _pause_overlay.find_child("DecisionButton", true, false) as Button
	if decision_btn:
		decision_btn.visible = GameState.main_stage >= 6
	var load_btn := _pause_overlay.find_child("LoadButton", true, false) as Button
	if load_btn:
		load_btn.disabled = not in_vale or not GameState.has_save()

func _save_game() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		notify("Sem jogador no mundo.")
		return
	if get_tree().current_scene == null or get_tree().current_scene.name != "Main":
		notify("Só podes guardar no Vale.")
		return
	GameState.save_game(player.global_position, float(player.get("hp")), float(player.get("stamina")))

func _load_game() -> void:
	if get_tree().current_scene == null or get_tree().current_scene.name != "Main":
		notify("Só podes carregar no Vale.")
		return
	if GameState.load_game():
		_close_pause()
		get_tree().reload_current_scene()

func _enter_system() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	GameState.system_return = player.global_position
	_close_pause()
	get_tree().change_scene_to_file("res://scenes/sala_branca.tscn")

func _quit_to_title() -> void:
	_close_all_overlays()
	set_in_game(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _close_all_overlays() -> void:
	pause_open = false
	attributes_open = false
	controls_open = false
	decision_open = false
	ending_open = false
	for overlay in [_pause_overlay, _attributes_overlay, _controls_overlay, _decision_overlay, _ending_overlay]:
		if overlay:
			overlay.visible = false

# ------------------------------------------------------------ atributos ------
var _attr_points_label: Label
var _attr_value_labels: Dictionary = {}

func _build_attributes() -> void:
	_attributes_overlay = _make_dim_overlay()
	var panel := _make_panel(640, 600)
	_attributes_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	_attr_points_label = _make_label("Atributos — 0 pontos", 20, Color(0.97, 0.9, 0.65))
	_attr_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_attr_points_label)
	for key in GameState.ATTR_KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := _make_label(String(GameState.ATTR_NAMES[key]), 15, Color(0.93, 0.92, 0.88))
		name_label.custom_minimum_size = Vector2(118, 0)
		row.add_child(name_label)
		var hint := _make_label(String(GameState.ATTR_HINTS[key]), 10, Color(0.55, 0.56, 0.52))
		hint.custom_minimum_size = Vector2(220, 0)
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(hint)
		var value_label := _make_label("1", 16, Color(0.9, 0.8, 0.45))
		value_label.custom_minimum_size = Vector2(34, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(value_label)
		_attr_value_labels[key] = value_label
		var add_btn := Button.new()
		add_btn.text = "+"
		add_btn.custom_minimum_size = Vector2(36, 28)
		add_btn.pressed.connect(func(): _add_attribute(key))
		row.add_child(add_btn)
		vbox.add_child(row)
	var note := _make_label("O teu maior talento é sobreviver. Mas talento sem treino é só sobrevivência.", 11, Color(0.5, 0.5, 0.47))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(note)
	vbox.add_child(_make_button("Voltar", func(): _toggle_attributes(false)))

func _add_attribute(key: String) -> void:
	if GameState.spend_attribute(key):
		_refresh_attribute_panel()
	else:
		notify("Sem pontos de atributo. Níveis e o Sistema dão pontos.")

func _toggle_attributes(open_it: bool) -> void:
	attributes_open = open_it
	_attributes_overlay.visible = open_it
	if open_it:
		_pause_overlay.visible = false
		_refresh_attribute_panel()
	elif pause_open:
		_pause_overlay.visible = true

func _refresh_attribute_panel() -> void:
	_attr_points_label.text = "Atributos — %d ponto(s) disponível(eis)" % GameState.attribute_points
	for key in GameState.ATTR_KEYS:
		(_attr_value_labels[key] as Label).text = str(int(GameState.attributes[key]))

# ------------------------------------------------------------ controlos -----
func _build_controls() -> void:
	_controls_overlay = _make_dim_overlay()
	var panel := _make_panel(560, 600)
	_controls_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	var title := _make_label("CONTROLOS", 22, Color(0.97, 0.9, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var lines := [
		"W / ↑ — Avançar          S / ↓ — Recuar",
		"A / ← — Esquerda          D / → — Direita",
		"Rato — Mover a câmara (clique para focar)",
		"M1 — Ataque leve (combo de 3)",
		"M2 — Ataque pesado",
		"Espaço — Esquiva (curta invulnerabilidade)",
		"Shift — Correr (gasta fôlego)",
		"Q (segurar) — Bloquear",
		"Q (no instante) — Parry perfeito",
		"E — Interagir / Corrente de Âncora",
		"R — Beber poção (+45 vida)",
		"F — Estado de Ruptura (quando a barra está cheia)",
		"Tab — Fixar / largar inimigo",
		"Esc — Menu de pausa",
	]
	for line in lines:
		var l := _make_label(line, 14, Color(0.88, 0.87, 0.83))
		vbox.add_child(l)
	var lore := _make_label("«A ausência de magia é a arma mais antiga do mundo.»", 12, Color(0.6, 0.58, 0.5))
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(lore)
	vbox.add_child(_make_button("Voltar", func(): _toggle_controls(false)))

func _toggle_controls(open_it: bool) -> void:
	controls_open = open_it
	_controls_overlay.visible = open_it
	if open_it:
		_pause_overlay.visible = false
	elif pause_open:
		_pause_overlay.visible = true

# ------------------------------------------------------------- decisão ------
var _ending_title: Label
var _ending_text: Label
var _credits_label: Label

func _build_decision() -> void:
	_decision_overlay = _make_dim_overlay()
	var panel := _make_panel(680, 560)
	_decision_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := _make_label("A DECISÃO", 30, Color(0.97, 0.82, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var story := _make_label("O Guardião da Prova jaz aos teus pés. Os portões de Veyra estão abertos — e todas as portas do mundo também. O que fazes agora com a força que construíste?", 14, Color(0.85, 0.84, 0.8))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(story)
	for key in ["academia", "vagabundo", "revolta"]:
		var ending: Dictionary = ENDINGS[key]
		var btn := _make_button(String(ending["choice"]) + "\n" + String(ending["desc"]), _choose_ending.bind(key))
		btn.custom_minimum_size = Vector2(0, 64)
		vbox.add_child(btn)

func _open_decision() -> void:
	decision_open = true
	_pause_overlay.visible = false
	_decision_overlay.visible = true

func _choose_ending(key: String) -> void:
	GameState.ending = key
	GameState.main_stage = 7
	decision_open = false
	_decision_overlay.visible = false
	ending_open = true
	var ending: Dictionary = ENDINGS[key]
	_ending_title.text = String(ending["title"])
	_ending_text.text = String(ending["text"])
	_credits_label.text = _build_credits_text()
	_ending_overlay.visible = true

func _build_ending() -> void:
	_ending_overlay = _make_dim_overlay()
	var panel := _make_panel(700, 620)
	_ending_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	_ending_title = _make_label("", 26, Color(0.97, 0.82, 0.3))
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_ending_title)
	_ending_text = _make_label("", 15, Color(0.9, 0.89, 0.85))
	_ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_ending_text)
	_credits_label = _make_label("", 12, Color(0.58, 0.58, 0.55))
	_credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_credits_label)
	vbox.add_child(_make_button("Voltar ao Título", func(): _quit_to_title()))

func _build_credits_text() -> String:
	GameState.objective_changed.emit("")
	return "A ACADEMIA DO ZERO — vertical slice\nKael Noro, o rapaz sem Núcleo\nVladimir, o Guardião da Prova\nElen Noro · Garr · Tomás · Liora Venn · Mestre Dario Vale\n\nO mundo de Arkanor continua. Tu também.\nObrigado por jogar.\n\nNv %d · %d marcos · %d XP totais" % [GameState.level, GameState.marcos, GameState.xp]
