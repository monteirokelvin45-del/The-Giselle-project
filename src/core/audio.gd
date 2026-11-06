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

# -------------------------------------------------------- música dinâmica ---
var _music_player: AudioStreamPlayer = null
var _music_mode: String = ""
const MUSIC_VOL := {"exploration": -14.0, "combat": -9.0, "system": -15.0}

func play_music(mode: String) -> void:
	if not GameState.music_enabled:
		mode = "off"
	if mode == _music_mode:
		return
	_music_mode = mode
	_stop_music()
	if mode == "off":
		return
	var path := "res://assets/audio/music/%s.wav" % mode
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamWAV = load(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = stream.data.size() / 2   # 16-bit mono → frames
	_music_player = AudioStreamPlayer.new()
	_music_player.stream = stream
	_music_player.volume_db = float(MUSIC_VOL.get(mode, -12.0))
	add_child(_music_player)
	_music_player.play()

func _stop_music() -> void:
	if _music_player != null:
		_music_player.stop()
		_music_player.queue_free()
		_music_player = null

func set_music_enabled(enabled: bool) -> void:
	GameState.music_enabled = enabled
	if enabled:
		_music_mode = ""
	else:
		_stop_music()
		_music_mode = "off"
	GameState.stats_changed.emit()

func master_volume_db() -> float:
	return AudioServer.get_bus_volume_db(0)

func set_master_volume_db(db: float) -> void:
	AudioServer.set_bus_volume_db(0, db)
