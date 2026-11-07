extends RefCounted
## Retratos do elenco (v1.2, 2026-11-07) — assets/art/portraits/*_face.jpg,
## recortes «bust» derivados das folhas geradas por IA com a referência de
## personagem do dono (assets/art/kael_reference.jpg). As folhas completas
## ficam no mesmo diretório (*.jpg) para docs/arte.
## Se o falante não estiver na tabela (retrato ainda não gerado — Bram, Sena,
## Iven, Voss, Cadena, Vladimir), path_for devolve "" e o UI segue sem
## retrato — nunca um rosto errado. Ao gerar as folhas em falta, adicionar
## aqui os caminhos correspondentes (ver docs/CHARACTER.md).

const KAEL := {
	"neutral": "res://assets/art/portraits/kael_neutral_face.jpg",
	"determined": "res://assets/art/portraits/kael_determined_face.jpg",
	"pained": "res://assets/art/portraits/kael_pained_face.jpg",
	"soft": "res://assets/art/portraits/kael_soft_face.jpg",
	"battle": "res://assets/art/portraits/kael_battle_face.jpg",
}

const PORTRAITS := {
	"elen": "res://assets/art/portraits/elen_face.jpg",
	"tomás": "res://assets/art/portraits/tomas_face.jpg",
	"tomas": "res://assets/art/portraits/tomas_face.jpg",
	"garr": "res://assets/art/portraits/garr_face.jpg",
	"liora": "res://assets/art/portraits/liora_face.jpg",
	"dario": "res://assets/art/portraits/dario_face.jpg",
}
const KAEL_DEFAULT := "determined"

static func path_for(speaker: String, mood: String = "") -> String:
	var key := speaker.to_lower()
	if key == "" or key.contains("sistema"):
		return ""
	if key.contains("kael"):
		var m := mood if KAEL.has(mood) else KAEL_DEFAULT
		var path: String = KAEL[m]
		return path if ResourceLoader.exists(path) else ""
	for k in PORTRAITS:
		if key.contains(k):
			var p: String = PORTRAITS[k]
			return p if ResourceLoader.exists(p) else ""
	return ""

static func texture_for(speaker: String, mood: String = "") -> Texture2D:
	var path := path_for(speaker, mood)
	if path == "":
		return null
	return load(path) as Texture2D
