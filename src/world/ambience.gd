extends Node3D
## Ambiente vivo v1.1 — vento e vida, sem shaders custom (GLES3-safe):
##  · grupo "sway": vegetação balança suavemente (base calculada, nunca acumula)
##  · grupo "bob":  objetos levitam (ilhas flutuantes, detritos)
##  · grupo "spin": rodam devagar à volta do eixo Y (feixe do farol)
##  · bandos de pássaros (V duplo) a circling centros; centelhas/poeira/folhas
##    em GPUParticles3D nativas.
## Registo é feito no spawn (model_factory.spawn_env) e em helpers abaixo.

const SWAY_GROUP := "ambience_sway"
const BOB_GROUP := "ambience_bob"
const SPIN_GROUP := "ambience_spin"
const FLOCK_GROUP := "ambience_flock"

var _time: float = 0.0
var _flocks: Array[Dictionary] = []
var _sway_cache: Array = []
var _bob_cache: Array = []
var _spin_cache: Array = []
var _cache_built: bool = false

func _ready() -> void:
	# Fase aleatória para que cenas irmãs não batam a mesma onda
	_time = randf() * 20.0

static func swayable(node: Node3D, amp: float, speed: float) -> void:
	node.add_to_group(SWAY_GROUP)
	node.set_meta("sway_amp", amp)
	node.set_meta("sway_speed", speed)
	node.set_meta("sway_phase", randf() * TAU)
	node.set_meta("sway_base_x", node.rotation.x)
	node.set_meta("sway_base_z", node.rotation.z)

static func bobber(node: Node3D, amp: float, speed: float) -> void:
	node.add_to_group(BOB_GROUP)
	node.set_meta("bob_amp", amp)
	node.set_meta("bob_speed", speed)
	node.set_meta("bob_phase", randf() * TAU)
	node.set_meta("bob_base_y", node.position.y)

static func spinner(node: Node3D, speed: float) -> void:
	node.add_to_group(SPIN_GROUP)
	node.set_meta("spin_speed", speed)

## Bando de 3 pássaros em V a circular um centro (silhueta contra o céu).
func add_flock(center: Vector3, radius: float, speed: float, height: float = 0.0) -> void:
	var pivot := Node3D.new()
	pivot.position = center + Vector3(0.0, height, 0.0)
	add_child(pivot)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.08, 0.07, 0.09)
	dark.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dark.roughness = 1.0
	var birds: Array[Node3D] = []
	for i in range(3):
		var bird := Node3D.new()
		var offset := TAU * float(i) / 3.0
		for side in [-1.0, 1.0]:
			var wing := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.72, 0.05, 0.16)
			wing.mesh = bm
			wing.material_override = dark
			wing.position = Vector3(side * 0.38, 0.0, 0.0)
			wing.rotation.z = side * 0.42
			bird.add_child(wing)
		var angle := speed * _time + offset
		bird.position = Vector3(cos(angle) * radius, sin(angle * 2.0) * 0.6, sin(angle) * radius)
		pivot.add_child(bird)
		birds.append(bird)
	_flocks.append({"pivot": pivot, "radius": radius, "speed": speed, "birds": birds, "phase": randf() * TAU})

## Emissores de partículas nativas (folhas, pétalas, brasas, pó, vaga-lumes,
## motes do Abismo). `kind` escolhe paleta/física.
func add_emitter(kind: String, center: Vector3, extents: Vector3, amount: int = 26) -> void:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = 2.6
	particles.local_coords = false
	particles.position = center + Vector3(0.0, extents.y * 0.5, 0.0)
	particles.visibility_aabb = AABB(Vector3(-extents.x, -extents.y, -extents.z), extents * 2.0)
	var mat := ParticleProcessMaterial.new()
	var drop := BoxMesh.new()
	drop.size = Vector3(0.09, 0.02, 0.13)
	match kind:
		"leaves":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(extents.x, 0.5, extents.z)
			mat.direction = Vector3(0.3, -1.0, 0.15)
			mat.spread = 28.0
			mat.gravity = Vector3(0.6, -2.6, 0.2)
			mat.initial_velocity_min = 0.4
			mat.initial_velocity_max = 1.3
			mat.angular_velocity_min = -130.0
			mat.angular_velocity_max = 130.0
			drop.material = _pmat(Color(0.86, 0.55, 0.18), 0.0)
		"petals":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(extents.x, 0.4, extents.z)
			mat.direction = Vector3(0.2, -1.0, 0.1)
			mat.spread = 24.0
			mat.gravity = Vector3(0.4, -1.9, 0.2)
			mat.initial_velocity_min = 0.4
			mat.initial_velocity_max = 1.1
			mat.angular_velocity_min = -90.0
			mat.angular_velocity_max = 90.0
			drop.material = _pmat(Color(0.98, 0.82, 0.88), 0.0)
		"embers":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(extents.x, 0.3, extents.z)
			mat.direction = Vector3(0.05, 1.0, 0.05)
			mat.spread = 18.0
			mat.gravity = Vector3(0.0, 1.4, 0.0)
			mat.initial_velocity_min = 0.6
			mat.initial_velocity_max = 1.6
			drop.material = _pmat(Color(1.0, 0.5, 0.1), 2.6)
		"dust":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(extents.x, 0.3, extents.z)
			mat.direction = Vector3(0.8, 0.25, 0.2)
			mat.spread = 40.0
			mat.gravity = Vector3(0.0, -0.12, 0.0)
			mat.initial_velocity_min = 0.5
			mat.initial_velocity_max = 1.4
			drop.material = _pmat(Color(0.85, 0.74, 0.5), 0.0)
		"fireflies":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = extents
			mat.direction = Vector3(0.0, 0.05, 0.0)
			mat.spread = 180.0
			mat.gravity = Vector3.ZERO
			mat.initial_velocity_min = 0.15
			mat.initial_velocity_max = 0.5
			drop.material = _pmat(Color(0.78, 1.0, 0.35), 2.2)
		"snow":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = Vector3(extents.x, 0.4, extents.z)
			mat.direction = Vector3(0.18, -1.0, 0.05)
			mat.spread = 7.0
			mat.gravity = Vector3(0.35, -1.6, 0.1)
			mat.initial_velocity_min = 0.4
			mat.initial_velocity_max = 1.0
			drop.material = _pmat(Color(0.95, 0.97, 1.0), 0.0)
		"clouds":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = extents
			mat.direction = Vector3(0.0, 0.1, 0.0)
			mat.spread = 90.0
			mat.gravity = Vector3(0.0, 0.0, 0.0)
			mat.initial_velocity_min = 0.08
			mat.initial_velocity_max = 0.3
			drop.size = Vector3(0.26, 0.08, 0.4)
			drop.material = _pmat(Color(0.96, 0.97, 1.0), 0.0)
		"motes":
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = extents
			mat.direction = Vector3(0.0, 0.15, 0.0)
			mat.spread = 180.0
			mat.gravity = Vector3(0.0, 0.35, 0.0)
			mat.initial_velocity_min = 0.2
			mat.initial_velocity_max = 0.7
			drop.material = _pmat(Color(0.65, 0.35, 1.0), 2.4)
		_:
			mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
			mat.emission_box_extents = extents
			mat.direction = Vector3(0.0, 1.0, 0.0)
			drop.material = _pmat(Color(1.0, 1.0, 1.0), 1.0)
	particles.process_material = mat
	particles.draw_pass_1 = drop
	add_child(particles)

func _pmat(color: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_receive_shadows = true
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = energy
	return m

func _process(delta: float) -> void:
	_time += delta
	if not _cache_built:
		_cache_built = true
		_sway_cache = get_tree().get_nodes_in_group(SWAY_GROUP)
		_bob_cache = get_tree().get_nodes_in_group(BOB_GROUP)
		_spin_cache = get_tree().get_nodes_in_group(SPIN_GROUP)
	for node in _sway_cache:
		if not is_instance_valid(node):
			continue
		var amp: float = float(node.get_meta("sway_amp", 0.02))
		var speed: float = float(node.get_meta("sway_speed", 1.15))
		var phase: float = float(node.get_meta("sway_phase", 0.0))
		var base_x: float = float(node.get_meta("sway_base_x", 0.0))
		var base_z: float = float(node.get_meta("sway_base_z", 0.0))
		node.rotation.x = base_x + sin(_time * speed + phase) * amp
		node.rotation.z = base_z + cos(_time * speed * 0.83 + phase * 1.7) * amp * 0.7
	for node in _bob_cache:
		if not is_instance_valid(node):
			continue
		var amp: float = float(node.get_meta("bob_amp", 0.3))
		var speed: float = float(node.get_meta("bob_speed", 0.55))
		var phase: float = float(node.get_meta("bob_phase", 0.0))
		var base_y: float = float(node.get_meta("bob_base_y", 0.0))
		node.position.y = base_y + sin(_time * speed + phase) * amp
	for node in _spin_cache:
		if not is_instance_valid(node):
			continue
		node.rotation.y += delta * float(node.get_meta("spin_speed", 0.45))
	for flock in _flocks:
		var pivot: Node3D = flock["pivot"]
		pivot.rotation.y += delta * float(flock["speed"]) * 0.35
		for i in range(flock["birds"].size()):
			var bird: Node3D = flock["birds"][i]
			bird.position.y = sin(_time * 1.7 + float(i) * 2.1 + float(flock["phase"])) * 0.7
