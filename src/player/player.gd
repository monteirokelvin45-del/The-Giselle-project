extends CharacterBody3D
## Kael Noro — controlador de terceira pessoa e combate.

signal attack_performed()
signal attack_landed()

const GRAVITY := 26.0
const CAM_DISTANCE := 4.6
const CAM_HEIGHT := 1.55

var hp: float = 100.0
var stamina: float = 100.0

# Combate / movimento
var _yaw: float = 0.0
var _pitch: float = 0.42
var _cam_dist: float = CAM_DISTANCE
var _dodge_timer: float = 0.0
var _dodge_cooldown: float = 0.0
var _invuln_timer: float = 0.0
var _attack_cooldown: float = 0.0
var _attack_cooldown_heavy: float = 0.0
var _combo: int = 0
var _combo_reset: float = 0.0
var _chain_cooldown: float = 0.0
var _blocking: bool = false
var _block_press_time: float = -10.0
var _dodge_dir: Vector3 = Vector3.FORWARD
var _lunge: Vector3 = Vector3.ZERO
var _knockback: Vector3 = Vector3.ZERO
var _facing: float = 0.0
var _breath_t: float = 0.0

var _anim_player: AnimationPlayer = null
var _anim_lock: float = 0.0
var _attack_anim_flip: bool = false
var _shake: float = 0.0
var _dying: bool = false

var locked_enemy: Node3D = null
var current_interactable: Node3D = null

# Estatísticas para a avaliação do Sistema
var total_swings: int = 0
var total_hits: int = 0
var total_damage_taken: float = 0.0
var total_parries: int = 0
var light_hits: int = 0
var heavy_hits: int = 0
var hits_taken_attacking: int = 0
var first_hit_msec: int = -1

# Habilidades dos companheiros (canais 1–4)
var ability_cooldowns := {"liora": 0.0, "bram": 0.0, "sena": 0.0, "iven": 0.0}
var _heal_over_time: float = 0.0
const ABILITY_INFO := {
	"liora": {"name": "Murmúrio de Véu", "desc": "Invulnerável 3,5s +15 Ruptura", "cd": 24.0, "key": "1"},
	"bram": {"name": "Eco de Forja", "desc": "Atordoa e parte postura numa área", "cd": 18.0, "key": "2"},
	"sena": {"name": "Seiva", "desc": "+40 vida ao longo de 4s", "cd": 30.0, "key": "3"},
	"iven": {"name": "Passo de Horizonte", "desc": "Avança 6m + fôlego completo", "cd": 20.0, "key": "4"},
}

var visual: Node3D
var camera: Camera3D
var cam_ray: RayCast3D

func _ready() -> void:
	add_to_group("player")
	hp = GameState.max_hp()
	stamina = GameState.max_stamina()
	if GameState.resume_pending:
		if GameState.saved_hp > 0.0:
			hp = minf(GameState.saved_hp, GameState.max_hp())
			stamina = minf(GameState.saved_stamina, GameState.max_stamina())
		elif not GameState.system_return_pending:
			pass
		global_position = GameState.system_return if GameState.system_return_pending else GameState.saved_position
		GameState.resume_pending = false
		GameState.system_return_pending = false
	elif GameState.system_return_pending:
		global_position = GameState.system_return
		GameState.system_return_pending = false
	_build_visual()
	_build_camera()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func reset_combat_stats() -> void:
	total_swings = 0
	total_hits = 0
	total_damage_taken = 0.0
	total_parries = 0
	light_hits = 0
	heavy_hits = 0
	hits_taken_attacking = 0
	first_hit_msec = -1

func heal_external(amount: float) -> void:
	hp = minf(GameState.max_hp(), hp + amount)

func _use_ability(id: String) -> void:
	if not GameState.companions.has(id):
		GameState.notify("Ainda não tens este companheiro.")
		return
	if float(ability_cooldowns.get(id, 0.0)) > 0.0:
		GameState.notify("Habilidade em recarga (%.0fs)." % float(ability_cooldowns[id]))
		return
	match id:
		"liora":
			_invuln_timer = maxf(_invuln_timer, 3.5)
			GameState.add_rupture(15.0)
			GameState.notify("Murmúrio de Véu — invulnerável por 3,5s.")
			Audio.play("rupture", -4.0)
			ability_cooldowns[id] = 24.0
		"bram":
			var mf := preload("res://src/visuals/model_factory.gd")
			var hit := 0
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if not is_instance_valid(enemy):
					continue
				var to_e: Vector3 = enemy.global_position - global_position
				to_e.y = 0.0
				if to_e.length() <= 4.5:
					if enemy.has_method("take_posture"):
						enemy.take_posture(50.0 * GameState.posture_mult())
					if enemy.has_method("stagger_brief"):
						enemy.stagger_brief(1.2)
					hit += 1
			mf.spawn_hit_burst(get_tree(), global_position + Vector3(0.0, 1.2, 0.0), Color(0.95, 0.8, 0.4))
			add_shake(0.7)
			GameState.notify("Eco de Forja — %d inimigos atordoados!" % hit)
			Audio.play("heavy_hit", -2.0)
			ability_cooldowns[id] = 18.0
		"sena":
			_heal_over_time = 40.0
			GameState.notify("Seiva — +40 vida ao longo de 4s.")
			Audio.play("potion", -6.0)
			ability_cooldowns[id] = 30.0
		"iven":
			var motion := facing_direction() * 6.0
			move_and_collide(motion)
			stamina = GameState.max_stamina()
			GameState.notify("Passo de Horizonte!")
			Audio.play("swing", -2.0, 1.4)
			ability_cooldowns[id] = 20.0
	GameState.stats_changed.emit()

func facing_direction() -> Vector3:
	return Vector3(sin(_facing), 0.0, cos(_facing))

# ------------------------------------------------------------------ visual ---
func _build_visual() -> void:
	var mf := preload("res://src/visuals/model_factory.gd")
	# Kael na referência de personagem (assets/art/kael_reference.jpg):
	# traje monocromático carvão/preto com capa com capuz.
	var result: Dictionary = mf.spawn_character(self, "res://assets/models/characters/Rogue_Hooded.glb", Vector3.ZERO, Color(0.36, 0.35, 0.37), 1.0)
	if result["visual"] != null:
		visual = result["visual"]
		_anim_player = result["anim_player"]
		_facing = 0.0
		return
	_build_procedural_visual()

func _build_procedural_visual() -> void:
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	var skin := _mat(Color(0.85, 0.62, 0.45))
	var cloth := _mat(Color(0.19, 0.19, 0.22))
	var leather := _mat(Color(0.35, 0.24, 0.15))
	var bandage := _mat(Color(0.85, 0.83, 0.74))
	var rope := _mat(Color(0.48, 0.37, 0.22))
	var steel := _mat(Color(0.55, 0.58, 0.65), 0.35, 0.6)
	var hair := _mat(Color(0.12, 0.09, 0.07))

	_box(visual, Vector3(0.62, 0.7, 0.36), Vector3(0, 1.14, 0), cloth)          # tronco
	_box(visual, Vector3(0.66, 0.14, 0.4), Vector3(0, 0.82, 0), leather)        # cinturão
	_box(visual, Vector3(0.4, 0.4, 0.38), Vector3(0, 1.68, 0), skin)            # cabeça
	_box(visual, Vector3(0.44, 0.16, 0.42), Vector3(0, 1.9, 0), hair)           # cabelo
	_box(visual, Vector3(0.46, 0.18, 0.18), Vector3(0, 1.62, 0.17), bandage)    # faixa nos olhos? (proteção)
	_box(visual, Vector3(0.16, 0.52, 0.16), Vector3(-0.42, 1.12, 0), skin)      # braço esq
	_box(visual, Vector3(0.17, 0.4, 0.17), Vector3(-0.42, 1.38, 0), bandage)    # bandagem esq
	_box(visual, Vector3(0.16, 0.52, 0.16), Vector3(0.42, 1.12, 0), skin)       # braço dir
	_box(visual, Vector3(0.17, 0.4, 0.17), Vector3(0.42, 1.38, 0), bandage)     # bandagem dir
	_box(visual, Vector3(0.34, 0.78, 0.3), Vector3(-0.2, 0.38, 0), leather)     # perna esq
	_box(visual, Vector3(0.34, 0.78, 0.3), Vector3(0.2, 0.38, 0), leather)      # perna dir
	_box(visual, Vector3(0.36, 0.18, 0.42), Vector3(-0.2, 0.06, 0.04), cloth)   # bota esq
	_box(visual, Vector3(0.36, 0.18, 0.42), Vector3(0.2, 0.06, 0.04), cloth)    # bota dir
	_box(visual, Vector3(0.42, 0.5, 0.24), Vector3(0, 1.18, -0.34), rope)       # mochila enrolada
	var sword := _box(visual, Vector3(0.1, 1.15, 0.06), Vector3(0.14, 1.32, -0.38), steel)  # espada às costas
	sword.rotation.z = 0.5
	_box(visual, Vector3(0.22, 0.1, 0.1), Vector3(0.42, 0.86, 0.14), steel)     # gancho de escalada

func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	return m

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi

func add_shake(amount: float) -> void:
	_shake = minf(1.6, _shake + amount)

func _hit_stop(duration: float) -> void:
	# Pausa dramática de ~100 ms em todo o mundo (o temporizador ignora a escala de tempo)
	var tree := get_tree()
	Engine.time_scale = 0.2
	tree.create_timer(duration, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

func _update_animation(delta: float, input_dir: Vector3) -> void:
	if _anim_player == null or _dying:
		return
	if _anim_lock > 0.0:
		_anim_lock -= delta
		return
	var speed_len := input_dir.length()
	var target := "Idle"
	if _blocking:
		target = "Blocking"
	elif speed_len > 0.6:
		target = "Running_A" if Input.is_action_pressed("sprint") and stamina > 1.0 else "Walking_A"
	if _anim_player.current_animation != target:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, target, 0.18)

func _play_attack_anim(heavy: bool) -> void:
	if _anim_player == null:
		return
	var mf := preload("res://src/visuals/model_factory.gd")
	var clip: String
	var duration: float
	if heavy:
		clip = "Unarmed_Melee_Attack_Kick"
		duration = 0.5
	else:
		_attack_anim_flip = not _attack_anim_flip
		clip = "Unarmed_Melee_Attack_Punch_A" if _attack_anim_flip else "Unarmed_Melee_Attack_Punch_B"
		duration = 0.34
	mf.play_anim(_anim_player, clip, 0.08, duration)
	_anim_lock = duration

func _build_camera() -> void:
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.current = true
	camera.fov = 62.0
	camera.far = 400.0
	add_child(camera)
	cam_ray = RayCast3D.new()
	cam_ray.name = "CamRay"
	cam_ray.collision_mask = 1  # só o mundo
	add_child(cam_ray)

# ------------------------------------------------------------------ input ---
func _input(event: InputEvent) -> void:
	if Dialogue.active or UI.is_blocking():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * 0.0028
		_pitch = clampf(_pitch + event.relative.y * 0.0022, 0.08, 1.15)

func _unhandled_input(event: InputEvent) -> void:
	if Dialogue.active or UI.is_blocking():
		return
	if event.is_action_pressed("lock_on"):
		_toggle_lock()
	elif event.is_action_pressed("rupture"):
		if GameState.try_activate_rupture():
			Audio.play("rupture")
	elif event.is_action_pressed("potion"):
		_drink_potion()
	elif event.is_action_pressed("ability_1"):
		_use_ability("liora")
	elif event.is_action_pressed("ability_2"):
		_use_ability("bram")
	elif event.is_action_pressed("ability_3"):
		_use_ability("sena")
	elif event.is_action_pressed("ability_4"):
		_use_ability("iven")
	elif event.is_action_pressed("attack_light"):
		_do_attack(false)
	elif event.is_action_pressed("attack_heavy"):
		_do_attack(true)
	elif event.is_action_pressed("interact"):
		_on_interact()
	elif event.is_action_pressed("dodge"):
		_try_dodge()

func _toggle_lock() -> void:
	if locked_enemy != null:
		locked_enemy = null
		Audio.play("click")
		return
	var nearest: Node3D = null
	var nearest_dist := GameState.lock_range()
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	if nearest:
		locked_enemy = nearest
		Audio.play("click", -4.0)
	else:
		GameState.notify("Nenhum inimigo ao alcance.")

func _drink_potion() -> void:
	if hp >= GameState.max_hp():
		GameState.notify("Vida cheia.")
		return
	if GameState.spend_potion():
		hp = minf(GameState.max_hp(), hp + 45.0)
		Audio.play("potion")
		GameState.notify("+45 vida")

func _on_interact() -> void:
	if current_interactable != null and is_instance_valid(current_interactable):
		current_interactable.interact()
	else:
		_try_chain()

func _try_chain() -> void:
	if _chain_cooldown > 0.0:
		GameState.notify("A Corrente ainda está a enrolar-se... (%.1fs)" % _chain_cooldown)
		return
	var nearest: Node3D = null
	var nearest_dist := 13.0
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	if nearest == null:
		GameState.notify("Nenhum alvo para a Corrente de Âncora.")
		return
	_chain_cooldown = GameState.chain_cooldown()
	# Puxar o alvo para perto e interromper o que quer que esteja a fazer
	var pull := (global_position - nearest.global_position)
	pull.y = 0.0
	var dir := pull.normalized()
	if nearest is CharacterBody3D:
		nearest.velocity += dir * 14.0
	if nearest.has_method("interrupt_cast"):
		nearest.interrupt_cast()
	if nearest.has_method("take_damage"):
		nearest.take_damage(10.0 * GameState.damage_mult(), 25.0 * GameState.posture_mult(), self)
	GameState.add_rupture(8.0)
	Audio.play("heavy_hit", -2.0, 1.3)
	GameState.notify("Corrente de Âncora!")

func _try_dodge() -> void:
	if _dodge_cooldown > 0.0:
		return
	if stamina < 18.0:
		GameState.notify("Sem fôlego para esquivar.")
		return
	var input_dir := _input_vector()
	if input_dir.length() < 0.1:
		input_dir = facing_direction()
	_dodge_dir = input_dir.normalized()
	_dodge_timer = 0.34
	_dodge_cooldown = 0.55
	_invuln_timer = 0.36
	stamina -= 18.0
	Audio.play("swing", -4.0, 0.75)
	if _anim_player != null:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, "Dodge_Forward", 0.08, 0.34)
		_anim_lock = 0.34

func _input_vector() -> Vector3:
	var ix := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var iz := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var touch := get_node_or_null("/root/Touch")
	if touch:
		var tv: Vector2 = touch.get("move_vector")
		if tv.length() > 0.12:
			ix += tv.x
			iz += -tv.y
	var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))
	var move := forward * iz + right * ix
	if move.length() > 1.0:
		move = move.normalized()
	return move

func _do_attack(heavy: bool) -> void:
	if heavy and _attack_cooldown_heavy > 0.0:
		return
	if not heavy and _attack_cooldown > 0.0:
		return
	var cost := 18.0 if heavy else 6.0
	if stamina < cost:
		GameState.notify("Sem fôlego.")
		return
	stamina -= cost
	if heavy:
		_attack_cooldown_heavy = 0.95
	else:
		_attack_cooldown = 0.38
	total_swings += 1
	attack_performed.emit()
	var combo_idx := _combo % 3
	var base := [12.0, 14.0, 17.0][combo_idx] if not heavy else 34.0
	var reach := 2.4 if not heavy else 2.8
	var posture_dmg := (12.0 if not heavy else 30.0) * GameState.posture_mult()
	var mult := GameState.damage_mult() * (1.5 if GameState.rupture_time_left > 0.0 else 1.0)
	var forward := facing_direction()
	var hit_any := false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var to_e: Vector3 = enemy.global_position - global_position
		to_e.y = 0.0
		var dist := to_e.length()
		if dist <= reach:
			var dot := to_e.normalized().dot(forward)
			if dot > 0.25 or dist < 1.1:
				if enemy.has_method("take_damage"):
					enemy.take_damage(base * mult, posture_dmg, self)
					hit_any = true
	_play_attack_anim(heavy)
	if hit_any:
		total_hits += 1
		if first_hit_msec < 0:
			first_hit_msec = Time.get_ticks_msec()
		if heavy:
			heavy_hits += 1
		else:
			light_hits += 1
		attack_landed.emit()
		Audio.play("hit" if not heavy else "heavy_hit", 0.0, randf_range(0.9, 1.1))
		GameState.add_rupture(5.0)
		add_shake(0.35 if not heavy else 0.6)
		_hit_stop(0.09 if not heavy else 0.13)
		var mf := preload("res://src/visuals/model_factory.gd")
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(enemy):
				continue
			var to_e: Vector3 = enemy.global_position - global_position
			to_e.y = 0.0
			if to_e.length() <= reach:
				var dot := to_e.normalized().dot(forward)
				if dot > 0.25 or to_e.length() < 1.1:
					mf.spawn_hit_burst(get_tree(), enemy.global_position, Color(1.0, 0.8, 0.4))
					mf.spawn_damage_number(get_tree(), enemy.global_position, int(base * mult))
	else:
		Audio.play("swing", 0.0, randf_range(0.9, 1.15))
	if heavy:
		_combo = 0
	elif hit_any:
		_combo += 1
	_combo_reset = 1.15
	_lunge = forward * (2.0 if heavy else 3.4)

# ------------------------------------------------------------------ física ---
func _physics_process(delta: float) -> void:
	# Recargas de habilidades + cura ao longo do tempo (Sena)
	for id in ability_cooldowns:
		ability_cooldowns[id] = maxf(0.0, float(ability_cooldowns[id]) - delta)
	if _heal_over_time > 0.0:
		var heal := minf(10.0 * delta, _heal_over_time)
		hp = minf(GameState.max_hp(), hp + heal)
		_heal_over_time -= heal
	# Câmara com o stick direito (gamepad); o rato funciona via _input
	var look_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var look_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(look_x) > 0.18:
		_yaw -= look_x * 2.6 * delta
	if absf(look_y) > 0.18:
		_pitch = clampf(_pitch + look_y * 1.7 * delta, 0.08, 1.15)
	var touch := get_node_or_null("/root/Touch")
	if touch:
		var look_touch: Vector2 = touch.consume_look()
		if look_touch.length() > 0.01:
			_yaw -= look_touch.x * 0.0042
			_pitch = clampf(_pitch + look_touch.y * 0.0032, 0.08, 1.15)

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _attack_cooldown_heavy > 0.0:
		_attack_cooldown_heavy -= delta
	if _dodge_cooldown > 0.0:
		_dodge_cooldown -= delta
	if _dodge_timer > 0.0:
		_dodge_timer -= delta
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
	if _chain_cooldown > 0.0:
		_chain_cooldown -= delta
	if _combo_reset > 0.0:
		_combo_reset -= delta
		if _combo_reset <= 0.0:
			_combo = 0
	GameState.tick_rupture(delta)

	var rupture_active: bool = GameState.rupture_time_left > 0.0

	# Gravidade
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.5)

	# Bloqueio (segurar Q)
	_blocking = Input.is_action_pressed("block") and stamina > 0.0
	if Input.is_action_just_pressed("block"):
		_block_press_time = Time.get_ticks_msec() / 1000.0

	var input_dir := _input_vector()
	var sprinting := Input.is_action_pressed("sprint") and input_dir.length() > 0.1 and stamina > 1.0 and not _blocking
	var speed := GameState.move_speed()
	if sprinting:
		speed *= 1.45
		stamina = maxf(0.0, stamina - 12.0 * delta)
	if _blocking:
		speed *= 0.45
	if rupture_active:
		speed *= 1.12

	if _dodge_timer > 0.0:
		velocity.x = _dodge_dir.x * 10.0
		velocity.z = _dodge_dir.z * 10.0
	elif input_dir.length() > 0.05:
		velocity.x = input_dir.x * speed
		velocity.z = input_dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 30.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 30.0 * delta)

	# Lunge + knockback
	if _lunge.length() > 0.01:
		velocity.x += _lunge.x
		velocity.z += _lunge.z
		_lunge = _lunge.lerp(Vector3.ZERO, 0.35)
	if _knockback.length() > 0.01:
		velocity.x += _knockback.x
		velocity.z += _knockback.z
		_knockback = _knockback.lerp(Vector3.ZERO, 0.3)

	# Regeneração de fôlego
	if not sprinting and not _blocking:
		stamina = minf(GameState.max_stamina(), stamina + GameState.stamina_regen() * (2.0 if rupture_active else 1.0) * delta)

	# Orientação
	var target_facing := _facing
	if locked_enemy != null and is_instance_valid(locked_enemy):
		var to_e: Vector3 = locked_enemy.global_position - global_position
		target_facing = atan2(to_e.x, to_e.z)
	elif input_dir.length() > 0.05:
		target_facing = atan2(input_dir.x, input_dir.z)
	if visual:
		visual.rotation.y = lerp_angle(visual.rotation.y, target_facing, 12.0 * delta)
		_breath_t += delta * (2.6 if input_dir.length() > 0.05 else 1.4)
		var breathe := 1.0 + sin(_breath_t) * 0.012
		visual.scale = Vector3(1.0, breathe, 1.0)
	_facing = target_facing

	# Lock-on: limpar alvo morto/distante
	if locked_enemy != null:
		var invalid: bool = not is_instance_valid(locked_enemy)
		if not invalid and locked_enemy.get("hp") != null and locked_enemy.get("hp") <= 0.0:
			invalid = true
		if not invalid and global_position.distance_to(locked_enemy.global_position) > 26.0:
			invalid = true
		if invalid:
			locked_enemy = null

	# Interagíveis
	current_interactable = _find_interactable()

	_update_animation(delta, input_dir)

	move_and_slide()

	# Limites do mundo
	global_position.x = clampf(global_position.x, -62.0, 62.0)
	global_position.z = clampf(global_position.z, -78.0, 56.0)

	_update_camera(delta)

func _update_camera(delta: float) -> void:
	var chest := global_position + Vector3(0.0, CAM_HEIGHT, 0.0)
	var offset := Vector3(sin(_yaw) * cos(_pitch), sin(_pitch), cos(_yaw) * cos(_pitch)) * _cam_dist
	# Evitar que a câmara atravesse paredes
	cam_ray.global_position = chest
	cam_ray.target_position = offset.normalized() * CAM_DISTANCE
	var desired := CAM_DISTANCE
	if cam_ray.is_colliding():
		desired = maxf(1.4, chest.distance_to(cam_ray.get_collision_point()) * 0.85)
	_cam_dist = lerpf(_cam_dist, desired, 10.0 * delta)
	if _shake > 0.01:
		_shake = maxf(0.0, _shake - delta * 2.3)
		var shake_offset := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * (_shake * 0.22)
		camera.global_position = chest + offset.normalized() * _cam_dist + shake_offset
	else:
		camera.global_position = chest + offset.normalized() * _cam_dist
	camera.look_at(chest, Vector3.UP)

func _find_interactable() -> Node3D:
	var best: Node3D = null
	var best_dist := 2.8
	for group_name in ["npc", "pickup", "exit_portal", "rest_point", "scene_portal"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or not (node is Node3D):
				continue
			var to_n := node.global_position - global_position
			to_n.y = 0.0
			var d := to_n.length()
			if d < best_dist:
				best_dist = d
				best = node
	return best

# ----------------------------------------------------------------- dano -----
func take_damage(amount: float, from_node: Node3D = null) -> void:
	if _invuln_timer > 0.0:
		return
	var final := amount * GameState.difficulty_taken_mult()
	var parried := false
	if _blocking:
		var t := Time.get_ticks_msec() / 1000.0 - _block_press_time
		if t <= GameState.parry_window():
			parried = true
		if parried:
			total_parries += 1
			Audio.play("parry")
			GameState.add_rupture(16.0)
			add_shake(0.55)
			var mf := preload("res://src/visuals/model_factory.gd")
			mf.spawn_hit_burst(get_tree(), global_position + Vector3(0.0, 1.3, 0.0), Color(1.0, 0.9, 0.35))
			if from_node != null:
				if from_node.has_method("take_posture"):
					from_node.take_posture(38.0 * GameState.posture_mult())
				if from_node.has_method("stagger_brief"):
					from_node.stagger_brief(1.1)
			GameState.notify("Parry perfeito!")
			return
		final = amount * 0.28
		stamina -= 9.0
		GameState.add_rupture(6.0)
		Audio.play("parry", -14.0, 0.7)
		if stamina <= 0.0:
			stamina = 0.0
			_blocking = false
			GameState.notify("Fôlego esgotado — não consegues bloquear!")
	if GameState.rupture_time_left > 0.0:
		final *= 0.5
	if _attack_cooldown > 0.0 or _attack_cooldown_heavy > 0.0:
		hits_taken_attacking += 1
	hp -= final
	total_damage_taken += final
	if final >= GameState.max_hp() * 0.25:
		GameState.add_injury()
	if _anim_player != null and not _dying:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, "Hit_A", 0.1, 0.3)
		_anim_lock = 0.3
	add_shake(0.45)
	Audio.play("hit", -2.0, 0.9)
	if from_node != null:
		var away := global_position - from_node.global_position
		away.y = 0.0
		if away.length() > 0.05:
			_knockback = away.normalized() * 5.5
	if hp <= 0.0:
		_die()

func _die() -> void:
	Audio.play("death")
	_dying = true
	if _anim_player != null:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, "Death_A", 0.12)
	var loss := int(GameState.marcos * 0.1)
	GameState.add_marcos(-loss)
	GameState.notify("Kael caiu... Acordas na aldeia. (-%d marcos)" % loss)
	hp = GameState.max_hp()
	stamina = GameState.max_stamina()
	GameState.rupture = 0.0
	GameState.rupture_time_left = 0.0
	var scene := get_tree().current_scene
	if scene != null and scene.has_method("respawn_position"):
		global_position = scene.respawn_position()
	elif scene != null and scene.name == "Main":
		if GameState.main_stage == 5:
			global_position = Vector3(10.0, 1.5, -45.0)  # entrada da arena
		else:
			global_position = Vector3(0.0, 1.5, 34.0)     # vila de Noro
	locked_enemy = null
	# Voltar a pôr-se de pé: terminar a animação de morte
	_dying = false
	_anim_lock = 0.0
	if _anim_player != null:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, "Idle", 0.4)
