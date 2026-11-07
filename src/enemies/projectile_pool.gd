## Pool de projéteis arcanos (v1.7 «Qualidade & Performance»): evita
## alocar/destruir Area3D a cada disparo — os conjuradores (Mago de Cinza,
## Brasa de Ruína) são os maiores produtores de lixo de nós num combate cheio.
## Só recursos cacheados (malha, colisor, materiais) e os nós do próprio pool —
## sem estado de jogo aqui. O pool vive fora da cena enquanto está em stash.
static var _stash: Array[Area3D] = []
static var _mesh: SphereMesh = null
static var _shape: SphereShape3D = null
static var _mat_default: StandardMaterial3D = null
static var _mat_brasa: StandardMaterial3D = null

static func _cached_resources() -> void:
	if _mesh == null:
		_mesh = SphereMesh.new()
		_mesh.radius = 0.22
		_mesh.height = 0.44
		_shape = SphereShape3D.new()
		_shape.radius = 0.28
		_mat_default = _make_material(Color(0.6, 0.3, 0.95), Color(0.6, 0.25, 0.95))
		_mat_brasa = _make_material(Color(0.98, 0.5, 0.12), Color(0.98, 0.42, 0.08))

static func _make_material(albedo: Color, emission: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.emission_enabled = true
	m.emission = emission
	m.emission_energy_multiplier = 2.5
	m.roughness = 0.3
	return m

static func _build() -> Area3D:
	_cached_resources()
	var p := Area3D.new()
	p.name = "ProjectilePoolNode"
	p.set_script(load("res://src/enemies/projectile.gd"))
	p.collision_layer = 8
	p.collision_mask = 3
	var mesh := MeshInstance3D.new()
	mesh.name = "Mesh"
	mesh.mesh = _mesh
	mesh.material_override = _mat_default
	p.add_child(mesh)
	var shape := CollisionShape3D.new()
	shape.shape = _shape
	p.add_child(shape)
	return p

## Devolve um projétil pronto a usar (visível, a colidir, com timer cheio).
## `brasa` pinta o projétil com o material da Brasa de Ruína.
static func acquire(tree: SceneTree, brasa: bool) -> Area3D:
	_cached_resources()
	var p: Area3D
	if not _stash.is_empty():
		p = _stash.pop_back()
		tree.current_scene.add_child(p)
	else:
		p = _build()
		tree.current_scene.add_child(p)
	var mesh := p.get_node_or_null("Mesh") as MeshInstance3D
	if mesh != null:
		mesh.material_override = _mat_brasa if brasa else _mat_default
	p.visible = true
	p.monitoring = true
	p.collision_layer = 8
	p.collision_mask = 3
	p.rotation = Vector3.ZERO
	p.set("life", 4.0)
	return p

## Esconde e estaciona o projétil; nunca destrói o nó.
static func release(p: Area3D) -> void:
	if p == null or not is_instance_valid(p):
		return
	if p.get_parent() != null:
		p.get_parent().remove_child(p)
	p.visible = false
	p.monitoring = false
	p.set("life", 0.0)
	_stash.append(p)

## Só para testes/CI: quantos projétis estão estacionados.
static func stash_size() -> int:
	return _stash.size()
