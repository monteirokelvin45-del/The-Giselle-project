extends Node3D
## Ponto de descanso: recupera vida, fôlego e trata lesões.

var _t: float = 0.0

func _ready() -> void:
	add_to_group("rest_point")
	var bed := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.6, 0.35, 2.4)
	bed.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.3, 0.42)
	mat.roughness = 0.9
	bed.material_override = mat
	bed.position.y = 0.45
	add_child(bed)
	var pillow := MeshInstance3D.new()
	var pbox := BoxMesh.new()
	pbox.size = Vector3(1.3, 0.18, 0.5)
	pillow.mesh = pbox
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.85, 0.83, 0.78)
	pillow.material_override = pmat
	pillow.position = Vector3(0.0, 0.58, -0.85)
	add_child(pillow)

func get_prompt() -> String:
	return "E — Descansar (alivia 1 nível de lesão; repõe fadiga)"

func interact() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set("hp", GameState.max_hp())
		player.set("stamina", GameState.max_stamina())
	GameState.rest()
	GameState.notify("Descansaste. As dores aliviaram (−1 nível de lesão); o treino abre de novo.")
	Audio.play("potion", -4.0, 0.7)
