## Ciclo dia/noite do mundo aberto (main.tscn). O relógio vive em
## GameState.world_day_t (0–1, 0.3 ≈ manhã). ~4 minutos por ciclo —
## o mesmo ritmo das regiões de expedição: luz, nevoeiro e cores de
## céu transitam; entradas e saídas da noite avisam o jogador.
extends Node3D

var sun: DirectionalLight3D
var env: Environment
var sky_mat: ProceduralSkyMaterial
var fog_day: float = 0.0058
var _was_night: bool = false

func _ready() -> void:
	_was_night = _is_night()

func _is_night() -> bool:
	var daylight := clampf(sin(GameState.world_day_t * PI), 0.0, 1.0)
	return daylight < 0.22

func _process(delta: float) -> void:
	GameState.world_day_t += delta / 240.0
	if GameState.world_day_t > 1.0:
		GameState.world_day_t -= 1.0
	var t := GameState.world_day_t
	var daylight := clampf(sin(t * PI), 0.0, 1.0)
	if sun != null:
		sun.rotation_degrees.x = lerp(-20.0, -160.0, t)
		sun.light_energy = 0.28 + 0.97 * daylight
		sun.light_color = Color(0.62, 0.68, 0.9).lerp(Color(1.0, 0.94, 0.82), daylight)
	if env != null:
		env.ambient_light_energy = 0.24 + 0.51 * daylight
		env.fog_density = fog_day * (1.0 + 1.1 * (1.0 - daylight))
	if sky_mat != null:
		sky_mat.sky_horizon_color = Color(0.02, 0.02, 0.07).lerp(Color(0.82, 0.75, 0.6), daylight)
		sky_mat.sky_top_color = Color(0.02, 0.02, 0.1).lerp(Color(0.18, 0.38, 0.68), daylight)
	var night := daylight < 0.22
	if night != _was_night:
		_was_night = night
		if night:
			GameState.notify("A NOITE CAI — espreitam coisas na floresta.")
		else:
			GameState.notify("AURORA — os vultos recuam para as sombras.")
