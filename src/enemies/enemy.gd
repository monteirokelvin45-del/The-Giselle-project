extends CharacterBody3D
## Inimigos: Lobo de Cinza, Salteador de Ruína (físico), Mago de Cinza (conjurador)
## e o Guardião da Prova (chefe).

signal died(enemy: Node3D, enemy_type: String)

const Elements := preload("res://src/core/elements.gd")
const GRAVITY := 26.0
const TYPES := {
	"wolf": {
		"name": "Lobo de Cinza", "hp": 35.0, "dmg": 8.0, "speed": 4.3,
		"posture": 30.0, "xp": 25, "marcos": 6, "range": 1.9, "aggro": 13.0,
		"body_r": 0.34, "body_h": 0.85,
	},
	"salteador": {
		"name": "Salteador de Ruína", "hp": 75.0, "dmg": 14.0, "speed": 3.3,
		"posture": 62.0, "xp": 45, "marcos": 12, "range": 2.1, "aggro": 15.0,
		"body_r": 0.45, "body_h": 1.7,
	},
	"cinza": {
		"name": "Mago de Cinza", "hp": 45.0, "dmg": 12.0, "speed": 3.0,
		"posture": 40.0, "xp": 55, "marcos": 14, "range": 16.0, "aggro": 17.0,
		"body_r": 0.4, "body_h": 1.7,
	},
	"guardiao": {
		"name": "Guardião da Prova", "hp": 300.0, "dmg": 22.0, "speed": 3.2,
		"posture": 170.0, "xp": 250, "marcos": 80, "range": 2.7, "aggro": 40.0,
		"body_r": 0.85, "body_h": 2.8,
	},
	"alfa": {
		"name": "Lobo Alfa de Cinza", "hp": 60.0, "dmg": 11.0, "speed": 4.6,
		"posture": 40.0, "xp": 45, "marcos": 10, "range": 1.9, "aggro": 15.0,
		"body_r": 0.42, "body_h": 1.05,
	},
	"umbra": {
		"name": "Salteador da Umbra", "hp": 95.0, "dmg": 16.0, "speed": 3.6,
		"posture": 70.0, "xp": 70, "marcos": 18, "range": 2.1, "aggro": 15.0,
		"body_r": 0.45, "body_h": 1.7,
	},
	"espectro": {
		"name": "Espectro do Véu", "hp": 45.0, "dmg": 13.0, "speed": 4.5,
		"posture": 30.0, "xp": 65, "marcos": 16, "range": 1.8, "aggro": 14.0,
		"body_r": 0.38, "body_h": 1.65,
	},
	"guarda_espinho": {
		"name": "Guarda de Espinho", "hp": 150.0, "dmg": 18.0, "speed": 2.6,
		"posture": 110.0, "xp": 80, "marcos": 22, "range": 2.2, "aggro": 12.0,
		"body_r": 0.5, "body_h": 1.95,
	},
	"brasa": {
		"name": "Brasa de Ruína", "hp": 55.0, "dmg": 13.0, "speed": 3.0,
		"posture": 40.0, "xp": 60, "marcos": 16, "range": 16.0, "aggro": 17.0,
		"body_r": 0.4, "body_h": 1.7,
	},
	"veterano": {
		"name": "Salteador Veterano", "hp": 120.0, "dmg": 17.0, "speed": 3.2,
		"posture": 85.0, "xp": 75, "marcos": 20, "range": 2.2, "aggro": 15.0,
		"body_r": 0.48, "body_h": 1.75,
	},
}

@export var enemy_type: String = "salteador"
## Multiplicador de vida extra — definido pelo nível de ameaça do Sistema.
var power_mult: float = 1.0

var display_name: String = "Inimigo"
var hp: float = 50.0
var max_hp: float = 50.0
var posture: float = 40.0
var max_posture: float = 40.0

var _combat: bool = false
var _stunned: float = 0.0
var _attack_cooldown: float = 0.0
var _windup: float = 0.0
var _cast_timer: float = 1.5
var _slam_cooldown: float = 4.0
var _slam_telegraph: Node3D = null
var _slam_timer: float = 0.0
var _player: Node3D = null
var _anim_t: float = 0.0
var _dead: bool = false
var _statuses: Dictionary = {}    # v1.8 — id do status → segundos restantes
var _stealth_t: float = 0.0       # v1.8 — Eclipse de um Segundo: cego a «lumina_revelado»
var _anim_player: AnimationPlayer = null
var _anim_lock: float = 0.0
var _cast_windup: float = 0.0
var _pounce_cooldown: float = 2.0
var _pounce_windup: float = 0.0
var _pouncing: float = 0.0
var _pounce_hit: bool = false
var _pounce_dir: Vector3 = Vector3.FORWARD
var _enraged: bool = false

var visual: Node3D

func _ready() -> void:
	var stats: Dictionary = TYPES.get(enemy_type, TYPES["salteador"])
	display_name = String(stats["name"])
	max_hp = float(stats["hp"]) * GameState.difficulty_enemy_hp_mult() * power_mult
	hp = max_hp
	max_posture = float(stats["posture"])
	posture = max_posture
	# Colisão ajustada ao tipo
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is CapsuleShape3D:
		col.shape = col.shape.duplicate()
		col.shape.radius = float(stats["body_r"])
		col.shape.height = float(stats["body_h"])
		col.position.y = float(stats["body_h"]) * 0.5
	add_to_group("enemy")
	_build_visual()

const CHARACTER_MODELS := {
	"wolf": {"path": "res://assets/models/creatures/wolf.glb", "tint": Color(1.0, 1.0, 1.0), "scale": 1.0},
	"salteador": {"path": "res://assets/models/characters/Barbarian.glb", "tint": Color(1.0, 0.72, 0.62), "scale": 1.05},
	"cinza": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(0.72, 0.7, 1.0), "scale": 1.0},
	"guardiao": {"path": "res://assets/models/characters/Barbarian.glb", "tint": Color(0.72, 0.66, 0.6), "scale": 2.3},
	"alfa": {"path": "res://assets/models/creatures/wolf.glb", "tint": Color(0.8, 0.82, 0.88), "scale": 1.35},
	"umbra": {"path": "res://assets/models/characters/Barbarian.glb", "tint": Color(0.45, 0.4, 0.58), "scale": 1.0},
	"espectro": {"path": "res://assets/models/characters/Rogue_Hooded.glb", "tint": Color(0.5, 0.52, 0.72), "scale": 0.95},
	"guarda_espinho": {"path": "res://assets/models/characters/Knight.glb", "tint": Color(0.55, 0.62, 0.5), "scale": 1.12},
	"brasa": {"path": "res://assets/models/characters/Mage.glb", "tint": Color(1.0, 0.68, 0.45), "scale": 1.0},
	"veterano": {"path": "res://assets/models/characters/Barbarian.glb", "tint": Color(0.72, 0.48, 0.4), "scale": 1.15},
}

func _build_visual() -> void:
	var mf := preload("res://src/visuals/model_factory.gd")
	var cfg: Dictionary = CHARACTER_MODELS.get(enemy_type, {})
	if not cfg.is_empty():
		var result: Dictionary = mf.spawn_character(self, cfg["path"], Vector3.ZERO, cfg["tint"], cfg["scale"])
		if result["visual"] != null:
			visual = result["visual"]
			_anim_player = result["anim_player"]
			return
	# Fallback procedural (contingência; o lobo também cai aqui se o GLB falhar)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	match enemy_type:
		"wolf": _build_wolf()
		"cinza": _build_cinza()
		"guardiao": _build_guardiao()
		_: _build_salteador()

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

func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: StandardMaterial3D, rot_z: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.rotation.z = rot_z
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi

func _cyl(parent: Node3D, r_top: float, r_bottom: float, height: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_top
	cm.bottom_radius = r_bottom
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, radius: float, pos: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	mi.mesh = sm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _build_wolf() -> void:
	var fur := _mat(Color(0.36, 0.36, 0.40))
	var dark := _mat(Color(0.22, 0.22, 0.26))
	var eye := _mat(Color(0.9, 0.75, 0.2), 0.0, 0.4, Color(0.9, 0.75, 0.2), 2.0)
	_box(visual, Vector3(0.62, 0.42, 1.15), Vector3(0, 0.62, 0), fur)
	_box(visual, Vector3(0.4, 0.34, 0.42), Vector3(0, 0.78, 0.72), fur)
	_box(visual, Vector3(0.2, 0.18, 0.25), Vector3(0, 0.7, 0.98), dark)
	_box(visual, Vector3(0.08, 0.08, 0.04), Vector3(-0.12, 0.82, 0.9), eye)
	_box(visual, Vector3(0.08, 0.08, 0.04), Vector3(0.12, 0.82, 0.9), eye)
	_box(visual, Vector3(0.09, 0.28, 0.09), Vector3(-0.2, 0.84, 0.6), dark, 0.25)
	_box(visual, Vector3(0.09, 0.28, 0.09), Vector3(0.2, 0.84, 0.6), dark, -0.25)
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_box(visual, Vector3(0.14, 0.42, 0.14), Vector3(sx * 0.22, 0.21, sz * 0.36), dark)
	_box(visual, Vector3(0.1, 0.1, 0.5), Vector3(0, 0.66, -0.72), dark, 0.35)

func _build_salteador() -> void:
	var skin := _mat(Color(0.72, 0.52, 0.38))
	var cloth := _mat(Color(0.38, 0.21, 0.14))
	var iron := _mat(Color(0.4, 0.42, 0.48), 0.7, 0.35)
	_box(visual, Vector3(0.85, 0.85, 0.48), Vector3(0, 1.18, 0), cloth)
	_box(visual, Vector3(0.94, 0.16, 0.52), Vector3(0, 0.78, 0), iron)
	_box(visual, Vector3(0.38, 0.38, 0.36), Vector3(0, 1.8, 0), skin)
	_box(visual, Vector3(0.42, 0.14, 0.4), Vector3(0, 2.0, 0), iron)
	for sx in [-1, 1]:
		_box(visual, Vector3(0.2, 0.66, 0.2), Vector3(sx * 0.56, 1.18, 0), skin)
		_box(visual, Vector3(0.22, 0.34, 0.22), Vector3(sx * 0.56, 1.52, 0), iron)
	_box(visual, Vector3(0.3, 0.75, 0.28), Vector3(-0.24, 0.4, 0), cloth)
	_box(visual, Vector3(0.3, 0.75, 0.28), Vector3(0.24, 0.4, 0), cloth)
	var mace := _box(visual, Vector3(0.09, 0.95, 0.09), Vector3(0.72, 1.25, 0.1), iron)
	mace.rotation.x = 0.5
	_sphere(visual, 0.17, Vector3(0.72, 1.72, -0.35), iron)

func _build_cinza() -> void:
	var robe := _mat(Color(0.27, 0.24, 0.36))
	var trim := _mat(Color(0.16, 0.14, 0.24))
	var crystal := _mat(Color(0.35, 0.9, 0.85), 0.1, 0.3, Color(0.3, 0.95, 0.9), 2.4)
	var dark := _mat(Color(0.05, 0.05, 0.08))
	_cyl(visual, 0.26, 0.56, 1.5, Vector3(0, 0.75, 0), robe)
	_cyl(visual, 0.3, 0.3, 0.12, Vector3(0, 1.52, 0), trim)
	_sphere(visual, 0.21, Vector3(0, 1.68, 0), robe)
	_box(visual, Vector3(0.2, 0.12, 0.1), Vector3(0, 1.66, 0.16), dark)  # rosto na sombra
	var staff := _cyl(visual, 0.05, 0.05, 1.7, Vector3(0.42, 1.0, 0.15), trim)
	staff.rotation.z = 0.12
	_sphere(visual, 0.13, Vector3(0.53, 1.9, 0.15), crystal)

func _build_guardiao() -> void:
	var stone := _mat(Color(0.45, 0.45, 0.52), 0.15, 0.75)
	var stone_dark := _mat(Color(0.3, 0.3, 0.36), 0.1, 0.85)
	var core := _mat(Color(1.0, 0.55, 0.15), 0.0, 0.3, Color(1.0, 0.5, 0.1), 3.0)
	_box(visual, Vector3(1.35, 1.25, 0.85), Vector3(0, 1.72, 0), stone)
	_box(visual, Vector3(1.5, 0.3, 0.95), Vector3(0, 1.12, 0), stone_dark)
	_box(visual, Vector3(0.55, 0.45, 0.5), Vector3(0, 2.6, 0), stone_dark)   # cabeça
	_box(visual, Vector3(0.3, 0.1, 0.12), Vector3(0, 2.55, 0.27), core)      # visor
	for sx in [-1, 1]:
		_box(visual, Vector3(0.38, 1.15, 0.38), Vector3(sx * 0.88, 1.6, 0), stone)
		_box(visual, Vector3(0.42, 0.35, 0.42), Vector3(sx * 0.88, 0.95, 0), stone_dark)
		_box(visual, Vector3(0.5, 1.15, 0.5), Vector3(sx * 0.42, 0.55, 0), stone_dark)
	_sphere(visual, 0.22, Vector3(0, 1.78, 0.36), core)

func _set_surface_emission(mni: MeshInstance3D, surface: int, dup: StandardMaterial3D) -> void:
	mni.set_surface_override_material(surface, dup)

# ------------------------------------------------------------------- IA -----
func _physics_process(delta: float) -> void:
	if _dead:
		return
	_anim_t += delta
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
	if _slam_cooldown > 0.0:
		_slam_cooldown -= delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = maxf(velocity.y, -0.5)

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		move_and_slide()
		return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var stats: Dictionary = TYPES[enemy_type]
	# v1.7: acima de X m do jogador, saltar os caminhos caros (consultas de
	# grupo, skinning/anim). Movimento e cooldowns continuam a 60 Hz.
	var far_mode := dist > float(Balance.combat_cfg()["remote_ai_distance_m"])

	# Atordoado / postura quebrada
	if _stunned > 0.0:
		_stunned -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if visual:
			visual.rotation.x = sin(_anim_t * 10.0) * 0.03
		move_and_slide()
		return

	# Deteção
	if not _combat:
		if dist < float(stats["aggro"]) or hp < max_hp:
			_combat = true
		else:
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
			return

	# Face ao jogador
	if dist > 0.2:
		var target_yaw := atan2(to_player.x, to_player.z)
		if visual:
			visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, 8.0 * delta)

	# Lobo de Cinza: arremesso telegrafado — a sua «habilidade»
	# (abaixa-se 0,4s → lança-se a 9 m/s; anulável por stun, esquivável por timing)
	if enemy_type in ["wolf", "alfa"]:
		if _pounce_cooldown > 0.0:
			_pounce_cooldown -= delta
		if _pouncing > 0.0:
			_pouncing -= delta
			velocity.x = _pounce_dir.x * 9.0
			velocity.z = _pounce_dir.z * 9.0
			if not _pounce_hit and dist < 1.5:
				_pounce_hit = true
				if _player.has_method("take_damage"):
					_player.take_damage(float(stats["dmg"]) + 4.0, self)
				_attack_cooldown = 1.2
			_update_enemy_anim(delta)
			move_and_slide()
			return
		if _pounce_windup > 0.0:
			_pounce_windup -= delta
			velocity.x = 0.0
			velocity.z = 0.0
			if visual:
				visual.rotation.x = 0.3 * (1.0 - _pounce_windup / 0.38)
			move_and_slide()
			if _pounce_windup <= 0.0:
				if visual:
					visual.rotation.x = 0.0
				_pounce_dir = to_player.normalized()
				_pouncing = 0.42
				_pounce_hit = false
				_anim_lock = 0.42
				if _anim_player != null:
					var mfw := preload("res://src/visuals/model_factory.gd")
					mfw.play_anim(_anim_player, "Gallop", 0.08, 0.42)
				Audio.play("swing", -6.0, 0.6)
			return
		if _attack_cooldown <= 0.0 and _pounce_cooldown <= 0.0 and dist >= 3.0 and dist <= 8.0:
			_pounce_windup = 0.38
			_pounce_cooldown = 4.5
			Audio.play("swing", -14.0, 0.45)
			return

	# Chefe: golpe de área telegrafado
	if enemy_type == "guardiao" and _slam_telegraph != null:
		_slam_timer -= delta
		var t := clampf(1.0 - _slam_timer / 1.05, 0.0, 1.0)
		_slam_telegraph.scale = Vector3.ONE * (0.4 + t * 2.6)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		if _slam_timer <= 0.0:
			_resolve_slam()
		return

	if enemy_type == "guardiao" and _slam_cooldown <= 0.0 and dist < 7.5:
		_start_slam()

	# Conjurador: manter distância e disparar com canal visível
	if enemy_type in ["cinza", "brasa"]:
		_cast_timer -= delta
		if _cast_windup > 0.0:
			# A canalizar — está vulnerável à interrupção
			_cast_windup -= delta
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
			if _cast_windup <= 0.0:
				_fire_projectile(to_player.normalized())
				_cast_timer = 2.4
			return
		var has_guard := _nearest_ally_of_type("salteador", 15.0) != null
		var stand_far := 13.0 if has_guard else 11.5
		var stand_near := 8.0 if has_guard else 6.0
		var move := Vector3.ZERO
		if dist > stand_far:
			move = to_player.normalized()
		elif dist < stand_near:
			move = -to_player.normalized()
		else:
			var perp := Vector3(-to_player.z, 0.0, to_player.x).normalized()
			move = perp * (0.6 if sin(_anim_t * 0.7) > 0.0 else -0.6)
		velocity.x = move.x * float(stats["speed"])
		velocity.z = move.z * float(stats["speed"])
		if _cast_timer <= 0.0 and dist < 19.0:
			_cast_windup = 0.75
			var mf_cast := preload("res://src/visuals/model_factory.gd")
			mf_cast.spawn_hit_burst(get_tree(), global_position + Vector3(0.0, 1.6, 0.0), (Color(0.95, 0.55, 0.25) if enemy_type == "brasa" else Color(0.35, 0.95, 0.88)), 0.6)
			if _anim_player != null:
				var mf := preload("res://src/visuals/model_factory.gd")
				mf.play_anim(_anim_player, "Spellcast_Raise", 0.1, 0.75)
				_anim_lock = 0.75
		move_and_slide()
		return

	# Ataque corpo a corpo (com windup legível)
	if _windup > 0.0:
		_windup -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		if visual:
			visual.rotation.x = -0.18 * (1.0 - _windup / 0.45)
		move_and_slide()
		if _windup <= 0.0:
			if visual:
				visual.rotation.x = 0.0
			if dist < float(stats["range"]) + 0.7:
				if _player.has_method("take_damage"):
					var enrage_mult := 1.15 if _enraged else 1.0
					_player.take_damage(float(stats["dmg"]) * enrage_mult, self)
			Audio.play("swing", -6.0, 0.8)
			_attack_cooldown = 1.6
		return

	var speed_now := float(stats["speed"]) * (1.18 if _enraged else 1.0)
	if dist > float(stats["range"]) * 0.85:
		var dir: Vector3 = to_player.normalized() if far_mode else _coordinated_direction(to_player)
		velocity.x = dir.x * speed_now
		velocity.z = dir.z * speed_now
	else:
		velocity.x = move_toward(velocity.x, 0.0, 20.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 20.0 * delta)
		if _attack_cooldown <= 0.0:
			_windup = 0.45
			if _anim_player != null:
				var mf := preload("res://src/visuals/model_factory.gd")
				var attack_clip := "Attack" if enemy_type in ["wolf", "alfa"] else "Unarmed_Melee_Attack_Punch_A"
				mf.play_anim(_anim_player, attack_clip, 0.08, 0.45)
				_anim_lock = 0.45
			Audio.play("swing", -10.0, 0.6)

	# Separação suave entre inimigos (só quando perto — longe custa O(n²) à toa)
	if not far_mode:
		for other in get_tree().get_nodes_in_group("enemy"):
			if other == self or not is_instance_valid(other):
				continue
			var push: Vector3 = global_position - other.global_position
			push.y = 0.0
			if push.length() < 1.3 and push.length() > 0.01:
				velocity += push.normalized() * 3.0

	if not far_mode:
		_update_enemy_anim(delta)
	move_and_slide()
	_tick_statuses(delta)

## ---------------- v1.8 «As Seis Disciplinas» — statuses e reações ----------------
## Statuses vivem no inimigo como a postura; qualquer fonte aplica via
## element_apply_status (o jogador nunca lança disciplinas — é um Vazio).
func element_apply_status(id: String) -> bool:
	var def := Elements.status_def(id)
	if def.is_empty():
		return false
	if id == "lumina_revelado" and _stealth_t > 0.0:
		return false    # Eclipse de um Segundo: cloakado contra o Revelado
	var disc := String(def.get("discipline", ""))
	var reaction: Dictionary = {}
	for active_id in _statuses.keys():
		var r := Elements.reaction(disc, String(active_id))
		if not r.is_empty():
			reaction = r
			break
	if not reaction.is_empty():
		_resolve_reaction(reaction)
		for consume_id in reaction.get("consumes", []):
			_statuses.erase(String(consume_id))
		if bool(reaction.get("applies_incoming", false)):
			_statuses[id] = maxf(float(_statuses.get(id, 0.0)), float(def.get("duration", 5.0)))
		return true
	_statuses[id] = maxf(float(_statuses.get(id, 0.0)), float(def.get("duration", 5.0)))
	for clear_id in def.get("clears", []):
		_statuses.erase(String(clear_id))
	var mf := preload("res://src/visuals/model_factory.gd")
	mf.spawn_hit_burst(get_tree(), global_position + Vector3(0.0, 1.7, 0.0), Elements.discipline_color(disc), 0.7)
	return true

func element_has_status(id: String) -> bool:
	return float(_statuses.get(id, 0.0)) > 0.0

func element_status_time(id: String) -> float:
	return float(_statuses.get(id, 0.0))

## Uma linha para o HUD: "Cinética 4s · Ígnea 6s" (nomes trilingues via CSV).
func element_status_list_flat() -> String:
	if _statuses.is_empty():
		return ""
	var parts := PackedStringArray()
	for id in _statuses.keys():
		var def := Elements.status_def(id)
		var disc := String(def.get("discipline", "cinetica"))
		parts.append(tr(Elements.discipline_key(disc)) + " " + str(int(float(_statuses[id]))) + "s")
	parts.sort()
	return " · ".join(parts)

func _tick_statuses(delta: float) -> void:
	if _stealth_t > 0.0:
		_stealth_t = maxf(0.0, _stealth_t - delta)
	if _statuses.is_empty():
		return
	var expired: Array[String] = []
	for id in _statuses.keys():
		_statuses[id] = float(_statuses[id]) - delta
		var def := Elements.status_def(id)
		var dot := float(def.get("dot", 0.0))
		if dot > 0.0:
			hp = maxf(hp - dot * delta, 0.0)
			if hp <= 0.0 and not _dead:
				_die()
		if float(_statuses[id]) <= 0.0:
			expired.append(String(id))
	for e in expired:
		_statuses.erase(e)

func _resolve_reaction(reaction: Dictionary) -> void:
	var mf := preload("res://src/visuals/model_factory.gd")
	var rcolor := Elements.discipline_color(String(reaction.get("incoming", "cinetica")))
	mf.spawn_hit_burst(get_tree(), global_position + Vector3(0.0, 1.6, 0.0), rcolor, 1.3)
	var center := global_position + Vector3(0.0, 1.5, 0.0)
	var radius := float(reaction.get("radius", 0.0))
	var aoe := float(reaction.get("aoe_damage", 0.0))
	if aoe > 0.0 and radius > 0.0:
		for other in get_tree().get_nodes_in_group("enemy"):
			if not is_instance_valid(other) or not other.has_method("take_damage"):
				continue
			var to_t: Vector3 = other.global_position - global_position
			to_t.y = 0.0
			if to_t.length() <= radius:
				other.take_damage(aoe, 0.0, self)
		if bool(reaction.get("hits_player", false)):
			var pl := get_tree().get_first_node_in_group("player")
			if pl != null and pl.has_method("take_damage"):
				var to_p: Vector3 = pl.global_position - global_position
				to_p.y = 0.0
				if to_p.length() <= radius:
					pl.take_damage(aoe, self)
	var pd := float(reaction.get("posture_damage", 0.0))
	if pd > 0.0:
		posture -= pd
	var fr := float(reaction.get("freeze", 0.0))
	if fr > 0.0:
		_stunned = maxf(_stunned, fr)
	var st := float(reaction.get("stealth", 0.0))
	if st > 0.0:
		_stealth_t = maxf(_stealth_t, st)
	var pushf := float(reaction.get("push", 0.0))
	if pushf > 0.0 and _player != null and is_instance_valid(_player):
		var away: Vector3 = global_position - _player.global_position
		away.y = 0.0
		if away.length() > 0.01:
			velocity += away.normalized() * pushf
	GameState.notify(tr("Reação: %s") % tr(Elements.reaction_key(String(reaction.get("id", "vapor_veyra")))))

func _nearest_ally_of_type(type: String, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_d := max_dist
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self or not is_instance_valid(other):
			continue
		if other.get("enemy_type") != type:
			continue
		var d: float = (other.global_position - global_position).length()
		if d < best_d:
			best_d = d
			best = other
	return best

## Coordenenação leve: salteador protege o Mago de Cinza mais próximo
## (coloca-se entre ele e o jogador); sem Mago por perto, dois salteadores
## escolhem lados opostos de flanqueamento.
func _coordinated_direction(to_player: Vector3) -> Vector3:
	if enemy_type != "salteador":
		return to_player.normalized()
	var cinza := _nearest_ally_of_type("cinza", 32.0)
	if cinza != null:
		var dir_to_player := to_player.normalized()
		var cover := cinza.global_position + dir_to_player * 3.4
		var to_cover := cover - global_position
		to_cover.y = 0.0
		if to_cover.length() > 1.3:
			return to_cover.normalized()
		return dir_to_player
	var ally := _nearest_ally_of_type("salteador", 48.0)
	if ally != null:
		var side := 1.0 if get_instance_id() > ally.get_instance_id() else -1.0
		var perp := Vector3(-to_player.z, 0.0, to_player.x).normalized() * side
		var flank := _player.global_position + perp * 2.8
		var to_flank := flank - global_position
		to_flank.y = 0.0
		if to_flank.length() > 1.6:
			return to_flank.normalized()
	return to_player.normalized()

func _update_enemy_anim(delta: float) -> void:
	if _anim_player == null or _dead:
		return
	if _anim_lock > 0.0:
		_anim_lock -= delta
		return
	var speed_len := Vector2(velocity.x, velocity.z).length()
	var walk_clip := "Walk" if enemy_type in ["wolf", "alfa"] else "Walking_A"
	var target := walk_clip if speed_len > 0.6 else "Idle"
	if _anim_player.current_animation != target:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, target, 0.2)

const ProjectilePool := preload("res://src/enemies/projectile_pool.gd")

func _fire_projectile(dir: Vector3) -> void:
	var mf_fire := preload("res://src/visuals/model_factory.gd")
	mf_fire.spawn_hit_burst(get_tree(), global_position + Vector3(0.0, 1.6, 0.0), (Color(1.0, 0.62, 0.3) if enemy_type == "brasa" else Color(0.4, 0.8, 0.95)), 0.9)
	if _anim_player != null:
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.play_anim(_anim_player, "Spellcast_Shoot", 0.08, 0.4)
	var p := ProjectilePool.acquire(get_tree(), enemy_type == "brasa")
	p.global_position = global_position + Vector3(0.0, 1.6, 0.0) + dir * 0.6
	if p.has_method("setup"):
		p.setup(dir)
	Audio.play("swing", -4.0, 1.5)

func _start_slam() -> void:
	_slam_cooldown = 6.5
	_slam_timer = 1.05
	_slam_telegraph = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0
	cyl.bottom_radius = 1.0
	cyl.height = 0.06
	_slam_telegraph.mesh = cyl
	var m := _mat(Color(0.9, 0.25, 0.12), 0.0, 0.6, Color(0.9, 0.2, 0.08), 1.6)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.9, 0.25, 0.12, 0.55)
	_slam_telegraph.material_override = m
	get_tree().current_scene.add_child(_slam_telegraph)
	_slam_telegraph.global_position = global_position + Vector3(0.0, 0.35, 0.0)
	_slam_telegraph.scale = Vector3.ONE * 0.4
	Audio.play("rupture", -8.0, 0.75)

func _resolve_slam() -> void:
	var center := _slam_telegraph.global_position
	_slam_telegraph.queue_free()
	_slam_telegraph = null
	Audio.play("heavy_hit", 0.0, 0.6)
	if _player != null and is_instance_valid(_player):
		if _player.global_position.distance_to(center) <= 3.4:
			if _player.has_method("take_damage"):
				_player.take_damage(30.0 * (1.15 if _enraged else 1.0), self)

# ------------------------------------------------------------------ dano ----
func take_damage(amount: float, posture_dmg: float, _from: Node3D = null) -> void:
	if _dead:
		return
	hp -= amount
	posture -= posture_dmg
	_combat = true
	# Flinch em golpes pesados (posture >= 25, i.e. pesado/slam) — não no Guardião
	if posture_dmg >= 25.0 and enemy_type != "guardiao":
		_stunned = maxf(_stunned, 0.35)
	if enemy_type == "guardiao" and not _enraged and hp <= max_hp * 0.5 and hp > 0.0:
		_enraged = true
		GameState.notify("O Guardião RUGE — a Prova enfurece!")
		Audio.play("rupture", -2.0, 0.7)
		if _player != null and is_instance_valid(_player) and _player.has_method("add_shake"):
			_player.add_shake(0.8)
		if visual and is_instance_valid(visual):
			for node in visual.find_children("*", "MeshInstance3D", true, false):
				var mni := node as MeshInstance3D
				if mni == null or mni.mesh == null:
					continue
				for i in range(mni.mesh.get_surface_count()):
					var mat := mni.mesh.surface_get_material(i)
					if mat is StandardMaterial3D:
						var dup := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
						dup.emission_enabled = true
						dup.emission = Color(0.65, 0.12, 0.05)
						dup.emission_energy_multiplier = 0.55
						_set_surface_emission(mni, i, dup)
	if visual and is_instance_valid(visual):
		var mf := preload("res://src/visuals/model_factory.gd")
		mf.flash_model(visual, 0.1)
	if _anim_player != null and not _dead:
		var mf := preload("res://src/visuals/model_factory.gd")
		var hit_clip := "Idle_HitReact1" if enemy_type in ["wolf", "alfa"] else "Hit_A"
		mf.play_anim(_anim_player, hit_clip, 0.08, 0.24)
		_anim_lock = 0.24
	if posture <= 0.0:
		posture = max_posture * 0.65
		_stunned = maxf(_stunned, 2.3)
		if visual:
			visual.rotation.x = 0.12
		GameState.notify("Postura quebrada — agora golpeia!")
		Audio.play("posture_break")
	if hp <= 0.0:
		_die()

func take_posture(amount: float) -> void:
	if _dead:
		return
	posture -= amount
	_combat = true
	if posture <= 0.0:
		posture = max_posture * 0.65
		_stunned = maxf(_stunned, 2.3)
		Audio.play("posture_break")

func stagger_brief(duration: float) -> void:
	_stunned = maxf(_stunned, duration)

func interrupt_cast() -> void:
	_cast_timer = maxf(_cast_timer, 2.0)
	_cast_windup = 0.0
	_anim_lock = 0.0
	_stunned = maxf(_stunned, 1.1)
	GameState.notify("Conjuração interrompida!")

func _die() -> void:
	_dead = true
	if _anim_player != null:
		var mf := preload("res://src/visuals/model_factory.gd")
		var death_clip := "Death" if enemy_type in ["wolf", "alfa"] else "Death_A"
		mf.play_anim(_anim_player, death_clip, 0.12)
	if _slam_telegraph != null:
		_slam_telegraph.queue_free()
		_slam_telegraph = null
	remove_from_group("enemy")
	collision_layer = 0
	collision_mask = 0
	var stats: Dictionary = TYPES[enemy_type]
	GameState.add_marcos(int(stats["marcos"]))
	GameState.add_xp(int(stats["xp"]))
	if enemy_type == "wolf":
		GameState.on_wolf_killed()
	if enemy_type == "guardiao":
		GameState.notify("O Guardião da Prova despedaça-se... algo dentro de ti acorda.")
	died.emit(self, enemy_type)
	# Cair e desaparecer
	var tween := create_tween()
	tween.tween_property(visual, "rotation:x", -1.35, 0.7)
	tween.parallel().tween_property(self, "position:y", position.y - 0.15, 0.7)
	tween.tween_interval(1.1)
	tween.tween_callback(queue_free)
