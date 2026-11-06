extends Node3D
## Cena principal: constrói o Vale de Noro, instancia o jogador e liga
## missões, emboscadas e o Guardião da Prova.

var _player: Node3D = null

func _ready() -> void:
	var world_builder := preload("res://src/world/world_builder.gd")
	world_builder.build(self)
	var player_scene := preload("res://scenes/player.tscn")
	var player := player_scene.instantiate()
	player.position = Vector3(0.0, 1.3, 34.0)
	add_child(player)
	_player = player
	UI.set_in_game(true)
	if not Dialogue.dialogue_finished.is_connected(_on_dialogue_action):
		Dialogue.dialogue_finished.connect(_on_dialogue_action)
	# Se o jogador aceitou a prova e ainda não venceu o Guardião, ele espera na arena
	if GameState.main_stage == 5:
		_spawn_guardian()

func _process(_delta: float) -> void:
	if _player == null:
		return
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
		var enemy := enemy_scene.instantiate()
		enemy.set("enemy_type", d["type"])
		enemy.position = d["pos"]
		add_child(enemy)

func _spawn_guardian() -> void:
	var enemy_scene := preload("res://scenes/enemy.tscn")
	var guardian := enemy_scene.instantiate()
	guardian.set("enemy_type", "guardiao")
	guardian.position = Vector3(17.0, 0.3, -44.0)
	guardian.died.connect(_on_guardian_died)
	add_child(guardian)

func _on_guardian_died(_enemy: Node3D, enemy_type: String) -> void:
	if enemy_type != "guardiao":
		return
	GameState.artifact_unlocked = true
	GameState.advance_stage(6)
	GameState.stats_changed.emit()
	Audio.play("levelup")
	GameState.notify("Algo antigo e silencioso acordou dentro de ti…")
	await get_tree().create_timer(1.6).timeout
	GameState.notify("(Esc → Entrar no Sistema — se ousares)")

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
		"liora_met":
			GameState.advance_stage(4)
		"accept_trial":
			if GameState.main_stage == 4:
				GameState.advance_stage(5)
				_spawn_guardian()
				GameState.notify("A arena aguarda. Que o Guardião te meça.")
