## Runner do smoke test de jogabilidade (corre dentro do engine, contexto de cena).
## Uso: godot --headless --path . res://tools/smoke_test.tscn
extends Node3D

var _frame: int = 0
var _failures: int = 0

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
		_check(int(GameState.attributes["for"]) == 4, "save/load devolve atributos")
		var enemy_scene := load("res://scenes/enemy.tscn")
		if enemy_scene != null:
			var enemy: Node3D = enemy_scene.instantiate()
			get_tree().get_root().add_child(enemy)
			enemy.global_position = player.global_position + Vector3(1.0, 0.0, 1.0)
			var hp_before: float = float(enemy.get("hp"))
			player.call("_do_attack", false)
			var hp_after: float = float(enemy.get("hp"))
			_check(hp_after < hp_before, "ataque corpo a corpo tira vida ao inimigo")
		else:
			_check(false, "enemy.tscn instancia")
		print("SMOKE|INFO reputação imperial inicial = ", int(GameState.reputation.get("imperial", 0)))
		print("SMOKE|DONE falhas=", _failures)
		get_tree().quit(0 if _failures == 0 else 1)
