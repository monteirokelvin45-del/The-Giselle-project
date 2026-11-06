extends CanvasLayer
## Controlos táteis para Android — autoload "Touch".
## Joystick virtual dinâmico à esquerda, câmara por arrastamento à direita e
## botões de ação à direita. Alimenta o jogador diretamente (move_vector /
## consume_look) e injeta os botões no pipeline de input normal via InputEventAction
## (por isso o código do jogador/UI não precisa de caminho especial para toques).
##
## Visível apenas em cenas de jogo (Main / SalaBranca), sem diálogos/menus abertos
## e em Android (ou com FORCE_TOUCH=true para testar no PC).

const FORCE_TOUCH := false
const JOY_RADIUS := 78.0
const JOY_DEADZONE := 0.14

var move_vector := Vector2.ZERO
var _look_delta := Vector2.ZERO
var _joy_index: int = -1
var _joy_origin := Vector2.ZERO
var _cam_index: int = -1
var _cam_last := Vector2.ZERO

var _root: Control
var _joy_base: Panel
var _joy_knob: Panel
var _ability_buttons: Array[Button] = []
var _ability_refresh: float = 0.0

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS  # controla a visibilidade mesmo pausado
	_build_ui()
	set_process(true)

func _process(delta: float) -> void:
	var show := _should_show()
	if visible != show:
		visible = show
		if not show:
			move_vector = Vector2.ZERO
			_joy_index = -1
			_cam_index = -1
			_hide_joystick()
	_ability_refresh += delta
	if _ability_refresh >= 0.5:
		_ability_refresh = 0.0
		_refresh_ability_buttons()

func consume_look() -> Vector2:
	var d: Vector2 = _look_delta
	_look_delta = Vector2.ZERO
	return d

# ------------------------------------------------------------ visibilidade --
func _should_show() -> bool:
	if not FORCE_TOUCH and not (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")):
		return false
	var cs := get_tree().current_scene
	if cs == null:
		return false
	if cs.name != "Main" and cs.name != "SalaBranca" and cs.name != "Academia" and cs.name != "Region":
		return false
	var ui := get_node_or_null("/root/UI")
	if ui:
		for flag in ["pause_open", "attributes_open", "controls_open", "decision_open", "ending_open", "external_block", "map_open", "factions_open"]:
			if bool(ui.get(flag)):
				return false
	var dlg := get_node_or_null("/root/Dialogue")
	if dlg and bool(dlg.get("active")):
		return false
	return true

# ----------------------------------------------------------------- input ----
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var vis_size := get_viewport().get_visible_rect().size
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			if p.x < vis_size.x * 0.45 and _joy_index == -1:
				_joy_index = event.index
				_joy_origin = p
				move_vector = Vector2.ZERO
				_update_joystick(p)
			else:
				_cam_index = event.index
				_cam_last = p
			get_viewport().set_input_as_handled()
		elif event.index == _joy_index:
			_joy_index = -1
			move_vector = Vector2.ZERO
			_hide_joystick()
		elif event.index == _cam_index:
			_cam_index = -1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var p: Vector2 = event.position
		if event.index == _joy_index:
			var d: Vector2 = p - _joy_origin
			var dl := d.length()
			if dl > JOY_RADIUS:
				d = d.normalized() * JOY_RADIUS
			var raw := d / JOY_RADIUS
			move_vector = raw if raw.length() > JOY_DEADZONE else Vector2.ZERO
			_update_joystick(_joy_origin + d)
			get_viewport().set_input_as_handled()
		elif event.index == _cam_index:
			_look_delta += p - _cam_last
			_cam_last = p
			get_viewport().set_input_as_handled()

func _update_joystick(knob_pos: Vector2) -> void:
	_joy_base.visible = true
	_joy_knob.visible = true
	_joy_base.position = _joy_origin - Vector2.ONE * JOY_RADIUS
	_joy_knob.position = knob_pos - Vector2.ONE * (JOY_RADIUS * 0.55)

func _hide_joystick() -> void:
	if _joy_base:
		_joy_base.visible = false
	if _joy_knob:
		_joy_knob.visible = false

# ------------------------------------------------------------------ UI ------
func _make_circle(diameter: float, bg: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.size = Vector2.ONE * diameter
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = int(diameter * 0.5)
	style.corner_radius_top_right = int(diameter * 0.5)
	style.corner_radius_bottom_left = int(diameter * 0.5)
	style.corner_radius_bottom_right = int(diameter * 0.5)
	panel.add_theme_stylebox_override("panel", style)
	_root.add_child(panel)
	return panel

func _make_button(action: String, label: String, margin_right: float, top: float, size: float, _hold: bool, font_size: int) -> void:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_right = -margin_right
	btn.offset_left = -margin_right - size
	btn.offset_top = top
	btn.offset_bottom = top + size
	var radius := int(size * 0.5)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.075, 0.09, 0.55)
	normal.border_color = Color(0.85, 0.72, 0.4, 0.85)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = radius
	normal.corner_radius_top_right = radius
	normal.corner_radius_bottom_left = radius
	normal.corner_radius_bottom_right = radius
	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.85, 0.72, 0.4, 0.85)
	var font_color := Color(0.97, 0.9, 0.65)
	var font_pressed := Color(0.12, 0.1, 0.05)
	for state in ["normal", "hover", "focus"]:
		btn.add_theme_stylebox_override(state, normal)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_color_override("font_color", font_color)
	btn.add_theme_color_override("font_pressed_color", font_pressed)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.button_down.connect(func(): _inject(action, true))
	btn.button_up.connect(func(): _inject(action, false))
	_root.add_child(btn)

## Botões 1–4 das habilidades dos companheiros, topo-esquerda.
func _make_ability_button(action: String, label: String, left: float, top: float, size: float) -> void:
	var btn := Button.new()
	btn.text = label
	btn.focus_mode = Control.FOCUS_NONE
	btn.anchor_left = 0.0
	btn.anchor_right = 0.0
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.offset_left = left
	btn.offset_right = left + size
	btn.offset_top = top
	btn.offset_bottom = top + size
	var radius := int(size * 0.5)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.075, 0.09, 0.55)
	normal.border_color = Color(0.62, 0.78, 0.9, 0.85)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = radius
	normal.corner_radius_top_right = radius
	normal.corner_radius_bottom_left = radius
	normal.corner_radius_bottom_right = radius
	var pressed_style := normal.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.62, 0.78, 0.9, 0.9)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", normal)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("pressed", pressed_style)
	btn.add_theme_color_override("font_color", Color(0.82, 0.92, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.05, 0.1, 0.15))
	btn.add_theme_font_size_override("font_size", 17)
	btn.button_down.connect(func(): _inject(action, true))
	btn.button_up.connect(func(): _inject(action, false))
	_root.add_child(btn)
	_ability_buttons.append(btn)

func _refresh_ability_buttons() -> void:
	if _ability_buttons.size() != 4:
		return
	var ids := ["liora", "bram", "sena", "iven"]
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	var companions = gs.get("companions")
	for i in range(4):
		var btn: Button = _ability_buttons[i]
		btn.modulate.a = 1.0 if (companions is Dictionary and companions.has(ids[i])) else 0.3

func _inject(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_joy_base = _make_circle(JOY_RADIUS * 2.0, Color(0.1, 0.095, 0.11, 0.35), Color(0.85, 0.72, 0.4, 0.7))
	_joy_base.visible = false
	_joy_knob = _make_circle(JOY_RADIUS * 1.1, Color(0.85, 0.72, 0.4, 0.9), Color(0.97, 0.93, 0.75, 0.9))
	_joy_knob.visible = false
	# Faixa superior direita
	_make_button("pause", "II", 18.0, 14.0, 52.0, false, 20)
	_make_button("rupture", "RUPT", 20.0, 82.0, 74.0, false, 18)
	_make_button("lock_on", "ALVO", 22.0, 172.0, 70.0, false, 15)
	_make_button("potion", "POT", 20.0, 258.0, 68.0, false, 18)
	# Cluster principal de ação
	_make_button("interact", "E", 116.0, 262.0, 78.0, false, 24)
	_make_button("dodge", "ESQV", 124.0, 356.0, 84.0, false, 18)
	_make_button("attack_light", "LEVE", 108.0, 436.0, 112.0, false, 22)
	_make_button("attack_heavy", "FORTE", 240.0, 520.0, 90.0, false, 17)
	_make_button("block", "BLOQ", 240.0, 414.0, 86.0, true, 17)
	# Habilidades dos companheiros (só úteis quando recrutados)
	_make_ability_button("ability_1", "1", 16.0, 14.0, 46.0)
	_make_ability_button("ability_2", "2", 70.0, 14.0, 46.0)
	_make_ability_button("ability_3", "3", 124.0, 14.0, 46.0)
	_make_ability_button("ability_4", "4", 178.0, 14.0, 46.0)
