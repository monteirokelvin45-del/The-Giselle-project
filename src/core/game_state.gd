extends Node
## Estado global do jogo: atributos, XP, missões, inventário, ruptura e save/load.
## Autoload "GameState". Persistido em user://academia_zero_save.json

signal notify(text: String)
signal objective_changed(text: String)
signal stats_changed()
signal game_saved()

const SAVE_PATH := "user://academia_zero_save.json"
const ATTR_KEYS := ["for", "vel", "ref", "res", "fol", "tec", "per", "ada"]
const ATTR_NAMES := {
	"for": "Força", "vel": "Velocidade", "ref": "Reflexos", "res": "Resistência",
	"fol": "Fôlego", "tec": "Técnica", "per": "Perceção", "ada": "Adaptação",
}
const ATTR_HINTS := {
	"for": "+8% dano físico", "vel": "+0.25 velocidade", "ref": "+0.025s janela de parry",
	"res": "+14 vida máxima", "fol": "+12 fôlego máximo", "tec": "+10% dano de postura",
	"per": "+1m alcance de lock-on", "ada": "Corrente mais rápida, +8% ruptura",
}
const DEFAULT_ATTRS := {"for": 1, "vel": 1, "ref": 1, "res": 1, "fol": 1, "tec": 1, "per": 1, "ada": 1}

var level: int = 1
var xp: int = 0
var attribute_points: int = 0
var attributes: Dictionary = DEFAULT_ATTRS.duplicate()
var marcos: int = 75
var potions: int = 2
var rupture: float = 0.0
var rupture_time_left: float = 0.0

## Missão principal: 0 rédea → 7 fim
var main_stage: int = 0
## Missões secundárias
var wolf_kills: int = 0
var herb_count: int = 0
var wolf_quest_state: String = "available"   # available | active | done
var herb_quest_state: String = "available"   # available | active | done
var ambush_spawned: bool = false
var artifact_unlocked: bool = false
var evaluations_used: int = 0
var ending: String = ""

var resume_pending: bool = false
var saved_position: Vector3 = Vector3(0, 1, 34)
var saved_hp: float = -1.0
var saved_stamina: float = -1.0
var system_return: Vector3 = Vector3(0, 1, 34)
var system_return_pending: bool = false

func xp_needed() -> int:
	return 100 + (level - 1) * 75

func xp_progress() -> float:
	return clampf(float(xp) / float(maxi(1, xp_needed())), 0.0, 1.0)

func add_xp(amount: int) -> void:
	xp += amount
	notify("+%d XP" % amount)
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		attribute_points += 2
		notify("NÍVEL %d! +2 pontos de atributo (Esc → Atributos)" % level)
		Audio.play("levelup")
	stats_changed.emit()

func max_hp() -> float:
	return 100.0 + float(int(attributes["res"]) - 1) * 14.0

func max_stamina() -> float:
	return 100.0 + float(int(attributes["fol"]) - 1) * 12.0

func stamina_regen() -> float:
	return 28.0 + float(int(attributes["fol"]) - 1) * 3.0

func move_speed() -> float:
	return 5.2 + float(int(attributes["vel"]) - 1) * 0.25

func damage_mult() -> float:
	return 1.0 + float(int(attributes["for"]) - 1) * 0.08

func posture_mult() -> float:
	return 1.0 + float(int(attributes["tec"]) - 1) * 0.10

func parry_window() -> float:
	return 0.2 + float(int(attributes["ref"]) - 1) * 0.025

func chain_cooldown() -> float:
	return maxf(2.0, 6.0 - float(int(attributes["ada"]) - 1) * 0.6)

func lock_range() -> float:
	return 16.0 + float(int(attributes["per"]) - 1) * 1.0

func rupture_gain_mult() -> float:
	return 1.0 + float(int(attributes["ada"]) - 1) * 0.08

func add_rupture(amount: float) -> void:
	if rupture_time_left > 0.0:
		return
	rupture = clampf(rupture + amount * rupture_gain_mult(), 0.0, 100.0)
	stats_changed.emit()

func try_activate_rupture() -> bool:
	if rupture >= 100.0 and rupture_time_left <= 0.0:
		rupture_time_left = 8.0
		notify("ESTADO DE RUPTURA — 8 segundos de fúria!")
		stats_changed.emit()
		return true
	notify("Ruptura não está cheia (%d%%)" % int(rupture))
	return false

func tick_rupture(delta: float) -> void:
	if rupture_time_left > 0.0:
		rupture_time_left -= delta
		rupture = clampf(rupture_time_left / 8.0 * 100.0, 0.0, 100.0)
		if rupture_time_left <= 0.0:
			rupture = 0.0
			notify("Esgotado... o corpo cobra o preço.")
		stats_changed.emit()

func spend_attribute(key: String) -> bool:
	if attribute_points <= 0 or not attributes.has(key):
		return false
	attributes[key] = int(attributes[key]) + 1
	attribute_points -= 1
	stats_changed.emit()
	return true

func spend_potion() -> bool:
	if potions <= 0:
		notify("Sem poções!")
		return false
	potions -= 1
	stats_changed.emit()
	return true

func add_marcos(n: int) -> void:
	marcos = maxi(0, marcos + n)
	stats_changed.emit()

# ---------------------------------------------------------------- missões ---
func objective_text() -> String:
	match main_stage:
		0: return "Fala com a tua mãe, Elen, na casa junto ao poço."
		1: return "Visita Garr, o ferreiro, junto à forja no lado poente."
		2: return "Atravessa a Floresta Baixa pela Estrada Imperial."
		3: return "Chega ao Portão da Academia e fala com Liora Venn."
		4: return "Vai à arena e fala com o Mestre Dario Vale."
		5: return "Derrota o Guardião da Prova na arena."
		6: return "Abre o menu (Esc) e toma A DECISÃO."
		_: return "Fim da linha — por agora. O mundo continua sem ti... ou não."

func side_objectives() -> Array[String]:
	var list: Array[String] = []
	if wolf_quest_state == "active":
		list.append("Lobos de Cinza na estrada: %d/3" % wolf_kills)
	elif wolf_quest_state == "done":
		list.append("Lobos de Cinza: concluído ✓")
	if herb_quest_state == "active":
		list.append("Fibras de Ruína: %d/5" % herb_count)
	elif herb_quest_state == "done":
		list.append("Luz para as Lâmpadas: concluído ✓")
	return list

func advance_stage(to_stage: int) -> void:
	if to_stage > main_stage:
		main_stage = to_stage
		objective_changed.emit(objective_text())
		notify("Novo objetivo — " + objective_text())

func on_wolf_killed() -> void:
	if wolf_quest_state != "active":
		return
	wolf_kills += 1
	notify("Lobo de Cinza derrotado (%d/3)" % wolf_kills)
	if wolf_kills >= 3:
		wolf_quest_state = "done"
		add_marcos(60)
		add_xp(80)
		notify("Missão concluída: Lobos da Estrada! +60 marcos")
		Audio.play("quest_done")
	stats_changed.emit()

func on_herb_collected() -> void:
	if herb_quest_state != "active":
		return
	herb_count += 1
	notify("Fibra de Ruína recolhida (%d/5)" % herb_count)
	if herb_count >= 5:
		herb_quest_state = "done"
		add_marcos(40)
		add_xp(60)
		potions += 1
		notify("Missão concluída: Luz para as Lâmpadas! +40 marcos, +1 poção")
		Audio.play("quest_done")
	stats_changed.emit()

# ------------------------------------------------------------------ save ---
func save_game(pos: Vector3, hp: float, stamina: float) -> bool:
	var data := {
		"version": 1,
		"level": level, "xp": xp, "attribute_points": attribute_points,
		"attributes": attributes, "marcos": marcos, "potions": potions,
		"rupture": rupture, "main_stage": main_stage,
		"wolf_kills": wolf_kills, "herb_count": herb_count,
		"wolf_quest_state": wolf_quest_state, "herb_quest_state": herb_quest_state,
		"ambush_spawned": ambush_spawned, "artifact_unlocked": artifact_unlocked,
		"evaluations_used": evaluations_used, "ending": ending,
		"px": pos.x, "py": pos.y, "pz": pos.z, "hp": hp, "stamina": stamina,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		notify("Não foi possível guardar o jogo.")
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	game_saved.emit()
	notify("Jogo guardado.")
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		notify("Não existe jogo guardado.")
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		notify("Ficheiro de gravação corrompido.")
		return false
	level = int(parsed.get("level", 1))
	xp = int(parsed.get("xp", 0))
	attribute_points = int(parsed.get("attribute_points", 0))
	var loaded_attrs: Dictionary = parsed.get("attributes", DEFAULT_ATTRS)
	for key in ATTR_KEYS:
		attributes[key] = int(loaded_attrs.get(key, 1))
	marcos = int(parsed.get("marcos", 75))
	potions = int(parsed.get("potions", 2))
	rupture = float(parsed.get("rupture", 0.0))
	rupture_time_left = 0.0
	main_stage = int(parsed.get("main_stage", 0))
	wolf_kills = int(parsed.get("wolf_kills", 0))
	herb_count = int(parsed.get("herb_count", 0))
	wolf_quest_state = String(parsed.get("wolf_quest_state", "available"))
	herb_quest_state = String(parsed.get("herb_quest_state", "available"))
	ambush_spawned = bool(parsed.get("ambush_spawned", false))
	artifact_unlocked = bool(parsed.get("artifact_unlocked", false))
	evaluations_used = int(parsed.get("evaluations_used", 0))
	ending = String(parsed.get("ending", ""))
	saved_position = Vector3(float(parsed.get("px", 0.0)), float(parsed.get("py", 1.0)), float(parsed.get("pz", 34.0)))
	saved_hp = float(parsed.get("hp", -1.0))
	saved_stamina = float(parsed.get("stamina", -1.0))
	resume_pending = true
	stats_changed.emit()
	notify("Jogo carregado.")
	return true

func reset_for_new_game() -> void:
	level = 1
	xp = 0
	attribute_points = 0
	attributes = DEFAULT_ATTRS.duplicate()
	marcos = 75
	potions = 2
	rupture = 0.0
	rupture_time_left = 0.0
	main_stage = 0
	wolf_kills = 0
	herb_count = 0
	wolf_quest_state = "available"
	herb_quest_state = "available"
	ambush_spawned = false
	artifact_unlocked = false
	evaluations_used = 0
	ending = ""
	resume_pending = false
	system_return_pending = false
	saved_position = Vector3(0, 1, 34)
	saved_hp = -1.0
	saved_stamina = -1.0
	stats_changed.emit()
