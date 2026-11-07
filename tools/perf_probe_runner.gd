## Perf probe headless: sobe o mundo principal, deixa correr ~12 s de jogo e
## mede os monitores do motor disponíveis SEM GPU (CPU-side). Não substitui
## profiling em hardware real (F5), mas regista números honestos por commit.
## Uso: godot --headless --path . res://tools/perf_probe.tscn
extends Node3D

var _t: float = 0.0
var _reported: bool = false

func _ready() -> void:
	var scene := load("res://scenes/main.tscn")
	if scene == null:
		print("SMOKE|FAIL main.tscn carregou para a sonda de perf")
		get_tree().quit(1)
		return
	add_child(scene.instantiate())

func _process(delta: float) -> void:
	_t += delta
	if _t < 12.0 or _reported:
		return
	_reported = true
	print("SMOKE|PERF engine=", String(Engine.get_version_info().get("string", "?")))
	print("SMOKE|PERF fps=%.1f" % Performance.get_monitor(Performance.TIME_FPS))
	print("SMOKE|PERF proc_ms=%.3f" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0))
	print("SMOKE|PERF phys_ms=%.3f" % (Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0))
	print("SMOKE|PERF mem_static_mb=%.2f" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0))
	print("SMOKE|PERF objects=%d" % int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	print("SMOKE|PERF nodes=%d" % int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
	print("SMOKE|PERF orphans=%d" % int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)))
	print("SMOKE|DONE falhas=0")
	get_tree().quit(0)
