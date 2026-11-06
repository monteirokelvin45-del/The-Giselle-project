extends Node3D
## Cena principal: constrói o Vale de Noro, instancia o jogador e liga
## missões, emboscadas e o Guardião da Prova.

var _player: Node3D = null
var _music_timer: float = 0.0

func _ready() -> void:
	var world_builder := preload("res://src/world/world_builder.gd")
	world_builder.build(self)
	var player_scene := preload("res://scenes/player.tscn")
	var player = player_scene.instantiate()
	player.position = Vector3(0.0, 1.3, 34.0)
	add_child(player)
	_player = player
	UI.set_in_game(true)
	Audio.play_music("exploration")
	if not Dialogue.dialogue_finished.is_connected(_on_dialogue_action):
		Dialogue.dialogue_finished.connect(_on_dialogue_action)
	# Se o jogador aceitou a prova e ainda não venceu o Guardião, ele espera na arena
	if GameState.main_stage == 5:
		_spawn_guardian()
	if GameState.main_stage >= 5:
		_spawn_academia_portal()

func _process(delta: float) -> void:
	if _player == null:
		return
	_music_timer -= delta
	if _music_timer <= 0.0:
		_music_timer = 2.0
		var threat := false
		for enemy in get_tree().get_nodes_in_group("enemy"):
			if enemy is Node3D and float(enemy.get("hp")) > 0.0:
				if enemy.global_position.distance_to(_player.global_position) < 14.0:
					threat = true
					break
		Audio.play_music("combat" if threat else "exploration")
	var z := _player.global_position.z
	# Emboscada na floresta (uma vez)
	if GameState.main_stage >= 2 and not GameState.ambush_spawned and z < -8.0:
		GameState.ambush_spawned = true
		_spawn_ambush()
	# Floresta atravessada
	if GameState.main_stage == 2 and z < -37.0:
		GameState.advance_stage(3)

func _spawn_ambush() -> void:
	GameState.notify("Emboscada na Estrada Imperial!")
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var defs := [
		{"type": "salteador", "pos": Vector3(3.5, 0.2, -11.0)},
		{"type": "salteador", "pos": Vector3(-3.5, 0.2, -12.5)},
		{"type": "cinza", "pos": Vector3(0.5, 0.2, -17.0)},
	]
	for d in defs:
		var enemy = enemy_scene.instantiate()
		enemy.set("enemy_type", d["type"])
		enemy.position = d["pos"]
		add_child(enemy)

func _spawn_academia_portal() -> void:
	var portal_scene := preload("res://scenes/scene_portal.tscn")
	var portal = portal_scene.instantiate()
	portal.set("target_scene", "res://scenes/academia.tscn")
	portal.set("prompt_text", "E — Entrar na Academia Real de Veyra")
	portal.set("ring_color", Color(0.9, 0.75, 0.3))
	portal.set("glow_color", Color(0.85, 0.68, 0.25))
	portal.position = Vector3(0.0, 1.7, -51.5)
	add_child(portal)

func _spawn_guardian() -> void:
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var guardian = enemy_scene.instantiate()
	guardian.set("enemy_type", "guardiao")
	guardian.position = Vector3(17.0, 0.3, -44.0)
	guardian.died.connect(_on_guardian_died)
	add_child(guardian)

func _on_guardian_died(_enemy: Node3D, enemy_type: String) -> void:
	if enemy_type != "guardiao":
		return
	GameState.artifact_unlocked = true
	GameState.add_reputation("imperial", 10)
	GameState.add_reputation("academia", 10)
	GameState.advance_stage(6)
	GameState.stats_changed.emit()
	Audio.play("levelup")
	GameState.notify("Algo antigo e silencioso acordou dentro de ti…")
	await get_tree().create_timer(1.6).timeout
	GameState.notify("(Esc → Entrar no Sistema — se ousares)")

func _buy(cost: int, what: String) -> bool:
	if GameState.marcos < cost:
		GameState.notify("Sem marcos suficientes (%d)." % cost)
		return false
	GameState.add_marcos(-cost)
	GameState.notify("Compraste %s. (-%d marcos)" % [what, cost])
	return true

func respawn_position() -> Vector3:
	if GameState.main_stage == 5:
		return Vector3(10.0, 1.5, -45.0)   # arena do Guardião
	return Vector3(0.0, 1.3, 34.0)       # vila de Noro

func _on_dialogue_action(action: String) -> void:
	match action:
		"elen_talked":
			GameState.advance_stage(1)
		"herb_accept":
			if GameState.herb_quest_state == "available":
				GameState.herb_quest_state = "active"
				GameState.stats_changed.emit()
				GameState.notify("Missão aceite: Luz para as Lâmpadas (0/5 Fibras)")
		"garr_chain":
			if GameState.main_stage == 1:
				GameState.advance_stage(2)
			GameState.notify("Corrente de Âncora obtida! (E — ou F quando a Ruptura encher)")
		"wolf_accept":
			if GameState.wolf_quest_state == "available":
				GameState.wolf_quest_state = "active"
				GameState.stats_changed.emit()
				GameState.notify("Missão aceite: Lobos da Estrada (0/3)")
		"shop_potion":
			if _buy(30, "Poção"):
				GameState.potions += 1
				GameState.stats_changed.emit()
				Audio.play("potion")
		"shop_prego":
			if _buy(45, "Prego de Ruptura"):
				GameState.add_rupture(25.0)
		"shop_balsamo":
			if _buy(60, "Bálsamo de Salvação"):
				var player := get_tree().get_first_node_in_group("player")
				if player != null:
					player.set("hp", GameState.max_hp())
					player.set("stamina", GameState.max_stamina())
				GameState.injury = 0
				GameState.notify("Lesões tratadas. Vida e fôlego restaurados.")
				GameState.stats_changed.emit()
		"shop_elixir":
			if _buy(120, "Elixir do Sistema"):
				GameState.add_rupture(50.0)
		"craft_potion":
			if GameState.herb_count < 2:
				GameState.notify("Precisas de 2 Fibras de Ruína.")
			elif _buy(10, "Poção forjada"):
				GameState.herb_count -= 2
				GameState.potions += 1
				GameState.stats_changed.emit()
				Audio.play("potion")
		"craft_balsamo":
			if GameState.herb_count < 3:
				GameState.notify("Precisas de 3 Fibras de Ruína.")
			elif _buy(20, "Bálsamo de Salvação forjado"):
				GameState.herb_count -= 3
				var player := get_tree().get_first_node_in_group("player")
				if player != null:
					player.set("hp", GameState.max_hp())
					player.set("stamina", GameState.max_stamina())
				GameState.injury = 0
				GameState.notify("Bálsamo forjado: lesões tratadas, corpo restaurado.")
				GameState.stats_changed.emit()
		"craft_temper":
			if GameState.weapon_tempered:
				GameState.notify("A lâmina já canta.")
			elif _buy(150, "Têmpera da lâmina"):
				GameState.weapon_tempered = true
				GameState.notify("Lâmina temperada: +12% de dano, para sempre.")
				GameState.stats_changed.emit()
		"rest_durr":
			var player := get_tree().get_first_node_in_group("player")
			if player != null:
				player.set("hp", GameState.max_hp())
				player.set("stamina", GameState.max_stamina())
			GameState.rest()
			GameState.notify("Descansaste um dia. O corpo perdoa.")
		"liora_met":
			GameState.advance_stage(4)
		"accept_trial":
			if GameState.main_stage == 4:
				GameState.advance_stage(5)
				_spawn_guardian()
				GameState.notify("A arena aguarda. Que o Guardião te meça.")
