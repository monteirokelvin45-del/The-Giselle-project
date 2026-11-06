extends Node
## Regista as ações de input em tempo de arranque.
## (Evita o formato propenso a erros do [input] no project.godot e garante
## teclas consistentes em qualquer máquina.)

func _ready() -> void:
	# Teclado / rato (acesso primário)
	_register("move_forward", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0)])
	_register("move_back", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0)])
	_register("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_register("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_register("dodge", [_key(KEY_SPACE), _joy(JOY_BUTTON_A)])
	_register("sprint", [_key(KEY_SHIFT), _joy(JOY_BUTTON_LEFT_STICK)])
	_register("block", [_key(KEY_Q), _joy(JOY_BUTTON_SHOULDER_LEFT)])
	_register("interact", [_key(KEY_E), _joy(JOY_BUTTON_B)])
	_register("rupture", [_key(KEY_F), _joy(JOY_BUTTON_SHOULDER_RIGHT)])
	_register("potion", [_key(KEY_R), _joy(JOY_BUTTON_DPAD_DOWN)])
	_register("lock_on", [_key(KEY_TAB), _joy(JOY_BUTTON_RIGHT_STICK)])
	_register("pause", [_key(KEY_ESCAPE), _joy(JOY_BUTTON_START)])
	_register("attack_light", [_mouse(MOUSE_BUTTON_LEFT), _joy(JOY_BUTTON_X)])
	_register("attack_heavy", [_mouse(MOUSE_BUTTON_RIGHT), _joy(JOY_BUTTON_Y)])

func _key(k: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = k
	return ev

func _mouse(b: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = b
	return ev

func _joy(b: JoyButton) -> InputEventJoypadButton:
	var ev := InputEventJoypadButton.new()
	ev.button_index = b
	return ev

func _axis(a: JoyAxis, value: float) -> InputEventJoypadMotion:
	var ev := InputEventJoypadMotion.new()
	ev.axis = a
	ev.axis_value = value
	return ev

func _register(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for ev in events:
		InputMap.action_add_event(action, ev)
