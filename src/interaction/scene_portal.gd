extends Node3D
## Portal de transição entre cenas (opção de exportação no editor ou por código).

@export var target_scene: String = "res://scenes/main.tscn"
@export var prompt_text: String = "E — Viajar"
@export var ring_color: Color = Color(0.9, 0.75, 0.3)
@export var glow_color: Color = Color(0.85, 0.68, 0.25)

var _t: float = 0.0
var _ring: MeshInstance3D

func _ready() -> void:
	add_to_group("scene_portal")
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.15
	tm.outer_radius = 1.45
	_ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ring_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 2.0
	_ring.material_override = mat
	add_child(_ring)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.15
	cyl.bottom_radius = 1.15
	cyl.height = 0.05
	disc.mesh = cyl
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(ring_color.r, ring_color.g, ring_color.b, 0.4)
	disc_mat.emission_enabled = true
	disc_mat.emission = glow_color
	disc_mat.emission_energy_multiplier = 1.1
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override = disc_mat
	disc.rotation.x = PI / 2.0
	add_child(disc)

func get_prompt() -> String:
	return prompt_text

func interact() -> void:
	GameState.notify("Atravessando o limiar...")
	get_tree().change_scene_to_file(target_scene)

func _process(delta: float) -> void:
	_t += delta
	if _ring:
		_ring.rotation.z += delta * 0.55
	position.y = 1.7 + sin(_t * 1.5) * 0.12
