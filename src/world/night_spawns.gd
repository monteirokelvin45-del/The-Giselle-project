## Ecos da noite: enquanto for NOITE, coisas específicas espreitam na
## floresta do Vale (área delimitada por zona). Nascem em redor do
## jogador (≥ 12 m de distância), são desalojados silenciosamente pela
## aurora — e alguns voltarão na noite seguinte.
extends Node3D

const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const TYPES_NIGHT := ["umbra", "espectro", "alfa", "umbra", "espectro", "alfa", "guarda_espinho", "brasa"]
const PLAYER_MIN_DIST: float = 12.0

var zone_center := Vector3(0.0, 0.0, -17.0)
var zone_radius: float = 21.0
var max_alive: int = 4
var interval: float = 4.5
var _cooldown: float = 2.0
var _was_night: bool = false

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	var t := GameState.world_day_t
	var daylight := clampf(sin(t * PI), 0.0, 1.0)
	var night := daylight < 0.22
	if night != _was_night:
		_was_night = night
		if not night:
			for enemy in get_tree().get_nodes_in_group("night_spawn"):
				if is_instance_valid(enemy):
					enemy.queue_free()
			return
	if not night:
		return
	if _cooldown > 0.0:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var to_zone := Vector2(player.global_position.x - zone_center.x, player.global_position.z - zone_center.z)
	if to_zone.length() > zone_radius + 26.0:
		return   # o jogador está longe da floresta — não repovoar às cegas
	_cooldown = interval
	var alive := 0
	for enemy in get_tree().get_nodes_in_group("night_spawn"):
		if is_instance_valid(enemy):
			alive += 1
	if alive >= max_alive:
		return
	for _attempt in range(8):
		var angle := randf_range(0.0, TAU)
		var radius := randf_range(zone_radius * 0.35, zone_radius)
		var pos := zone_center + Vector3(cos(angle) * radius, 0.2, sin(angle) * radius)
		if pos.distance_to(player.global_position) < PLAYER_MIN_DIST:
			continue
		var e: Node3D = ENEMY_SCENE.instantiate()
		e.set("enemy_type", TYPES_NIGHT[randi_range(0, TYPES_NIGHT.size() - 1)])
		e.set("power_mult", 1.0)
		e.position = pos
		get_tree().current_scene.add_child(e)
		e.add_to_group("night_spawn")
		return
