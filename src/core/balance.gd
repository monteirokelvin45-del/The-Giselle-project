extends Node
## Balanceamento data-driven (v1.0 / P8 do audit): números de combate,
## XP e dificuldade vivem em src/balance/balance.json — ajusta e joga,
## sem tocar em código. Fallbacks seguros se faltar ficheiro/chave.

var _data: Dictionary = {}
const FALLBACK_DIFFICULTY := {
	"casual": {"taken": 0.65, "enemy_hp": 0.75, "xp": 1.0, "label": "Casual (relaxado)"},
	"normal": {"taken": 1.0, "enemy_hp": 1.0, "xp": 1.0, "label": "Normal"},
	"pesadelo": {"taken": 1.35, "enemy_hp": 1.25, "xp": 1.5, "label": "Pesadelo (+50% XP)"},
}

func _ready() -> void:
	var path := "res://src/balance/balance.json"
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			_data = parsed
		else:
			push_warning("balance.json inválido — a usar valores internos.")

func difficulty_table() -> Dictionary:
	var t = _data.get("difficulty", FALLBACK_DIFFICULTY)
	return t if t is Dictionary and not (t as Dictionary).is_empty() else FALLBACK_DIFFICULTY

func xp_needed(level: int) -> int:
	var x = _data.get("xp", {})
	var base: int = int(x.get("base", 100)) if x is Dictionary else 100
	var per := int(x.get("per_level", 75)) if x is Dictionary else 75
	return base + (level - 1) * per

func attr(key: String, fallback: float) -> float:
	var a = _data.get("attr", {})
	if a is Dictionary and (a as Dictionary).has(key):
		return float((a as Dictionary)[key])
	return fallback

func potion_heal() -> float:
	return float(_data.get("potion_heal", 45.0))

const FALLBACK_JUMP := {
	"velocity": 8.2,
	"air_damage_mult": 1.25,
	"air_posture_mult": 1.5,
	"slam_radius": 3.1,
	"slam_damage": 24.0,
	"slam_posture": 42.0,
}

func jump_cfg() -> Dictionary:
	var t = _data.get("jump", {})
	if t is Dictionary and not (t as Dictionary).is_empty():
		var out: Dictionary = FALLBACK_JUMP.duplicate(true)
		for k in (t as Dictionary):
			out[k] = (t as Dictionary)[k]
		return out
	return FALLBACK_JUMP.duplicate(true)
