extends Node
## Regista as ações de input em tempo de arranque.
## Fonte única: ACTIONS (predefinições + overrides do jogador em
## GameState.custom_bindings, aplicado a seguir ao carregar o jogo).

const ACTIONS := [
	{"action": "move_forward", "events": [{"type": "key", "key": KEY_W}, {"type": "key", "key": KEY_UP}, {"type": "axis", "axis": JOY_AXIS_LEFT_Y, "value": -1.0}]},
	{"action": "move_back", "events": [{"type": "key", "key": KEY_S}, {"type": "key", "key": KEY_DOWN}, {"type": "axis", "axis": JOY_AXIS_LEFT_Y, "value": 1.0}]},
	{"action": "move_left", "events": [{"type": "key", "key": KEY_A}, {"type": "key", "key": KEY_LEFT}, {"type": "axis", "axis": JOY_AXIS_LEFT_X, "value": -1.0}]},
	{"action": "move_right", "events": [{"type": "key", "key": KEY_D}, {"type": "key", "key": KEY_RIGHT}, {"type": "axis", "axis": JOY_AXIS_LEFT_X, "value": 1.0}]},
	{"action": "dodge", "events": [{"type": "key", "key": KEY_SPACE}, {"type": "joy", "value": JOY_BUTTON_A}]},
	{"action": "jump", "events": [{"type": "key", "key": KEY_X}, {"type": "joy", "value": JOY_BUTTON_DPAD_UP}]},
	{"action": "sprint", "events": [{"type": "key", "key": KEY_SHIFT}, {"type": "joy", "value": JOY_BUTTON_LEFT_STICK}]},
	{"action": "block", "events": [{"type": "key", "key": KEY_Q}, {"type": "joy", "value": JOY_BUTTON_LEFT_SHOULDER}]},
	{"action": "interact", "events": [{"type": "key", "key": KEY_E}, {"type": "joy", "value": JOY_BUTTON_B}]},
	{"action": "rupture", "events": [{"type": "key", "key": KEY_F}, {"type": "joy", "value": JOY_BUTTON_RIGHT_SHOULDER}]},
	{"action": "potion", "events": [{"type": "key", "key": KEY_R}, {"type": "joy", "value": JOY_BUTTON_DPAD_DOWN}]},
	{"action": "lock_on", "events": [{"type": "key", "key": KEY_TAB}, {"type": "joy", "value": JOY_BUTTON_RIGHT_STICK}]},
	{"action": "pause", "events": [{"type": "key", "key": KEY_ESCAPE}, {"type": "joy", "value": JOY_BUTTON_START}]},
	{"action": "attack_light", "events": [{"type": "mouse", "value": MOUSE_BUTTON_LEFT}, {"type": "joy", "value": JOY_BUTTON_X}]},
	{"action": "attack_heavy", "events": [{"type": "mouse", "value": MOUSE_BUTTON_RIGHT}, {"type": "joy", "value": JOY_BUTTON_Y}]},
	{"action": "ability_1", "events": [{"type": "key", "key": KEY_1}]},
	{"action": "ability_2", "events": [{"type": "key", "key": KEY_2}]},
	{"action": "ability_3", "events": [{"type": "key", "key": KEY_3}]},
	{"action": "ability_4", "events": [{"type": "key", "key": KEY_4}]},
	{"action": "technique_1", "events": [{"type": "key", "key": KEY_V}]},
	{"action": "technique_2", "events": [{"type": "key", "key": KEY_C}]},
	{"action": "technique_3", "events": [{"type": "key", "key": KEY_Z}]},
]

const ACTION_NAMES := {
	"move_forward": "Avançar", "move_back": "Recuar", "move_left": "Esquerda", "move_right": "Direita",
	"dodge": "Esquiva", "jump": "Saltar", "sprint": "Correr", "block": "Bloquear", "interact": "Interagir / Corrente",
	"rupture": "Estado de Ruptura", "potion": "Poção", "lock_on": "Fixar alvo", "pause": "Pausa",
	"attack_light": "Ataque leve", "attack_heavy": "Ataque pesado",
	"ability_1": "Habilidade 1 — Liora", "ability_2": "Habilidade 2 — Bram",
	"ability_3": "Habilidade 3 — Sena", "ability_4": "Habilidade 4 — Iven",
	"technique_1": "Técnica — Passo Vazio", "technique_2": "Técnica — Corrida do Predador", "technique_3": "Técnica — Queda do Colosso",
}

func _ready() -> void:
	apply_custom_bindings({})

func apply_custom_bindings(custom: Dictionary) -> void:
	for def in ACTIONS:
		var action := String(def["action"])
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		InputMap.action_erase_events(action)
		var events: Array = def["events"]
		if custom != null and custom.has(action):
			var override = custom[action]
			if override is Array and not (override as Array).is_empty():
				events = override
		for d in events:
			var ev := _event_from_dict(d)
			if ev != null:
				InputMap.action_add_event(action, ev)

func dict_from_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "key": event.keycode}
	elif event is InputEventMouseButton:
		return {"type": "mouse", "value": event.button_index}
	elif event is InputEventJoypadButton:
		return {"type": "joy", "value": event.button_index}
	elif event is InputEventJoypadMotion:
		var v: float = event.axis_value
		return {"type": "axis", "axis": event.axis, "value": -1.0 if v < 0.0 else 1.0}
	return {}

func _event_from_dict(d: Dictionary) -> InputEvent:
	match String(d.get("type", "")):
		"key":
			var ev := InputEventKey.new()
			ev.keycode = int(d.get("key", 0))
			return ev
		"mouse":
			var ev := InputEventMouseButton.new()
			ev.button_index = int(d.get("value", 1))
			return ev
		"joy":
			var ev := InputEventJoypadButton.new()
			ev.button_index = int(d.get("value", 0))
			return ev
		"axis":
			var ev := InputEventJoypadMotion.new()
			ev.axis = int(d.get("axis", 0))
			ev.axis_value = float(d.get("value", 1.0))
			return ev
	return null

func binding_summary(action: String) -> String:
	var parts: Array[String] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			parts.append(OS.get_keycode_string(ev.keycode))
		elif ev is InputEventMouseButton:
			match ev.button_index:
				MOUSE_BUTTON_LEFT: parts.append("Rato E")
				MOUSE_BUTTON_RIGHT: parts.append("Rato D")
				_: parts.append("Rato %d" % ev.button_index)
		elif ev is InputEventJoypadButton:
			parts.append("Pad %d" % ev.button_index)
		elif ev is InputEventJoypadMotion:
			parts.append("Eixo %d%s" % [ev.axis, "−" if ev.axis_value < 0.0 else "+"])
	return ", ".join(parts)
