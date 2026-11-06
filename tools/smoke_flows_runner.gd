## Smoke test de fluxos de jogo (Sala Branca + provas da Academia).
## Corre dentro do engine: godot --headless --path . res://tools/smoke_flows.tscn
extends Node3D

var _phase: int = 0
var _current: Node = null
var _phase_start_ms: int = 0
var _failures: int = 0
var _evaluated: bool = false

func _ready() -> void:
	# O jogo pausa a árvore quando mostra a avaliação — o runner tem de
	# continuar a processar (PROCESS_MODE_ALWAYS) para poder avançar fases.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_sala()

func _load_sala() -> void:
	_current = load("res://scenes/sala_branca.tscn").instantiate()
	add_child(_current)
	_enter_phase(0)

func _enter_phase(p: int) -> void:
	_phase = p
	_phase_start_ms = Time.get_ticks_msec()

func _check(cond: bool, label: String) -> void:
	if cond:
		print("SMOKE|PASS ", label)
	else:
		_failures += 1
		print("SMOKE|FAIL ", label)

func _process(_delta: float) -> void:
	match _phase:
		0:  # esperar o mundo construir-se
			if Time.get_ticks_msec() - _phase_start_ms > 1200:
				_current.call("_start_simulation")
				_enter_phase(1)
		1:  # confirmar spawn e exterminar
			if Time.get_ticks_msec() - _phase_start_ms > 2500:
				var enemies := get_tree().get_nodes_in_group("enemy")
				_check(enemies.size() > 0, "Sala Branca spawna inimigos (%d)" % enemies.size())
				var player := get_tree().get_first_node_in_group("player")
				for e in enemies:
					e.call("take_damage", 99999.0, 99999.0, player)
				_enter_phase(2)
		2:  # aguardar a painel de avaliação (timer real ~2.4 s)
			var panel = _current.get("_eval_panel")
			if panel != null and (panel as Control).visible:
				if not _evaluated:
					_evaluated = true
					_check(true, "avaliação da Sala Branca concluída (painel visível)")
				_enter_phase(3)
			elif Time.get_ticks_msec() - _phase_start_ms > 9000:
				_check(false, "avaliação da Sala Branca concluiu a tempo")
				_enter_phase(3)
		3:  # trocar para a Academia (fechar a avaliação = árvore despausada)
			get_tree().paused = false
			var ui := get_node_or_null("/root/UI")
			if ui != null:
				ui.set("external_block", false)
			_current.queue_free()
			_current = load("res://scenes/academia.tscn").instantiate()
			add_child(_current)
			_enter_phase(4)
		4:
			if Time.get_ticks_msec() - _phase_start_ms > 1500:
				_current.call("_start_exam", "duelo")
				_enter_phase(5)
		5:
			if Time.get_ticks_msec() - _phase_start_ms > 2500:
				var enemies := get_tree().get_nodes_in_group("enemy")
				_check(enemies.size() > 0, "Prova de Duelo spawna inimigos (%d)" % enemies.size())
				var player := get_tree().get_first_node_in_group("player")
				for e in enemies:
					e.call("take_damage", 99999.0, 99999.0, player)
				_enter_phase(6)
		6:
			if Time.get_ticks_msec() - _phase_start_ms > 1500:
				_check(bool(GameState.exams_done.get("duelo", false)), "Prova de Duelo concluída e registada")
				_check(int(GameState.companions.get("bram", 0)) >= 60, "Bram junta-se (lealdade >= 60)")
				print("SMOKE|DONE falhas=", _failures)
				get_tree().quit(0 if _failures == 0 else 1)
