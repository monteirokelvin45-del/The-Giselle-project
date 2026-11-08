## v1.8 — Dados das Seis Disciplinas: tudo o que é numérico vive em
## res://src/balance/elements.json. Módulo estático sem estado.
const DISCIPLINE_NAMES := {
	"cinetica": "Carga Cinética",
	"ignea": "Queimadura Ígnea",
	"hidrica": "Saturação Hídrica",
	"vital": "Toxina Vital",
	"lumina": "Revelado Lúmina",
	"umbral": "Oculto Umbral",
}
const REACTION_NAMES := {
	"vapor_veyra": "Vapor de Veyra",
	"cavitacao": "Cavitação Profunda",
	"apagao": "Grande Apagão",
	"onda_choque": "Onda de Choque",
	"fotostase": "Luz Congelada",
	"eclipse": "Eclipse de um Segundo",
	"despertar_selado": "Despertar do Selado",
	"herda_vazio": "Herda do Vazio",
}

static func data() -> Dictionary:
	var path := "res://src/balance/elements.json"
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			return parsed
	return {}

static func status_def(id: String) -> Dictionary:
	var statuses = data().get("statuses", {})
	if statuses is Dictionary:
		var d = statuses.get(id, {})
		if d is Dictionary:
			return d
	return {}

static func enemy_discipline(type: String) -> String:
	var d = data().get("enemy_disciplines", {})
	if d is Dictionary:
		return String(d.get(type, ""))
	return ""

static func reaction(incoming_discipline: String, on_status: String) -> Dictionary:
	var reactions = data().get("reactions", [])
	if reactions is Array:
		for r in reactions:
			if r is Dictionary:
				if String(r.get("incoming", "")) == incoming_discipline and String(r.get("on", "")) == on_status:
					return r
	return {}

static func discipline_key(id: String) -> String:
	return DISCIPLINE_NAMES.get(id, id)

static func reaction_key(id: String) -> String:
	return REACTION_NAMES.get(id, id)
