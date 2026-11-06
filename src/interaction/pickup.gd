extends Node3D
## Fibra de Ruína — cristal âmbar recolhido para a missão da mãe.

var _t: float = 0.0
var _mesh: MeshInstance3D

func _ready() -> void:
	add_to_group("pickup")
	_t = randf() * TAU
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.62, 0.18)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.55, 0.1)
	mat.emission_energy_multiplier = 1.6
	mat.roughness = 0.35
	_mesh = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.3, 0.5, 0.3)
	_mesh.mesh = bm
	_mesh.material_override = mat
	_mesh.rotation = Vector3(0.3, 0.5, 0.2)
	add_child(_mesh)

func get_prompt() -> String:
	return "E — Recolher Fibra de Ruína"

func interact() -> void:
	if GameState.herb_quest_state != "active":
		GameState.notify("Um cristal âmbar pulsa com essência residual. (Precisas de um motivo — fala com a tua mãe)")
		return
	GameState.on_herb_collected()
	Audio.play("herb")
	queue_free()

func _process(delta: float) -> void:
	_t += delta
	if _mesh:
		_mesh.rotation.y += delta * 1.6
		_mesh.position.y = 0.15 + sin(_t * 2.2) * 0.08
