extends Node3D
## Autómato de Treino — boneco de madeira do Sistema.
## Fica no grupo "enemy" para o jogador poder golpeá-lo; não morre e não contra-ataca.

var hp: float = 99999.0
var max_hp: float = 99999.0
var posture: float = 99999.0
var max_posture: float = 99999.0
var display_name: String = "Autómato de Treino"
var _wobble: float = 0.0
var visual: Node3D

func _ready() -> void:
	add_to_group("enemy")
	visual = Node3D.new()
	add_child(visual)
	var wood := _mat(Color(0.5, 0.38, 0.22))
	var burlap := _mat(Color(0.6, 0.52, 0.36))
	var dark := _mat(Color(0.35, 0.27, 0.16))
	var target := _mat(Color(0.85, 0.2, 0.15), 0.0, 0.5, Color(0.8, 0.15, 0.1), 1.8)
	_cyl(visual, 0.16, 0.22, 1.15, Vector3(0, 0.57, 0), wood)
	_box(visual, Vector3(1.15, 0.95, 0.6), Vector3(0, 1.65, 0), burlap)
	_box(visual, Vector3(0.4, 0.22, 0.65), Vector3(0, 1.22, 0), dark)
	_sphere(visual, 0.28, Vector3(0, 2.35, 0), burlap)
	_cyl(visual, 0.32, 0.32, 0.05, Vector3(0, 1.65, 0.31), target, Vector3(PI / 2.0, 0, 0))

func take_damage(_amount: float, _posture_dmg: float, _from: Node3D = null) -> void:
	_wobble = 1.0

func take_posture(_amount: float) -> void:
	_wobble = maxf(_wobble, 0.8)

func stagger_brief(_duration: float) -> void:
	pass

func interrupt_cast() -> void:
	pass

func _process(delta: float) -> void:
	if _wobble > 0.0:
		_wobble = maxf(0.0, _wobble - delta * 1.5)
	if visual:
		visual.rotation.z = sin(_wobble * 16.0) * 0.3 * _wobble
		var s := 1.0 + _wobble * 0.06
		visual.scale = Vector3(s, 1.0 / s, s)

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.85, emissive: Color = Color.BLACK, energy: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emissive != Color.BLACK:
		m.emission_enabled = true
		m.emission = emissive
		m.emission_energy_multiplier = energy
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

func _cyl(parent: Node3D, r_top: float, r_bottom: float, height: float, pos: Vector3, mat: StandardMaterial3D, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)

func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
