extends Node3D
## Portal de saída da Sala Branca.

var _ring: MeshInstance3D
var _t: float = 0.0

func _ready() -> void:
	add_to_group("exit_portal")
	_ring = MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 1.15
	tm.outer_radius = 1.45
	_ring.mesh = tm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.9, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.85, 0.8)
	mat.emission_energy_multiplier = 2.2
	_ring.material_override = mat
	add_child(_ring)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.15
	cyl.bottom_radius = 1.15
	cyl.height = 0.05
	disc.mesh = cyl
	var disc_mat := StandardMaterial3D.new()
	disc_mat.albedo_color = Color(0.7, 1.0, 0.95, 0.4)
	disc_mat.emission_enabled = true
	disc_mat.emission = Color(0.5, 0.9, 0.85)
	disc_mat.emission_energy_multiplier = 1.2
	disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disc.material_override = disc_mat
	disc.rotation.x = PI / 2.0
	add_child(disc)

func get_prompt() -> String:
	return "E — Sair do Sistema"

func interact() -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("open_evaluation"):
		scene.open_evaluation()

func _process(delta: float) -> void:
	_t += delta
	if _ring:
		_ring.rotation.z += delta * 0.7
	position.y = 1.7 + sin(_t * 1.6) * 0.12
