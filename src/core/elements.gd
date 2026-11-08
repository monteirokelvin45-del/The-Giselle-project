extends RefCounted

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
