extends Node3D
## Personagem não-jogável: visual procedural, colisão simples e interação.

@export var npc_name: String = "Aldeão"
@export var dialogue_id: String = "aldeao"
@export var robe_color: Color = Color(0.4, 0.32, 0.25)

var _t: float = 0.0
var visual: Node3D

func _ready() -> void:
	add_to_group("npc")
	_build_visual()
	_build_collision()

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
		_:
			return dialogue_id

func _build_visual() -> void:
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
	if visual:
		visual.position.y = sin(_t * 1.8) * 0.025
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			var to_p := player.global_position - global_position
			to_p.y = 0.0
			if to_p.length() < 3.2 and to_p.length() > 0.1:
				var target := atan2(to_p.x, to_p.z)
				visual.rotation.y = lerp_angle(visual.rotation.y, target, 4.0 * delta)
