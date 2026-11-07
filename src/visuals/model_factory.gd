extends RefCounted
## Fábrica de modelos KayKit (CC0): instanciar, animar, tingir e o "juice" de
## combate (partículas, números de dano, flash).
##
## NOTA DE EIXO: o código de virado assume que os modelos olham para +Z
## (mesma convenção que visual.rotation.y = atan2(x, z)). Se algum modelo
## vier virado ao contrário, ajustar MODEL_FACING_OFFSET.

const MODEL_FACING_OFFSET := 0.0
const LOCOMOTION_CLIPS := ["Idle", "Walking_A", "Running_A", "Blocking", "Walk", "Gallop"]

# ------------------------------------------------------------ instanciar ----
static func spawn_env(parent: Node3D, path: String, pos: Vector3, rot_y: float, scale_factor: float, far_cull: float = 0.0) -> Node3D:
	var scene: PackedScene = load(path)
	if scene == null:
		push_warning("Modelo em falta: %s" % path)
		return null
	var inst := scene.instantiate() as Node3D
	if inst == null:
		push_warning("Cena não é Node3D: %s" % path)
		return null
	inst.position = pos
	inst.rotation.y = rot_y
	inst.scale = Vector3.ONE * scale_factor
	_set_shadows(inst)
	if far_cull > 0.0:
		_apply_far_cull(inst, far_cull)
	parent.add_child(inst)
	return inst

## Extensão de visibilidade por distância para decoração (v0.5): o motor
## deixa de desenhar o que está além de `cull` metros (física e lógica
## intactas — é só render). Robusto headless: propriedade nativa.
static func _apply_far_cull(root_node: Node3D, cull: float) -> void:
	if root_node is GeometryInstance3D:
		var gi := root_node as GeometryInstance3D
		gi.visibility_range_end = cull
		gi.visibility_range_end_margin = 4.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
	for child in root_node.find_children("*", "GeometryInstance3D", true, false):
		var gi := child as GeometryInstance3D
		gi.visibility_range_end = cull
		gi.visibility_range_end_margin = 4.0
		gi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED

static func spawn_character(parent: Node3D, path: String, pos: Vector3, tint: Color, scale_factor: float) -> Dictionary:
	var result := {"visual": null, "anim_player": null}
	var scene: PackedScene = load(path)
	if scene == null:
		push_warning("Personagem em falta: %s" % path)
		return result
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position = pos
	parent.add_child(visual)
	var model := scene.instantiate() as Node3D
	if model == null:
		push_warning("Cena não é Node3D: %s" % path)
		visual.queue_free()
		return result
	model.name = "Model"
	model.scale = Vector3.ONE * scale_factor
	model.rotation.y = MODEL_FACING_OFFSET
	visual.add_child(model)
	_set_shadows(model)
	if tint != Color.WHITE:
		tint_model(model, tint)
	var anim_player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if anim_player:
		for clip in LOCOMOTION_CLIPS:
			if anim_player.has_animation(clip):
				var anim := anim_player.get_animation(clip)
				if anim:
					anim.loop_mode = Animation.LOOP_LINEAR
		anim_player.play("Idle", 0.2)
	result["visual"] = visual
	result["anim_player"] = anim_player
	return result

static func _set_shadows(root: Node3D) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		mesh_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

static func tint_model(root: Node3D, tint: Color) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh == null:
			continue
		for i in range(mesh.get_surface_count()):
			var mat := mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = dup.albedo_color * tint
				mesh_node.set_surface_override_material(i, dup)

# ------------------------------------------------------------ animação ------
static func play_anim(anim_player: AnimationPlayer, clip: String, blend: float = 0.15, target_time: float = -1.0) -> void:
	if anim_player == null or not anim_player.has_animation(clip):
		return
	var anim := anim_player.get_animation(clip)
	var speed := 1.0
	if target_time > 0.05 and anim:
		speed = anim.length / target_time
	anim_player.play(clip, blend, speed)

static func flash_model(root: Node3D, duration: float = 0.12) -> void:
	var flashed: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		var mesh := mesh_node.mesh
		if mesh == null:
			continue
		for i in range(mesh.get_surface_count()):
			var mat := mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.emission_enabled = true
				dup.emission = Color(1.0, 0.95, 0.85)
				dup.emission_energy_multiplier = 1.6
				mesh_node.set_surface_override_material(i, dup)
				flashed.append(mesh_node)
	var tree := root.get_tree()
	if tree:
		var restore := func():
			for mesh_node in flashed:
				if is_instance_valid(mesh_node):
					for i in range(mesh_node.mesh.get_surface_count()):
						mesh_node.set_surface_override_material(i, null)
		tree.create_timer(duration).timeout.connect(restore)

# -------------------------------------------------------------- efeitos -----
static func spawn_hit_burst(tree: SceneTree, pos: Vector3, color: Color = Color(1.0, 0.75, 0.3)) -> void:
	var scene := tree.current_scene
	if scene == null:
		return
	var particles := GPUParticles3D.new()
	particles.amount = 16
	particles.one_shot = true
	particles.explosiveness = 0.9
	particles.lifetime = 0.55
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 180.0
	process.initial_velocity_min = 3.0
	process.initial_velocity_max = 6.5
	process.gravity = Vector3(0.0, -12.0, 0.0)
	process.scale_min = 0.5
	process.scale_max = 1.4
	process.color = color
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = color
	pmat.emission_enabled = true
	pmat.emission = color
	pmat.emission_energy_multiplier = 2.0
	pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = pmat
	particles.draw_pass_1 = quad
	scene.add_child(particles)
	particles.global_position = pos + Vector3(0.0, 1.2, 0.0)
	particles.emitting = true
	tree.create_timer(1.2).timeout.connect(particles.queue_free)

static func spawn_damage_number(tree: SceneTree, pos: Vector3, amount: int, color: Color = Color(1.0, 0.55, 0.35)) -> void:
	var scene := tree.current_scene
	if scene == null:
		return
	var label := Label3D.new()
	label.text = str(amount)
	label.font_size = 96
	label.modulate = color
	label.outline_size = 22
	label.outline_modulate = Color(0.1, 0.05, 0.02, 0.9)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0022
	scene.add_child(label)
	label.global_position = pos + Vector3(randf_range(-0.4, 0.4), 2.1, randf_range(-0.3, 0.3))
	var tween := tree.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y + 1.6, 0.9)
	tween.tween_property(label, "modulate:a", 0.0, 0.9)
	tween.chain().tween_callback(label.queue_free)
