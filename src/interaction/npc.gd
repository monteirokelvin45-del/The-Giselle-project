extends Node3D
## Personagem não-jogável: modelo KayKit (CC0) com fallback procedural, colisão simples e interação.

@export var npc_name: String = "Aldeão"
@export var dialogue_id: String = "aldeao"
@export var robe_color: Color = Color(0.4, 0.32, 0.25)
@export var wander_radius: float = 2.2   # 0 = enraizado (vendedores, quest-givers)

const ROOTED_IDS := ["elen", "garr", "dario", "voss", "liora", "liora_academia", "bram", "sena", "iven"]

var _t: float = 0.0
var visual: Node3D
var _self_rids: Array[RID] = []
var _anchor: Vector3 = Vector3.ZERO
var _waypoints: Array[Vector3] = []
var _wp_index: int = 0
var _wait_timer: float = 0.0

## Modelos KayKit (CC0): identidade visual por personagem
const NPC_MODELS := {
	"elen": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(0.9, 1.0, 0.85), "scale": 0.95},
	"garr": {"path": "res://assets/models/characters/Barbarian.glb", "tint": Color(0.92, 0.85, 0.78), "scale": 1.0},
	"aldeao": {"path": "res://assets/models/characters/Rogue.glb", "tint": Color(0.85, 0.9, 0.75), "scale": 0.98},
	"liora": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(1.0, 0.97, 0.82), "scale": 1.0},
	"dario": {"path": "res://assets/models/characters/Knight.glb", "tint": Color(0.8, 0.85, 1.0), "scale": 1.1},
	"dario_academia": {"path": "res://assets/models/characters/Knight.glb", "tint": Color(0.8, 0.85, 1.0), "scale": 1.1},
	"bram": {"path": "res://assets/models/characters/Barbarian.glb", "tint": Color(0.85, 0.62, 0.4), "scale": 1.08},
	"sena": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(0.7, 0.95, 0.65), "scale": 0.96},
	"iven": {"path": "res://assets/models/characters/Rogue.glb", "tint": Color(0.6, 0.75, 1.0), "scale": 1.0},
	"liora_academia": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(0.82, 0.88, 1.0), "scale": 1.0},
	"voss": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(0.55, 0.5, 0.7), "scale": 0.94},
}

func _ready() -> void:
	add_to_group("npc")
	if dialogue_id in ROOTED_IDS:
		wander_radius = 0.0
	_prepare_loop()
	_build_visual()
	_build_collision()

func _prepare_loop() -> void:
	if wander_radius <= 0.0:
		return
	_anchor = global_position
	var seed_angle := fmod(absf(_anchor.x * 12.9898 + _anchor.z * 78.233), 1.0) * TAU
	for i in range(3):
		var a := seed_angle + TAU * float(i) / 3.0
		var r := wander_radius * (0.55 + 0.45 * fmod(absf(seed_angle * (float(i) + 1.7) * 39.7), 1.0))
		_waypoints.push_back(_anchor + Vector3(cos(a) * r, 0.0, sin(a) * r))
	_wait_timer = randf_range(1.0, 4.0)

const COMPANION_IDS := {"bram": "bram", "sena": "sena", "iven": "iven", "liora_academia": "liora"}
const COMPANION_EXAMS := {"bram": "duelo", "sena": "floresta", "iven": "labirinto", "liora_academia": "equipas"}

## Árvore certa para um companheiro conforme o estado da prova e a lealdade.
func _companion_tree() -> String:
	var cid := String(COMPANION_IDS.get(dialogue_id, ""))
	var exam := String(COMPANION_EXAMS.get(dialogue_id, ""))
	if not GameState.exams_done.has(exam):
		return dialogue_id + "_pre"
	if GameState.romance_id == "" and GameState.companion_loyalty(cid) >= 80:
		return dialogue_id + "_romance"
	return dialogue_id + "_done"

func get_prompt() -> String:
	return "E — Falar com %s" % npc_name

func interact() -> void:
	Dialogue.start(_resolve_tree())

func _resolve_tree() -> String:
	match dialogue_id:
		"elen":
			return "elen" if GameState.main_stage == 0 else "elen_idle"
		"garr":
			return "garr" if GameState.main_stage < 2 else "garr_idle"
		"liora":
			return "liora_after" if GameState.artifact_unlocked else "liora"
		"dario":
			if GameState.main_stage >= 6:
				return "dario_done"
			elif GameState.main_stage == 5:
				return "dario_mid"
			elif GameState.main_stage == 4:
				return "dario"
			return "dario_early"
		"dario_academia":
			return "dario_academia"
		"bram", "sena", "iven", "liora_academia":
			return _companion_tree()
		"voss":
			return "voss" if not GameState.exams_done.has("voss_met") else "voss_after"
		_:
			return dialogue_id

func _build_visual() -> void:
	var mf := preload("res://src/visuals/model_factory.gd")
	var cfg: Dictionary = NPC_MODELS.get(dialogue_id, {})
	if not cfg.is_empty():
		var result: Dictionary = mf.spawn_character(self, cfg["path"], Vector3.ZERO, cfg["tint"], cfg["scale"])
		if result["visual"] != null:
			visual = result["visual"]
			return
	_build_procedural()

func _build_procedural() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	var skin := _mat(Color(0.85, 0.62, 0.45))
	var robe := _mat(robe_color)
	var hair := _mat(Color(0.15, 0.11, 0.08))
	_box(visual, Vector3(0.6, 0.78, 0.34), Vector3(0, 1.05, 0), robe)
	var legs := _mat(Color(robe_color.r * 0.6, robe_color.g * 0.6, robe_color.b * 0.6))
	_box(visual, Vector3(0.26, 0.62, 0.26), Vector3(-0.16, 0.36, 0), legs)
	_box(visual, Vector3(0.26, 0.62, 0.26), Vector3(0.16, 0.36, 0), legs)
	_box(visual, Vector3(0.36, 0.36, 0.34), Vector3(0, 1.56, 0), skin)
	_box(visual, Vector3(0.4, 0.13, 0.37), Vector3(0, 1.76, 0), hair)
	for sx in [-1, 1]:
		_box(visual, Vector3(0.14, 0.6, 0.14), Vector3(sx * 0.4, 1.06, 0), robe)

func _build_collision() -> void:
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var cs := CapsuleShape3D.new()
	cs.radius = 0.4
	cs.height = 1.75
	col.shape = cs
	col.position.y = 0.88
	body.add_child(col)
	add_child(body)
	_self_rids = [body.get_rid()]

## Rotina simples em anel: vagueia entre 3 pontos à volta do posto,
## para junto de cada um, e fica quieto quando o jogador está perto.
func _update_routine(delta: float) -> void:
	if _waypoints.is_empty():
		return
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.global_position.distance_to(global_position) < 2.1:
		return
	if _wait_timer > 0.0:
		_wait_timer -= delta
		return
	var target := _waypoints[_wp_index]
	var to_t := target - global_position
	to_t.y = 0.0
	if to_t.length() < 0.18:
		_wp_index = (_wp_index + 1) % _waypoints.size()
		_wait_timer = randf_range(2.0, 6.0)
		return
	var want := to_t.normalized()
	var dir := _walkable_dir(want)
	if dir.length_squared() < 0.001:
		return
	var step := dir * 0.55 * delta
	global_position = global_position + step
	if visual:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(step.x, step.z), 5.0 * delta)

## Desvio de obstáculos (sec. 9): raio à frente; se houver bloqueio, tenta
## desviar a ±40°/±80°/±120°. Não é pathfinding A* (exigiria navmesh baked);
## é o suficiente para não atravessarem props e muros.
func _walkable_dir(want: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	if space == null:
		return want
	var from := global_position + Vector3(0.0, 0.9, 0.0)
	var angles: Array[float] = [0.0, 0.7, -0.7, 1.4, -1.4, 2.1, -2.1]
	for a in angles:
		var dir := want.rotated(Vector3.UP, a)
		var params := PhysicsRayQueryParameters3D.create(from, from + dir * 1.5, 1)
		params.exclude = _self_rids
		if space.intersect_ray(params).is_empty():
			return dir
	return Vector3.ZERO

func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)

func _process(delta: float) -> void:
	_t += delta
	_update_routine(delta)
	if visual:
		visual.position.y = sin(_t * 1.8) * 0.025
		var player = get_tree().get_first_node_in_group("player")
		if player != null:
			var to_p: Vector3 = player.global_position - global_position
			to_p.y = 0.0
			if to_p.length() < 3.2 and to_p.length() > 0.1:
				var target := atan2(to_p.x, to_p.z)
				visual.rotation.y = lerp_angle(visual.rotation.y, target, 4.0 * delta)
