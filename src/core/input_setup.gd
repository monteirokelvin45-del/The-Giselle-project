extends Node
## Regista as ações de input em tempo de arranque.
## (Evita o formato propenso a erros do [input] no project.godot e garante
## teclas consistentes em qualquer máquina.)

func _ready() -> void:
	_register("move_forward", [_key(KEY_W), _key(KEY_UP)])
	_register("move_back", [_key(KEY_S), _key(KEY_DOWN)])
	_register("move_left", [_key(KEY_A), _key(KEY_LEFT)])
	_register("move_right", [_key(KEY_D), _key(KEY_RIGHT)])
	_register("dodge", [_key(KEY_SPACE)])
	_register("sprint", [_key(KEY_SHIFT)])
	_register("block", [_key(KEY_Q)])
	_register("interact", [_key(KEY_E)])
	_register("rupture", [_key(KEY_F)])
	_register("potion", [_key(KEY_R)])
	_register("lock_on", [_key(KEY_TAB)])
	_register("pause", [_key(KEY_ESCAPE)])
	_register("attack_light", [_mouse(MOUSE_BUTTON_LEFT)])
	_register("attack_heavy", [_mouse(MOUSE_BUTTON_RIGHT)])

func _key(k: Key) -> InputEventKey:
	var ev := InputEventKey.new()
	ev.keycode = k
	return ev

func _mouse(b: MouseButton) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = b
	return ev

func _register(action: String, events: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for ev in events:
		InputMap.action_add_event(action, ev)
