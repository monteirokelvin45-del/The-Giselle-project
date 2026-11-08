extends Node3D
## Multidão de fundo (v1.12) — o Vale e o campus respiram gente.
## Sem interação, sem colisor, sem diálogo: são figurantes que caminham
## devagar em anel curto à volta do seu posto. KayKit (5 modelos) com
## tintas/escalas próprias — zero assets novos.

const MODELS := [
	"res://assets/models/characters/Barbarian.glb",
	"res://assets/models/characters/Mage.glb",
	"res://assets/models/characters/Rogue.glb",
	"res://assets/models/characters/Knight.glb",
	"res://assets/models/characters/Rogue_Hooded.glb",
]

@export var anchor: Vector3 = Vector3.ZERO
@export var wander_radius: float = 2.0
@export var model_index: int = 0
@export var tint: Color = Color(0.42, 0.38, 0.34)
@export var scale_factor: float = 0.95

var _t: float = 0.0
var _waypoint: Vector3 = Vector3.ZERO
var _wait: float = 0.0
var visual: Node3D = null

func _ready() -> void:
	add_to_group("crowd")
	_waypoint = _pick_waypoint()
	_wait = randf() * 3.0
	_build_visual()

func _build_visual() -> void:
	var mf := preload("res://src/visuals/model_factory.gd")
	var result: Dictionary = mf.spawn_character(self, String(MODELS[model_index % MODELS.size()]), Vector3.ZERO, tint, scale_factor)
	visual = result["visual"]

func _pick_waypoint() -> Vector3:
	var a := randf() * TAU
	return anchor + Vector3(cos(a) * wander_radius, 0.0, sin(a) * wander_radius)

func _process(delta: float) -> void:
	_t += delta
	if _wait > 0.0:
		_wait -= delta
		_face_player_if_close(delta)
		return
	var to_t := _waypoint - position
	to_t.y = 0.0
	if to_t.length() < 0.22:
		_waypoint = _pick_waypoint()
		_wait = randf_range(1.5, 5.5)
		return
	var dir := to_t.normalized()
	position += dir * 0.55 * delta
	if visual != null:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 5.0 * delta)
		visual.position.y = sin(_t * 1.7) * 0.02
	_face_player_if_close(delta)

func _face_player_if_close(delta: float) -> void:
	if visual == null:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var to_p = player.global_position - global_position
	to_p.y = 0.0
	if to_p.length() < 4.0 and to_p.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(to_p.x, to_p.z), 4.0 * delta)
