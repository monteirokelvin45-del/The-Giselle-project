extends Node
## Pequeno motor de efeitos sonoros (WAVs sintetizados em assets/audio/).

var _streams: Dictionary = {}

const NAMES := [
	"swing", "hit", "heavy_hit", "parry", "posture_break", "potion",
	"rupture", "quest_done", "levelup", "click", "herb", "death",
]

func _ready() -> void:
	for n in NAMES:
		var path := "res://assets/audio/%s.wav" % n
		if ResourceLoader.exists(path):
			_streams[n] = load(path)

func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream: AudioStream = _streams.get(sound_name)
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

func master_volume_db() -> float:
	return AudioServer.get_bus_volume_db(0)

func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)
