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

## Dificuldade: casual | normal | pesadelo (afetada por mults; ver DIFFICULTY)
var difficulty: String = "normal"
const DIFFICULTY := {
	"casual": {"taken": 0.65, "enemy_hp": 0.75, "xp": 1.0, "label": "Casual (relaxado)"},
	"normal": {"taken": 1.0, "enemy_hp": 1.0, "xp": 1.0, "label": "Normal"},
	"pesadelo": {"taken": 1.35, "enemy_hp": 1.25, "xp": 1.5, "label": "Pesadelo (+50% XP)"},
}
const DIFFICULTY_ORDER := ["casual", "normal", "pesadelo"]

# ------------------------------------------------- v0.3 — O Sistema ----------
const SAVE_VERSION := 2

const THREAT_LEVELS := [
	{"name": "Básico", "hp_mult": 0.75, "count": 2, "level_req": 1, "reward_mult": 1.0},
	{"name": "Intermediário", "hp_mult": 1.0, "count": 3, "level_req": 1, "reward_mult": 1.25},
	{"name": "Avançado", "hp_mult": 1.45, "count": 4, "level_req": 3, "reward_mult": 1.6},
	{"name": "Mestre", "hp_mult": 2.1, "count": 5, "level_req": 5, "reward_mult": 2.1},
	{"name": "Impossível", "hp_mult": 3.1, "count": 5, "level_req": 8, "reward_mult": 3.0},
]

## v0.5 — Regiões do mundo aberto (viagem rápida)
const REGIONS := [
	{"id": "ruun", "name": "Floresta de Ruun", "level_req": 3, "power": 1.5, "xp": 150, "marcos": 90,
		"desc": "Pinhais eternos e lobos de cinza.",
		"ground": Color(0.14, 0.26, 0.11), "fog": Color(0.3, 0.42, 0.27), "fog_density": 0.021,
		"sky_top": Color(0.2, 0.35, 0.45), "sky_horizon": Color(0.55, 0.62, 0.48), "sun": Color(0.88, 0.95, 0.78),
		"prop": "tree_single_A.gltf", "types": ["wolf", "wolf", "salteador", "salteador", "cinza", "salteador"]},
	{"id": "sahr", "name": "Deserto de Sahr", "level_req": 5, "power": 1.9, "xp": 200, "marcos": 120,
		"desc": "Dunas infinitas e túmulos de Primeiros Engenheiros.",
		"ground": Color(0.68, 0.56, 0.35), "fog": Color(0.8, 0.69, 0.46), "fog_density": 0.017,
		"sky_top": Color(0.32, 0.42, 0.62), "sky_horizon": Color(0.9, 0.78, 0.55), "sun": Color(1.0, 0.9, 0.68),
		"prop": "rock_single_A.gltf", "types": ["salteador", "salteador", "cinza", "salteador", "wolf", "cinza"]},
	{"id": "khar", "name": "Montanhas de Khar", "level_req": 7, "power": 2.35, "xp": 260, "marcos": 150,
		"desc": "Picos de pedra e relâmpagos que nunca se apagam.",
		"ground": Color(0.34, 0.36, 0.41), "fog": Color(0.42, 0.47, 0.55), "fog_density": 0.024,
		"sky_top": Color(0.16, 0.22, 0.36), "sky_horizon": Color(0.55, 0.6, 0.7), "sun": Color(0.85, 0.9, 1.0),
		"prop": "rock_single_C.gltf", "types": ["cinza", "cinza", "salteador", "guardiao", "cinza", "salteador"]},
	{"id": "lume", "name": "Arquipélago de Lume", "level_req": 9, "power": 2.8, "xp": 330, "marcos": 190,
		"desc": "Ilhas de pedra clara e faróis de fósforo azul.",
		"ground": Color(0.16, 0.36, 0.45), "fog": Color(0.38, 0.58, 0.68), "fog_density": 0.021,
		"sky_top": Color(0.14, 0.3, 0.48), "sky_horizon": Color(0.6, 0.82, 0.88), "sun": Color(0.82, 0.96, 1.0),
		"prop": "rock_single_A.gltf", "types": ["cinza", "cinza", "cinza", "salteador", "guardiao", "cinza"]},
	{"id": "aer", "name": "Ilhas de Aer", "level_req": 11, "power": 3.35, "xp": 420, "marcos": 240,
		"desc": "Rochas suspensas num mar de nuvens.",
		"ground": Color(0.28, 0.3, 0.4), "fog": Color(0.62, 0.64, 0.74), "fog_density": 0.034,
		"sky_top": Color(0.22, 0.28, 0.55), "sky_horizon": Color(0.85, 0.8, 0.92), "sun": Color(0.9, 0.88, 1.0),
		"prop": "rock_single_C.gltf", "types": ["guardiao", "cinza", "cinza", "guardiao", "cinza", "cinza"]},
	{"id": "orun", "name": "Fim do Abismo", "level_req": 13, "power": 4.0, "xp": 550, "marcos": 320,
		"desc": "O lugar de onde nenhum Núcleo voltou a subir.",
		"ground": Color(0.07, 0.05, 0.12), "fog": Color(0.14, 0.09, 0.22), "fog_density": 0.038,
		"sky_top": Color(0.02, 0.02, 0.06), "sky_horizon": Color(0.3, 0.16, 0.45), "sun": Color(0.55, 0.35, 0.95),
		"prop": "rock_single_C.gltf", "types": ["guardiao", "cinza", "guardiao", "cinza", "cinza", "cinza"]},
]

const ARENA_ENVIRONMENTS := [
	{"id": "arena", "name": "Arena Branca", "ground": Color(0.93, 0.93, 0.96), "fog": Color(0.97, 0.97, 1.0), "fog_density": 0.028, "light": Color(1.0, 1.0, 1.0), "ambient": Color(0.9, 0.9, 0.96)},
	{"id": "floresta", "name": "Floresta de Ruun", "ground": Color(0.16, 0.28, 0.12), "fog": Color(0.35, 0.45, 0.3), "fog_density": 0.02, "light": Color(0.85, 0.95, 0.7), "ambient": Color(0.35, 0.45, 0.3)},
	{"id": "deserto", "name": "Deserto de Sahr", "ground": Color(0.72, 0.6, 0.38), "fog": Color(0.82, 0.72, 0.5), "fog_density": 0.016, "light": Color(1.0, 0.9, 0.65), "ambient": Color(0.75, 0.65, 0.45)},
	{"id": "montanha", "name": "Montanhas de Khar", "ground": Color(0.38, 0.4, 0.44), "fog": Color(0.45, 0.5, 0.58), "fog_density": 0.022, "light": Color(0.9, 0.93, 1.0), "ambient": Color(0.45, 0.48, 0.55)},
	{"id": "vulcao", "name": "Vulcão de Orun", "ground": Color(0.09, 0.06, 0.06), "fog": Color(0.35, 0.14, 0.08), "fog_density": 0.03, "light": Color(1.0, 0.5, 0.25), "ambient": Color(0.45, 0.2, 0.12)},
	{"id": "oceano", "name": "Arquipélago de Lume", "ground": Color(0.18, 0.38, 0.48), "fog": Color(0.4, 0.6, 0.7), "fog_density": 0.02, "light": Color(0.85, 0.97, 1.0), "ambient": Color(0.35, 0.5, 0.6)},
	{"id": "cidade", "name": "Cidade Cinza", "ground": Color(0.35, 0.33, 0.31), "fog": Color(0.4, 0.38, 0.35), "fog_density": 0.019, "light": Color(1.0, 0.9, 0.75), "ambient": Color(0.4, 0.37, 0.33)},
	{"id": "abismo", "name": "Fim do Abismo", "ground": Color(0.07, 0.05, 0.11), "fog": Color(0.12, 0.08, 0.2), "fog_density": 0.035, "light": Color(0.55, 0.35, 0.9), "ambient": Color(0.2, 0.14, 0.32)},
]

var threat_level: int = 0
var arena_environment: String = "arena"
var arena_enemy_count: int = 3
var arena_time_limit: float = 60.0   # segundos; 0 = ilimitado
var arena_potions: bool = true
var evaluation_history: Array = []
var system_memory: Dictionary = {"best_style": "", "refusals": 0, "evaluations": 0}

# --------------------------------------- v0.4/v0.6 — Academia e mundo ------
## Exames da Academia: id → true quando aprovado
var exams_done: Dictionary = {}
## Companheiros recrutados: id → lealdade (0–100)
var companions: Dictionary = {}
var romance_id: String = ""
## Reputação nas fações (-100 a +100)
var reputation: Dictionary = {
	"imperial": 0,      # Conselho Imperial
	"irmandade": 0,     # Irmandade do Vácuo
	"ordem": 0,         # Ordem da Cinza
	"arquivistas": 0,   # Arquivistas do Proibido
	"academia": 0,      # Academia Real de Veyra
}
## Regiões visitadas / concluídas (id → nº de expedições limpas)
var region_known: Dictionary = {"noro": true}
var region_clears: Dictionary = {}
var current_region: String = "noro"
## Lesões: 0 = saudável, 1 = grave (-15% velocidade, -10% dano até descansar)
var injury: int = 0

# ------------------------------------------- v1.0 — Acessibilidade ----------
var colorblind_mode: int = 0      # 0 desligado · 1 protanopia · 2 deuteranopia · 3 tritanopia
var subtitle_scale: float = 1.0
var custom_bindings: Dictionary = {}
var music_enabled: bool = true

func _difficulty_table() -> Dictionary:
	if Balance != null and Balance.has_method("difficulty_table"):
		var t: Dictionary = Balance.difficulty_table()
		if not t.is_empty():
			return t
	return DIFFICULTY

func difficulty_taken_mult() -> float:
	var t := _difficulty_table()
	return float(t.get(difficulty, t.get("normal", DIFFICULTY["normal"]))["taken"])

func difficulty_enemy_hp_mult() -> float:
	var t := _difficulty_table()
	return float(t.get(difficulty, t.get("normal", DIFFICULTY["normal"]))["enemy_hp"])

func difficulty_xp_mult() -> float:
	var t := _difficulty_table()
	return float(t.get(difficulty, t.get("normal", DIFFICULTY["normal"]))["xp"])

func difficulty_label() -> String:
	var t := _difficulty_table()
	return String(t.get(difficulty, t.get("normal", DIFFICULTY["normal"]))["label"])

func potion_heal() -> float:
	if Balance != null and Balance.has_method("potion_heal"):
		return Balance.potion_heal()
	return 45.0

func cycle_difficulty() -> void:
	var idx := DIFFICULTY_ORDER.find(difficulty)
	idx = (idx + 1) % DIFFICULTY_ORDER.size()
	difficulty = DIFFICULTY_ORDER[idx]
	notify("Dificuldade: %s" % difficulty_label())
	stats_changed.emit()

# ------------------------------------------- Sistema: níveis e arena --------
func threat_hp_mult() -> float:
	return float(THREAT_LEVELS[clampi(threat_level, 0, THREAT_LEVELS.size() - 1)]["hp_mult"])

func threat_count() -> int:
	return int(THREAT_LEVELS[clampi(threat_level, 0, THREAT_LEVELS.size() - 1)]["count"])

func threat_reward_mult() -> float:
	return float(THREAT_LEVELS[clampi(threat_level, 0, THREAT_LEVELS.size() - 1)]["reward_mult"])

func threat_level_req() -> int:
	return int(THREAT_LEVELS[clampi(threat_level, 0, THREAT_LEVELS.size() - 1)]["level_req"])

func threat_name() -> String:
	return String(THREAT_LEVELS[clampi(threat_level, 0, THREAT_LEVELS.size() - 1)]["name"])

func can_threat(idx: int) -> bool:
	return level >= int(THREAT_LEVELS[clampi(idx, 0, THREAT_LEVELS.size() - 1)]["level_req"])

const REPUTATION_FACTIONS := ["imperial", "irmandade", "ordem", "arquivistas", "academia"]
const REPUTATION_NAMES := {
	"imperial": "Conselho Imperial",
	"irmandade": "Irmandade do Vácuo",
	"ordem": "Ordem da Cinza",
	"arquivistas": "Arquivistas do Proibido",
	"academia": "Academia Real de Veyra",
}

func add_reputation(faction: String, amount: int) -> void:
	if not reputation.has(faction):
		return
	reputation[faction] = clampi(int(reputation[faction]) + amount, -100, 100)
	var verb := "melhorada" if amount >= 0 else "piorada"
	notify("Reputação %s %s (%d)" % [String(REPUTATION_NAMES.get(faction, faction)), verb, int(reputation[faction])])
	stats_changed.emit()

func reputation_rank(faction: String) -> String:
	var r := int(reputation.get(faction, 0))
	if r <= -30: return "Hostil"
	if r < 0: return "Desconfiado"
	if r < 20: return "Neutro"
	if r < 50: return "Conhecido"
	if r < 80: return "Respeitado"
	return "Lendário"

func companion_loyalty(id: String) -> int:
	return int(companions.get(id, 0))

func add_companion_loyalty(id: String, amount: int) -> void:
	if not companions.has(id):
		companions[id] = 0
	companions[id] = clampi(int(companions[id]) + amount, 0, 100)
	stats_changed.emit()

func rest() -> void:
	injury = 0
	stats_changed.emit()

func add_injury() -> void:
	if injury == 0:
		injury = 1
		notify("LESÃO GRAVE — -15% velocidade, -10% dano até descansares (forja de GARR, casa da Elen ou dormitórios).")
		stats_changed.emit()

func region_config(region_id: String) -> Dictionary:
	for r in REGIONS:
		if String(r["id"]) == region_id:
			return r
	return REGIONS[0]

func region_level_req(region_id: String) -> int:
	return int(region_config(region_id)["level_req"])

func region_unlocked(region_id: String) -> bool:
	return level >= region_level_req(region_id)

func region_clear_count(region_id: String) -> int:
	return int(region_clears.get(region_id, 0))

func environment_config() -> Dictionary:
	for env in ARENA_ENVIRONMENTS:
		if String(env["id"]) == arena_environment:
			return env
	return ARENA_ENVIRONMENTS[0]

var resume_pending: bool = false
var saved_position: Vector3 = Vector3(0, 1, 34)
var saved_hp: float = -1.0
var saved_stamina: float = -1.0
var system_return: Vector3 = Vector3(0, 1, 34)
var system_return_pending: bool = false

func xp_needed() -> int:
	if Balance != null and Balance.has_method("xp_needed"):
		return Balance.xp_needed(level)
	return 100 + (level - 1) * 75

func xp_progress() -> float:
	return clampf(float(xp) / float(maxi(1, xp_needed())), 0.0, 1.0)

func add_xp(amount: int) -> void:
	amount = maxi(1, int(round(amount * difficulty_xp_mult())))
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
	var per := 14.0
	if Balance != null and Balance.has_method("attr"):
		per = Balance.attr("hp_per_res", 14.0)
	return 100.0 + float(int(attributes["res"]) - 1) * per

func max_stamina() -> float:
	return 100.0 + float(int(attributes["fol"]) - 1) * 12.0

func stamina_regen() -> float:
	return 28.0 + float(int(attributes["fol"]) - 1) * 3.0

func move_speed() -> float:
	return (5.2 + float(int(attributes["vel"]) - 1) * 0.25) * (0.85 if injury > 0 else 1.0)

func damage_mult() -> float:
	var per := 0.08
	if Balance != null and Balance.has_method("attr"):
		per = Balance.attr("damage_per_point", 0.08)
	return (1.0 + float(int(attributes["for"]) - 1) * per) * (0.90 if injury > 0 else 1.0)

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
		"version": SAVE_VERSION,
		"difficulty": difficulty,
		"level": level, "xp": xp, "attribute_points": attribute_points,
		"attributes": attributes, "marcos": marcos, "potions": potions,
		"rupture": rupture, "main_stage": main_stage,
		"wolf_kills": wolf_kills, "herb_count": herb_count,
		"wolf_quest_state": wolf_quest_state, "herb_quest_state": herb_quest_state,
		"ambush_spawned": ambush_spawned, "artifact_unlocked": artifact_unlocked,
		"evaluations_used": evaluations_used, "ending": ending,
		"threat_level": threat_level, "arena_environment": arena_environment,
		"arena_enemy_count": arena_enemy_count, "arena_time_limit": arena_time_limit,
		"arena_potions": arena_potions,
		"evaluation_history": evaluation_history, "system_memory": system_memory,
		"exams_done": exams_done, "companions": companions, "romance_id": romance_id,
		"reputation": reputation, "region_known": region_known,
		"region_clears": region_clears, "current_region": current_region,
		"injury": injury,
		"colorblind_mode": colorblind_mode, "subtitle_scale": subtitle_scale,
		"custom_bindings": custom_bindings, "music_enabled": music_enabled,
		"px": pos.x, "py": pos.y, "pz": pos.z, "hp": hp, "stamina": stamina,
	}
	var payload := JSON.stringify(data)
	data["checksum"] = payload.sha256_text()
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		notify("Não foi possível guardar o jogo.")
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	# Backup do save anterior antes de o substituir
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.rename_absolute(SAVE_PATH, SAVE_PATH + ".bak")
	var err := DirAccess.rename_absolute(tmp_path, SAVE_PATH)
	if err != OK:
		notify("Não foi possível guardar o jogo.")
		return false
	game_saved.emit()
	notify("Jogo guardado.")
	return true

func _apply_save_dict(parsed: Dictionary) -> void:
	var saved_difficulty := String(parsed.get("difficulty", "normal"))
	if not DIFFICULTY.has(saved_difficulty):
		saved_difficulty = "normal"
	difficulty = saved_difficulty
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
	threat_level = clampi(int(parsed.get("threat_level", 0)), 0, THREAT_LEVELS.size() - 1)
	arena_environment = String(parsed.get("arena_environment", "arena"))
	arena_enemy_count = clampi(int(parsed.get("arena_enemy_count", 3)), 1, 5)
	arena_time_limit = float(parsed.get("arena_time_limit", 60.0))
	arena_potions = bool(parsed.get("arena_potions", true))
	evaluation_history = parsed.get("evaluation_history", [])
	if typeof(evaluation_history) != TYPE_ARRAY:
		evaluation_history = []
	var mem: Dictionary = parsed.get("system_memory", {})
	system_memory = {"best_style": String(mem.get("best_style", "")), "refusals": int(mem.get("refusals", 0)), "evaluations": int(mem.get("evaluations", 0))}
	exams_done = parsed.get("exams_done", {})
	if typeof(exams_done) != TYPE_DICTIONARY:
		exams_done = {}
	companions = parsed.get("companions", {})
	if typeof(companions) != TYPE_DICTIONARY:
		companions = {}
	romance_id = String(parsed.get("romance_id", ""))
	var rep: Dictionary = parsed.get("reputation", {})
	for faction in REPUTATION_FACTIONS:
		reputation[faction] = clampi(int(rep.get(faction, 0)), -100, 100)
	region_known = parsed.get("region_known", {"noro": true})
	if typeof(region_known) != TYPE_DICTIONARY:
		region_known = {"noro": true}
	region_clears = parsed.get("region_clears", {})
	if typeof(region_clears) != TYPE_DICTIONARY:
		region_clears = {}
	current_region = String(parsed.get("current_region", "noro"))
	injury = clampi(int(parsed.get("injury", 0)), 0, 1)
	colorblind_mode = clampi(int(parsed.get("colorblind_mode", 0)), 0, 3)
	subtitle_scale = clampf(float(parsed.get("subtitle_scale", 1.0)), 0.8, 1.6)
	custom_bindings = parsed.get("custom_bindings", {})
	if typeof(custom_bindings) != TYPE_DICTIONARY:
		custom_bindings = {}
	music_enabled = bool(parsed.get("music_enabled", true))
	saved_position = Vector3(float(parsed.get("px", 0.0)), float(parsed.get("py", 1.0)), float(parsed.get("pz", 34.0)))
	saved_hp = float(parsed.get("hp", -1.0))
	saved_stamina = float(parsed.get("stamina", -1.0))

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		notify("Não existe jogo guardado.")
		return false
	var raw := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		# Tentar o backup antes de desistir
		var bak := FileAccess.get_file_as_string(SAVE_PATH + ".bak")
		parsed = JSON.parse_string(bak) if bak != "" else null
		if typeof(parsed) != TYPE_DICTIONARY:
			notify("Ficheiro de gravação corrompido.")
			return false
		notify("Gravação principal corrompida — restaurado o backup.")
	var stored_checksum := String((parsed as Dictionary).get("checksum", ""))
	if stored_checksum != "":
		var data := parsed as Dictionary
		data.erase("checksum")
		if JSON.stringify(data).sha256_text() != stored_checksum:
			notify("Gravação adulterada ou corrompida (checksum inválido).")
			return false
	_apply_save_dict(parsed)
	resume_pending = true
	if Keymap != null and Keymap.has_method("apply_custom_bindings"):
		Keymap.apply_custom_bindings(custom_bindings)
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
	threat_level = 0
	arena_environment = "arena"
	arena_enemy_count = 3
	arena_time_limit = 60.0
	arena_potions = true
	evaluation_history.clear()
	system_memory = {"best_style": "", "refusals": 0, "evaluations": 0}
	exams_done.clear()
	companions.clear()
	romance_id = ""
	for faction in REPUTATION_FACTIONS:
		reputation[faction] = 0
	region_known = {"noro": true}
	region_clears.clear()
	current_region = "noro"
	injury = 0
	if Keymap != null and Keymap.has_method("apply_custom_bindings"):
		Keymap.apply_custom_bindings(custom_bindings)
	stats_changed.emit()
