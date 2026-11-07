## Runner do smoke test de jogabilidade (corre dentro do engine, contexto de cena).
## Uso: godot --headless --path . res://tools/smoke_test.tscn
extends Node3D

var _frame: int = 0
var _failures: int = 0
var _air_hp_before: float = -1.0
var _air_done: bool = false
var _air_phase: int = 0

func _ready() -> void:
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		print("SMOKE|FAIL main.tscn carregou")
		get_tree().quit(1)
		return
	add_child(scene.instantiate())

func _check(cond: bool, label: String) -> void:
	if cond:
		print("SMOKE|PASS ", label)
	else:
		_failures += 1
		print("SMOKE|FAIL ", label)

func _finish_air() -> void:
	Input.action_release("jump")
	print("SMOKE|DONE falhas=", _failures)
	get_tree().quit(0 if _failures == 0 else 1)

func _process(_delta: float) -> void:
	_frame += 1
	if _frame < 30:
		return
	if _frame == 30:
		var player: Node3D = get_tree().get_first_node_in_group("player")
		_check(player != null, "jogador existe no mundo")
		GameState.add_xp(1000)
		_check(GameState.level > 1, "ganho de XP sobe de nível")
		GameState.rupture_activations = 1
		_check(GameState.technique_unlocked("passo_vazio"), "Passo Vazio desbloqueia com 1 Ruptura")
		_check(not GameState.technique_unlocked("queda_colosso"), "Queda do Colosso trancada com 1 ativação")
		GameState.rupture_activations = 3
		_check(GameState.technique_unlocked("queda_colosso"), "Queda do Colosso com 3 ativações")
		_check(int(Balance.xp_needed(5)) > int(Balance.xp_needed(1)), "curva de XP crescente (balance.json)")
		_check(is_equal_approx(Balance.potion_heal(), 45.0), "cura da poção do balance.json")
		GameState.marcos = 1234
		GameState.attributes["for"] = 4
		GameState.save_game(Vector3(0.0, 1.3, 34.0), 100.0, 100.0)
		GameState.marcos = 0
		GameState.attributes["for"] = 1
		GameState.load_game()
		_check(GameState.marcos == 1234, "save/load devolve marcos")
		GameState.tts_voice = "voz-teste-123"
		GameState.save_game(Vector3(0.0, 1.3, 34.0), 100.0, 100.0)
		GameState.tts_voice = ""
		GameState.load_game()
		_check(GameState.tts_voice == "voz-teste-123", "save/load devolve a voz de narração")
		GameState.tts_voice = ""
		GameState.cycle_tts_voice()
		_check(GameState.tts_voice == "", "ciclo de voz sem vozes mantém automática")
		GameState.save_game(Vector3(0.0, 1.3, 34.0), 100.0, 100.0)
		_check(int(GameState.attributes["for"]) == 4, "save/load devolve atributos")
		# v0.6 — lesões graduadas e treino com mestres
		var attr_v06: int = GameState.attribute_points
		GameState.injury = 2
		var dmg_grave: float = GameState.damage_mult()
		GameState.injury = 1
		var dmg_mag: float = GameState.damage_mult()
		GameState.injury = 0
		var dmg_ok: float = GameState.damage_mult()
		_check(dmg_grave < dmg_mag and dmg_mag < dmg_ok, "lesões escalonadas reduzem o dano (0/1/2)")
		GameState.add_injury()
		GameState.add_injury()
		_check(GameState.injury == 2, "dois golpes graves levam a lesão ao nível 2")
		GameState.rest()
		_check(GameState.injury == 1, "repouso alivia 1 nível de lesão")
		GameState.injury = 2
		GameState.fatigue = 3
		GameState.marcos = 500
		var ok_blocked: bool = GameState.try_train_attribute()
		_check(not ok_blocked and GameState.attribute_points == attr_v06, "fadiga máxima bloqueia o treino com mestres")
		GameState.save_game(Vector3(0.0, 1.3, 34.0), 100.0, 100.0)
		GameState.injury = 0
		GameState.fatigue = 0
		GameState.load_game()
		_check(GameState.injury == 2 and GameState.fatigue == 3, "save/load devolve lesão e fadiga")
		GameState.marcos = 10
		var pobre: bool = GameState.try_spend_marcos(45)
		_check(not pobre and GameState.marcos == 10, "guarda de marcos recusa compra sem fundos")
		GameState.injury = 2
		var curados: int = GameState.heal_injury(1)
		_check(curados == 1 and GameState.injury == 1, "remendo do curandeiro cura 1 nível de lesão")
		GameState.marcos = 100
		_check(GameState.try_spend_marcos(45), "guarda de marcos aceita compra com fundos")
		GameState.marcos = 500
		GameState.rest()
		var trained: bool = GameState.try_train_attribute()
		_check(trained and GameState.fatigue == 1 and GameState.attribute_points == attr_v06 + 1, "treino com mestre gasta marcos e soma fadiga")
		# repõe o estado canónico usado pelos testes seguintes
		GameState.marcos = 1234
		GameState.injury = 0
		GameState.fatigue = 0
		GameState.attribute_points = attr_v06
		GameState.save_game(Vector3(0.0, 1.3, 34.0), 100.0, 100.0)
		var enemy_scene := load("res://scenes/enemy.tscn")
		if enemy_scene != null:
			var enemy: Node3D = enemy_scene.instantiate()
			get_tree().get_root().add_child(enemy)
			enemy.global_position = player.global_position + Vector3(1.0, 0.0, 1.0)
			var hp_before: float = float(enemy.get("hp"))
			player.call("_do_attack", false)
			var hp_after: float = float(enemy.get("hp"))
			_check(hp_after < hp_before, "ataque corpo a corpo tira vida ao inimigo")
			_air_hp_before = float(enemy.get("hp"))
			# ---- v1.5 «Qualidade de tudo» — asserções de regressão ----
			# Esquiva perfeita: arranque da esquiva no instante do impacto
			GameState.rupture = 0.0
			player.set("_invuln_timer", 0.5)
			player.set("_dodge_timer", 0.3)
			var hp_ghost := float(player.get("hp"))
			player.call("take_damage", 5.0, null)
			_check(float(player.get("hp")) == hp_ghost, "esquiva perfeita não tira vida")
			var rupture_esperado: float = 15.0 * GameState.rupture_gain_mult()
			_check(is_equal_approx(GameState.rupture, rupture_esperado), "esquiva perfeita dá +15 Ruptura (× mult)")
			player.set("_invuln_timer", 0.0)
			player.set("_dodge_timer", 0.0)

			# Sinal damaged emite ao sofrer dano (o HUD depende dele)
			var damaged_seen := [false]
			var pobj: Object = player
			if pobj.has_signal("damaged"):
				var sig: Signal = pobj.get("damaged")
				sig.connect(func(): damaged_seen[0] = true)
			player.call("take_damage", 5.0, null)
			_check(damaged_seen[0], "sinal damaged emite ao sofrer dano")

			# Sprint attack fere mais que o golpe normal (mesmo alvo)
			player.set("_attack_cooldown", 0.0)
			var e2: Node3D = enemy_scene.instantiate()
			get_tree().get_root().add_child(e2)
			e2.global_position = player.global_position + Vector3(0.0, 0.0, 1.5)
			var antes2 := float(e2.get("hp"))
			player.call("_do_attack", false)
			var dano_normal := antes2 - float(e2.get("hp"))
			player.set("_attack_cooldown", 0.0)
			player.set("_sprinting", true)
			var antes3 := float(e2.get("hp"))
			player.call("_do_attack", false)
			var dano_sprint := antes3 - float(e2.get("hp"))
			player.set("_sprinting", false)
			_check(dano_sprint > dano_normal, "sprint attack fere mais que o golpe normal")
			e2.queue_free()

			# Flinch em golpe pesado (≥25 postura) — Salteador vergou
			var e3: Node3D = enemy_scene.instantiate()
			get_tree().get_root().add_child(e3)
			e3.global_position = player.global_position + Vector3(0.0, 0.0, 1.5)
			e3.call("take_damage", 1.0, 30.0, player)
			_check(float(e3.get("_stunned")) > 0.3, "pós-25 postura aplica flinch no Salteador")
			e3.queue_free()

			# Lobo entra no arremesso telegrafado com o jogador a 5 m
			var wolf: Node3D = enemy_scene.instantiate()
			wolf.set("enemy_type", "wolf")
			get_tree().get_root().add_child(wolf)
			wolf.global_position = player.global_position + Vector3(0.0, 0.0, 5.0)
			wolf.set("_attack_cooldown", 0.0)
			wolf.set("_pounce_cooldown", 0.0)
			wolf.call("_physics_process", 0.016)
			_check(float(wolf.get("_pounce_windup")) > 0.3 or float(wolf.get("_pouncing")) > 0.0, "lobo entra no arremesso telegrafado")
			wolf.queue_free()

			# Guardião enfurece aos 50% de vida
			var guardian: Node3D = enemy_scene.instantiate()
			guardian.set("enemy_type", "guardiao")
			get_tree().get_root().add_child(guardian)
			guardian.global_position = player.global_position + Vector3(0.0, 0.0, 3.0)
			guardian.call("take_damage", 160.0, 0.0, player)
			_check(bool(guardian.get("_enraged")), "Guardião enfurece aos 50% de vida")
			guardian.queue_free()

			# Salto data-driven
			var jump_cfg: Dictionary = Balance.jump_cfg()
			_check(is_equal_approx(float(jump_cfg.get("coyote", 0.0)), 0.12) and is_equal_approx(float(jump_cfg.get("jump_buffer", 0.0)), 0.12), "coyote/jump buffer 0,12s no balance.json")
		else:
			_check(false, "enemy.tscn instancia")
		print("SMOKE|INFO reputação imperial inicial = ", int(GameState.reputation.get("imperial", 0)))
		Input.action_press("jump")
		_air_phase = 1
	elif _air_phase == 1:
		# esperar a descolagem (independente de FPS) → pesado no ar
		var player: Node3D = get_tree().get_first_node_in_group("player")
		if not player.is_on_floor():
			player.set("stamina", 100.0)
			player.call("_do_attack", true)
			_check(bool(player.get("_air_slam_pending")), "ataque pesado no ar prepara slam de queda")
			_air_phase = 2
		elif _frame >= 120:
			_check(false, "salto tira o jogador do chão")
			_air_phase = 3
			_finish_air()
	elif _air_phase == 2:
		# esperar a aterragem → slam consome-se e fere a área
		var player: Node3D = get_tree().get_first_node_in_group("player")
		if player.is_on_floor():
			_air_done = true
			Input.action_release("jump")
			_check(not bool(player.get("_air_slam_pending")), "slam de queda consome-se ao aterrar")
			var enemies := get_tree().get_nodes_in_group("enemy")
			if enemies.is_empty():
				_check(true, "slam de queda concluiu (inimigo já derrotado)")
			else:
				_check(float(enemies[0].get("hp")) < _air_hp_before, "slam de queda fere inimigos na área")
			_air_phase = 3
			_finish_air()
		elif _frame >= 140:
			_check(false, "jogador aterrou a tempo")
			_air_phase = 3
			_finish_air()
