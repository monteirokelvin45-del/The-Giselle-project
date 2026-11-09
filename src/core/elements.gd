## Dados das Seis Disciplinas (v1.8 «As Seis Disciplinas»): tudo o que é
## numérico vive em res://src/balance/elements.json — ajusta e joga, sem
## tocar em código. Módulo estático (sem autoload): sem estado de cena,
## só leitura de JSON cacheada. Não referencia nós; operações de cena
## (dano, stun, VFX) vivem em enemy.gd via esta tabela.
static func data() -> Dictionary:
	var path := "res://src/balance/elements.json"
	if FileAccess.file_exists(path):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			return parsed
	return {}

static func disciplines() -> Dictionary:
	var d: Variant = data().get("disciplines", {})
	return d if d is Dictionary else {}

static func statuses() -> Dictionary:
	var d: Variant = data().get("statuses", {})
	return d if d is Dictionary else {}

static func status_def(id: String) -> Dictionary:
	var d: Variant = statuses().get(id, {})
	return d if d is Dictionary else {}

static func enemy_discipline(type: String) -> String:
	var d: Variant = data().get("enemy_disciplines", {})
	if d is Dictionary:
		return String((d as Dictionary).get(type, ""))
	return ""

static func reaction(incoming_discipline: String, on_status: String) -> Dictionary:
	var d: Variant = data().get("reactions", [])
	if d is Array:
		for r in d as Array:
			if r is Dictionary:
				var rd: Dictionary = r
				if String(rd.get("incoming", "")) == incoming_discipline and String(rd.get("on", "")) == on_status:
					return rd
	return {}

## Nomes visíveis vivem aqui (não no JSON): o gate de i18n extraí-os dos
## .gd — assim "disciplina já traduzida" é garantido por ferramenta.
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

static func discipline_key(id: String) -> String:
	return DISCIPLINE_NAMES.get(id, id)

static func reaction_key(id: String) -> String:
	return REACTION_NAMES.get(id, id)

static func discipline_color(id: String) -> Color:
	var hex := String(disciplines().get(id, {}).get("color", "#FFFFFF"))
	return Color(hex)
