## Stress headless de combate (v1.7): mundo principal + equipa de 10 inimigos
## de todos os tipos à volta do jogador — o pior caso real do combate.
## Verifica que nada rebenta com carga cheia, que o pool de projéteis reutiliza
## nós e regista monitores CPU-side (não substitui F5 no hardware real).
## Uso: godot --headless --path . res://tools/stress_test.tscn
extends Node3D

const ProjectilePool := preload("res://src/enemies/projectile_pool.gd")
const RING_TYPES := ["wolf", "salteador", "cinza", "guardiao", "umbra", "veterano", "espectro", "guarda_espinho", "brasa", "alfa"]
const TEST_SECONDS := 14.0

var _t: float = 0.0
var _frame: int = 0
var _done: bool = false
var _failures: int = 0

func _ready() -> void:
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		print("SMOKE|FAIL main.tscn carregou (stress)")
		get_tree().quit(1)
		return
	add_child(scene.instantiate())

func _check(cond: bool, label: String) -> void:
	if cond:
		print("SMOKE|PASS ", label)
	else:
		_failures += 1
		print("SMOKE|FAIL ", label)

func _spawn_wave() -> void:
	var enemy_scene := load("res://scenes/enemy.tscn")
	var player := get_tree().get_first_node_in_group("player")
	if enemy_scene == null or player == null:
		_check(false, "recursos da equipa de stress carregam")
		return
	for i in RING_TYPES.size():
		var e: Node3D = enemy_scene.instantiate()
		e.set("enemy_type", RING_TYPES[i])  # antes de entrar na árvore: o corpo é construído no _ready
		get_tree().current_scene.add_child(e)
		var angle := TAU * float(i) / float(RING_TYPES.size())
		e.global_position = player.global_position + Vector3(cos(angle) * 5.0, 0.0, sin(angle) * 5.0)
	_check(true, "equipa de 10 inimigos instancia à volta do jogador")

func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_frame += 1
	if _frame == 30:
		_spawn_wave()
	if _t < TEST_SECONDS:
		return
	_done = true
	var enemies := get_tree().get_nodes_in_group("enemy")
	_check(enemies.size() >= 10, "equipa de 10 inimigos continua no mundo (pior caso)")
	var a: Area3D = ProjectilePool.acquire(get_tree(), false)
	ProjectilePool.release(a)
	var b: Area3D = ProjectilePool.acquire(get_tree(), true)
	_check(a == b, "pool devolve o mesmo Area3D (sem churn de alocação)")
	ProjectilePool.release(b)
	_check(ProjectilePool.stash_size() >= 1, "pool estaciona nós em vez de os destruir")
	print("SMOKE|PERF fps=%.1f" % Performance.get_monitor(Performance.TIME_FPS))
	print("SMOKE|PERF proc_ms=%.3f" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	print("SMOKE|PERF phys_ms=%.3f" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0))
	print("SMOKE|PERF mem_static_mb=%.2f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	print("SMOKE|PERF objects=%d" % int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	print("SMOKE|PERF nodes=%d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("SMOKE|PERF orphans=%d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	print("SMOKE|DONE falhas=", _failures)
	get_tree().quit(0 if _failures == 0 else 1)
