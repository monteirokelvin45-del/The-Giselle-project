extends Node
## Frente-de-caixa completa: HUD, notificações, menu de pausa, atributos,
## controlos, a Decisão final e os créditos. Autoload "UI".

var in_game := false
var pause_open := false
var attributes_open := false
var controls_open := false
var decision_open := false
var ending_open := false
var external_block := false
var map_open := false
var factions_open := false

var _layer: CanvasLayer
var _hud: Control
var _pause_overlay: Control
var _difficulty_btn: Button
var _music_btn: Button
var _colorblind_btn: Button
var _subtitle_btn: Button
var _aim_btn: Button
var _cel_btn: Button
var _narration_btn: Button
var _voice_btn: Button
var _rebinding: String = ""
var _rebind_rows: Dictionary = {}
var _rebind_hint: Label

func _music_text() -> String:
	return tr("Música: %s") % (tr("Ligada") if GameState.music_enabled else tr("Desligada"))

func _toggle_music() -> void:
	Audio.set_music_enabled(not GameState.music_enabled)
	_music_btn.text = tr(_music_text())
	notify(tr("Música %s.") % ("ativada" if GameState.music_enabled else "desligada"))

func _reapply_binding(dict: Dictionary) -> bool:
	if _rebinding == "":
		return false
	if dict.is_empty():
		_cancel_rebind()
		return false
	GameState.custom_bindings[_rebinding] = [dict]
	Keymap.apply_custom_bindings(GameState.custom_bindings)
	var btn = _rebind_rows.get(_rebinding)
	if btn != null:
		btn.text = tr(Keymap.binding_summary(_rebinding))
	notify(tr("Controlo atualizado: %s") % String(Keymap.ACTION_NAMES.get(_rebinding, _rebinding)))
	_cancel_rebind()
	return true

func _start_rebind(action: String) -> void:
	_rebinding = action
	_rebind_hint.text = tr("Prime a nova tecla/botão para «%s» — Esc cancela") % String(Keymap.ACTION_NAMES.get(action, action))
	_rebind_hint.visible = true

func _cancel_rebind() -> void:
	_rebinding = ""
	if _rebind_hint != null:
		_rebind_hint.visible = false

func _reset_bindings() -> void:
	GameState.custom_bindings.clear()
	Keymap.apply_custom_bindings({})
	for action in _rebind_rows:
		(_rebind_rows[action] as Button).text = Keymap.binding_summary(String(action))
	notify("Controlos repostos para as predefinições.")

func _colorblind_text() -> String:
	return tr("Daltonismo: %s") % [tr("Desligado"), tr("Protanopia"), tr("Deuteranopia"), tr("Tritanopia")][clampi(GameState.colorblind_mode, 0, 3)]

func _cycle_colorblind() -> void:
	GameState.colorblind_mode = (GameState.colorblind_mode + 1) % 4
	_colorblind_btn.text = tr(_colorblind_text())
	_apply_colorblind()
	notify(tr("Modo de daltonismo: %s") % ["desligado", "protanopia", "deuteranopia", "tritanopia"][GameState.colorblind_mode])

func _apply_colorblind() -> void:
	var palettes := [
		[Color(0.82, 0.25, 0.25), Color(0.42, 0.78, 0.38), Color(0.95, 0.62, 0.15)],   # original
		[Color(0.0, 0.447, 0.698), Color(0.902, 0.624, 0.0), Color(0.941, 0.894, 0.259)],  # protanopia (Okabe-Ito)
		[Color(0.0, 0.447, 0.698), Color(0.902, 0.624, 0.0), Color(0.941, 0.894, 0.259)],  # deuteranopia
		[Color(0.835, 0.369, 0.0), Color(0.0, 0.62, 0.451), Color(0.8, 0.475, 0.655)],      # tritanopia
	]
	var p: Array = palettes[clampi(GameState.colorblind_mode, 0, 3)]
	var bars: Array[ProgressBar] = [_hp_bar, _stamina_bar, _rupture_bar]
	for i in range(3):
		var bar: ProgressBar = bars[i]
		if bar == null:
			continue
		var sb := bar.get_theme_stylebox("fill")
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).bg_color = p[i]

func _subtitle_text() -> String:
	return tr("Legenda: %d%%") % int(GameState.subtitle_scale * 100.0)

func _cycle_subtitle() -> void:
	var scales := [0.8, 1.0, 1.25, 1.5]
	var idx := 1
	for i in range(scales.size()):
		if is_equal_approx(scales[i], GameState.subtitle_scale):
			idx = i
			break
	idx = (idx + 1) % scales.size()
	GameState.subtitle_scale = scales[idx]
	Dialogue.set_subtitle_scale(GameState.subtitle_scale)
	_subtitle_btn.text = tr(_subtitle_text())
	notify(tr("Tamanho da legenda: %d%%") % int(GameState.subtitle_scale * 100.0))

func _aim_text() -> String:
	return tr("Assistência de mira: %s") % (tr("Ligada") if GameState.aim_assist else tr("Desligada"))

func _cel_text() -> String:
	return tr("Cel-shading: %s") % (tr("Ligada") if GameState.cel_toon else tr("Desligada"))

func _cycle_cel() -> void:
	GameState.cel_toon = not GameState.cel_toon
	_cel_btn.text = tr(_cel_text())
	notify(tr("Cel-shading %s — requer recarregar a cena.") % (tr("ativada") if GameState.cel_toon else tr("desativada")))

func _cycle_aim_assist() -> void:
	GameState.aim_assist = not GameState.aim_assist
	_aim_btn.text = tr(_aim_text())
	notify(tr("Assistência de mira %s.") % ("ativada" if GameState.aim_assist else "desligada"))

func _narration_text() -> String:
	return tr("Narração de menus: %s") % (tr("Ligada") if GameState.menu_narration else tr("Desligada"))

func _cycle_narration() -> void:
	GameState.menu_narration = not GameState.menu_narration
	_narration_btn.text = tr(_narration_text())
	notify(tr("Narração de menus %s.") % ("ativada" if GameState.menu_narration else "desligada"))

func _voice_text() -> String:
	return tr("Narração — voz: %s  ⟳") % GameState.tts_voice_label()

func _cycle_voice() -> void:
	GameState.cycle_tts_voice()
	_voice_btn.text = tr(_voice_text())
	notify(tr("Voz da narração: %s") % GameState.tts_voice_label())

func _tts_say(text: String) -> void:
	GameState.tts_say(text)

func _difficulty_text() -> String:
	return tr("Dificuldade: %s  ⟳") % tr(GameState.difficulty_label())

func _cycle_difficulty() -> void:
	GameState.cycle_difficulty()
	if _difficulty_btn != null:
		_difficulty_btn.text = tr(_difficulty_text())
var _attributes_overlay: Control
var _controls_overlay: Control
var _decision_overlay: Control
var _ending_overlay: Control

# HUD
var _level_label: Label
var _xp_bar: ProgressBar
var _hp_bar: ProgressBar
var _stamina_bar: ProgressBar
var _rupture_bar: ProgressBar
var _marcos_label: Label
var _potions_label: Label
var _objective_label: Label
var _side_box: VBoxContainer
var _enemy_name_label: Label
var _posture_bar: ProgressBar
var _posture_box: VBoxContainer
var _prompt_label: Label
var _rupture_ready: Label
var _crosshair: ColorRect
var _controls_hint: Label
var _ability_box: HBoxContainer
var _ability_slots: Dictionary = {}
var _technique_box: HBoxContainer
var _technique_slots: Dictionary = {}
var _ability_timer: float = 0.0
var _notif_label: Label

var _notif_queue: Array[String] = []
var _notif_time := 0.0
var _time := 0.0
var _player_cache: Node3D = null
var _enemy_hp_bar: ProgressBar
var _hit_marker: Label
var _combo_label: Label
var _stagger_label: Label
var _vignette: TextureRect
var _boss_box: Control
var _boss_title: Label
var _boss_sub: Label
var _boss_time: float = 0.0
var _boss_banner_shown: bool = false
var _vignette_hit: float = 0.0
var _hit_marker_t: float = 0.0
var _hit_marker_hooked: bool = false
var _damage_hooked: bool = false

const ENDINGS := {
	"academia": {
		"title": "O Reformado",
		"choice": "«Tomo o lugar na Academia Real de Veyra.»",
		"desc": "Mudar o sistema de dentro para fora.",
		"text": "Kael Noro atravessa os portões de Veyra ao amanhecer, com a Corrente de Âncora à cintura e o Sistema em silêncio.\n\nMudar um mundo que adora o Núcleo Arcano não será obra de um dia, nem de um ano. Será obra de uma vida: um currículo aberto aos sem-magia, um arquivo proibido a ser revelado, sala a sala, professor a professor.\n\nA Academia não esqueceu o Vazio. O Vazio, agora, faz parte dela.",
	},
	"vagabundo": {
		"title": "O Herói Errante",
		"choice": "«Recuso cargos. A estrada é minha.»",
		"desc": "Nem rei, nem governador, nem diretor.",
		"text": "Kael Noro sorri perante as propostas — e recusa-as.\n\nSoldados procuram-no. Aldeias inteiras falam dele em voz baixa: o homem que derrubou o Guardião da Prova com as próprias mãos. A estrada abre-se como um livro que ninguém escreveu ainda.\n\nHá sempre uma ponte a cair, uma aldeia esquecida, um monstro na montanha. E há sempre um rapaz sem magia a chegar.",
	},
	"revolta": {
		"title": "A Chama dos Sem-Núcleo",
		"choice": "«A igualdade não se pede. Constrói-se.»",
		"desc": "Liderar os que foram esquecidos pelo mundo.",
		"text": "Quando Kael levanta a voz na zona dos Sem-Núcleo, ninguém pede silêncio.\n\nNão há Núcleo nesta sala. Há mãos abertas, ferramentas em riste, filhos de curandeiras e forjados pelos ribeiros de Noro. Se a magia construiu um mundo de portas fechadas, então eles serão a chave — ou a porta deitada abaixo.\n\nO Sistema observa em silêncio. Pela primeira vez, parece... curioso.",
	},
	"estandarte": {
		"title": "O Regente do Norte",
		"choice": "«Pego na espada do Conselho Imperial.»",
		"desc": "Um trono para um sem-magia. (Requer: Conselho Imperial 40+)",
		"req": {"faction": "imperial", "amount": 40},
		"text": "Quando o Conselho Imperial ergue Kael Noro como Regente do Norte, os marechais rangem os dentes — e curvam-se na mesma.\n\nUm homem sem Núcleo, com o peso de um trono de aço e estatutos em revisão. O Império aprende a sua primeira lição: a força nunca foi o monopólio dos magos.\n\nA segunda lição... vem depois.",
	},
	"arquivo": {
		"title": "O Guardião do Arquivo",
		"choice": "«Desço abaixo da torre poente.»",
		"desc": "Revelar o Arquivo Proibido. (Requer: Arquivistas 40+)",
		"req": {"faction": "arquivistas", "amount": 40},
		"text": "Abaixo da torre poente, onde noventa anos de poeira esquentaram os segredos, Kael Noro abre a porta que ninguém abriu.\n\nO Arquivo Proibido não queima — revela. Cada página é uma sentença sobre a magia: de onde veio, o que custou, quem a escondeu. Kael torna-se o Guardião do Arquivo — o homem que decide o que o mundo pode ler.\n\nO mundo, pela primeira vez, lê.",
	},
	"vacuo": {
		"title": "O Lugar-Vazio",
		"choice": "«Rasgo o decreto de ligação.»",
		"desc": "Destruir a lei dos Núcleos. (Requer: Irmandade do Vácuo 40+)",
		"req": {"faction": "irmandade", "amount": 40},
		"text": "Kael não destrói os Núcleos — destrói a lei que os tornou sagrados.\n\nNa Praça de Veyra, diante do Conselho, ele rasga o decreto de ligação e deita-o ao vento como a sua própria faixa de olhos. Os sem-magia erguem-se; os magos abdicam; os cépticos calam-se.\n\nO Sistema, finalmente, escolhe um lado — o lado do Vácuo: o lugar que ficou vazio quando Kael desapareceu, e voltou maior do que cabe no mundo.",
	},
}

const ROMANCE_EPILOGUES := {
	"liora": "Liora fica. Não como conselheira, não como mestre — fica como o corpo e o sossego de uma escolha.\nNos mapas que ela desenha agora, há um lugar marcado apenas «casa».",
	"bram": "Bram funde duas lâminas numa só — «para quem for», diz ele, e não explica mais.\nAs noites de festa da forja passam a ter sempre dois copos na mesa.",
	"sena": "Sena planta algo novo no jardim da Academia: uma árvore que ninguém reconhece.\n«Nasce quando o amor quer», diz ela. Chama-se, por agora, apenas «Kael».",
	"iven": "Iven navega. Sempre navegou. Mas agora, na última vigília antes de cada viagem, escreve uma carta — e a carta começa sempre da mesma maneira:\n«Kael, o porto continua aqui à tua espera.»",
}
## Se a lealdade subiu ≥ 60 (prova superada juntos), o epílogo reconhece —
## memória de ações do jogador, não só a declaração de romance.
const ROMANCE_EPILOGUES_WARM := {
	"liora": "Liora fica — e fica porque lutaste com ela, não só por ela. Não como conselheira: como o corpo e o sossego de uma escolha provada.\nNos mapas que ela desenha agora, há um lugar marcado apenas «casa», e a rota até ele está sempre aberta.",
	"bram": "Bram funde três lâminas numa só — «duas para ti, forasteiro» —, e ri-se baixinho pela primeira vez em anos.\nAs noites da forja têm sempre dois copos. E tu sabes segurá-los.",
	"sena": "Sena planta contigo, mão sobre mão. A árvore que ninguém reconhece nasceu do teu silêncio e das tuas provas — agora já deita fora.\nChama-se «Kael», mas no jardim todos sabem que significa «provado».",
	"iven": "Iven navega contigo neste último porto. A carta que escrevia antes de partir agora começa de outra maneira:\n«Kael, volta, o cais já conhece o teu passo.»",
}

func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 15
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)
	_build_hud()
	_build_pause()
	_build_attributes()
	_build_controls()
	_apply_colorblind()
	Dialogue.set_subtitle_scale(GameState.subtitle_scale)
	_build_map()
	_build_factions()
	_build_decision()
	_build_ending()
	GameState.notify_requested.connect(notify)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.stats_changed.connect(_refresh_stats)

func is_blocking() -> bool:
	return pause_open or attributes_open or controls_open or decision_open or ending_open or external_block or map_open or factions_open

func set_in_game(value: bool) -> void:
	in_game = value
	_hud.visible = value
	_crosshair.visible = value
	if value:
		_refresh_stats()
		_objective_label.text = tr(GameState.objective_text())
		_rebuild_side_objectives()
	else:
		_close_all_overlays()
		get_tree().paused = false

func notify(text: String) -> void:
	var shown := tr(text)
	if GameState.menu_narration:
		_tts_say(shown)
	_notif_queue.append(shown)
	if _notif_queue.size() > 4:
		_notif_queue.pop_front()

# ------------------------------------------------------------------ HUD -----
func _make_bar(width: float, height: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.max_value = 100.0
	bar.min_value = 0.0
	bar.value = 100.0
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.05, 0.06, 0.75)
	bg.corner_radius_top_left = int(height * 0.5)
	bg.corner_radius_bottom_left = int(height * 0.5)
	bg.corner_radius_top_right = int(height * 0.5)
	bg.corner_radius_bottom_right = int(height * 0.5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.corner_radius_top_left = bg.corner_radius_top_left
	fg.corner_radius_bottom_left = bg.corner_radius_bottom_left
	fg.corner_radius_top_right = bg.corner_radius_top_right
	fg.corner_radius_bottom_right = bg.corner_radius_bottom_right
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar

func _make_vignette_texture() -> ImageTexture:
	var size := 256
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size / 2.0, size / 2.0)
	for y in range(size):
		for x in range(size):
			var d: float = Vector2(x + 0.5, y + 0.5).distance_to(center) / (size * 0.5)
			var a: float = clampf((d - 0.55) / 0.45, 0.0, 1.0)
			a = a * a * 0.85
			img.set_pixel(x, y, Color(0.55, 0.03, 0.02, a))
	return ImageTexture.create_from_image(img)

func _on_hit_landed() -> void:
	_hit_marker_t = 0.18

func _on_player_damaged() -> void:
	_vignette_hit = 0.55

func _build_hud() -> void:
	_hud = Control.new()
	_hud.anchor_right = 1.0
	_hud.anchor_bottom = 1.0
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.visible = false
	_layer.add_child(_hud)

	# Vinheta de dano/vida baixa (atrás de tudo no HUD — só molduras)
	_vignette = TextureRect.new()
	_vignette.texture = _make_vignette_texture()
	_vignette.anchor_right = 1.0
	_vignette.anchor_bottom = 1.0
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.modulate.a = 0.0
	_hud.add_child(_vignette)

	# Bloco superior esquerdo
	var left := MarginContainer.new()
	left.position = Vector2(18, 16)
	_hud.add_child(left)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	left.add_child(vbox)
	_level_label = _make_label("Nv 1", 15, Color(0.95, 0.87, 0.6))
	vbox.add_child(_level_label)
	_xp_bar = _make_bar(230, 5, Color(0.85, 0.68, 0.25))
	vbox.add_child(_xp_bar)
	_hp_bar = _make_bar(230, 16, Color(0.82, 0.25, 0.25))
	vbox.add_child(_hp_bar)
	_stamina_bar = _make_bar(230, 11, Color(0.42, 0.78, 0.38))
	vbox.add_child(_stamina_bar)
	_rupture_bar = _make_bar(230, 9, Color(0.95, 0.62, 0.15))
	vbox.add_child(_rupture_bar)
	_marcos_label = _make_label("◈ 75 marcos", 13, Color(0.9, 0.78, 0.35))
	vbox.add_child(_marcos_label)
	_potions_label = _make_label("Poções: 2  (R)", 13, Color(0.62, 0.82, 0.95))
	vbox.add_child(_potions_label)

	# Habilidades dos companheiros (canais 1–4), inferior esquerdo
	_ability_box = HBoxContainer.new()
	_ability_box.anchor_top = 1.0
	_ability_box.anchor_bottom = 1.0
	_ability_box.offset_left = 18.0
	_ability_box.offset_top = -82.0
	_ability_box.offset_bottom = -14.0
	_ability_box.add_theme_constant_override("separation", 8)
	_hud.add_child(_ability_box)
	for aid in ["liora", "bram", "sena", "iven"]:
		_ability_slots[aid] = _make_ability_slot(aid)
	_technique_box = HBoxContainer.new()
	_technique_box.anchor_top = 1.0
	_technique_box.anchor_bottom = 1.0
	_technique_box.offset_left = 18.0
	_technique_box.offset_top = -150.0
	_technique_box.offset_bottom = -88.0
	_technique_box.add_theme_constant_override("separation", 8)
	_hud.add_child(_technique_box)
	for tid in ["passo_vazio", "corrida_predador", "queda_colosso"]:
		_technique_slots[tid] = _make_technique_slot(tid)

	# Painel de objetivo (superior direito)
	var obj := PanelContainer.new()
	obj.anchor_left = 1.0
	obj.anchor_right = 1.0
	obj.offset_left = -356.0
	obj.offset_right = -16.0
	obj.offset_top = 16.0
	obj.custom_minimum_size = Vector2(340, 0)
	var obj_style := StyleBoxFlat.new()
	obj_style.bg_color = Color(0.08, 0.07, 0.06, 0.62)
	obj_style.corner_radius_top_left = 8
	obj_style.corner_radius_top_right = 8
	obj_style.corner_radius_bottom_left = 8
	obj_style.corner_radius_bottom_right = 8
	obj_style.set_content_margin_all(10.0)
	obj.add_theme_stylebox_override("panel", obj_style)
	_hud.add_child(obj)
	var obj_vbox := VBoxContainer.new()
	obj_vbox.add_theme_constant_override("separation", 4)
	obj.add_child(obj_vbox)
	var obj_title := _make_label("◈ OBJETIVO", 12, Color(0.87, 0.7, 0.3))
	obj_vbox.add_child(obj_title)
	_objective_label = _make_label("...", 14, Color(0.96, 0.94, 0.88))
	_objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_objective_label.custom_minimum_size = Vector2(310, 0)
	obj_vbox.add_child(_objective_label)
	_side_box = VBoxContainer.new()
	_side_box.add_theme_constant_override("separation", 2)
	obj_vbox.add_child(_side_box)

	# Prompt de interação (fundo centro)
	_prompt_label = _make_label("", 17, Color(0.98, 0.95, 0.8))
	_prompt_label.anchor_left = 0.5
	_prompt_label.anchor_right = 0.5
	_prompt_label.anchor_top = 1.0
	_prompt_label.anchor_bottom = 1.0
	_prompt_label.offset_left = -260.0
	_prompt_label.offset_right = 260.0
	_prompt_label.offset_top = -218.0
	_prompt_label.offset_bottom = -186.0
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_constant_override("outline_size", 6)
	_prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_prompt_label.visible = false
	_hud.add_child(_prompt_label)

	# Bloco de postura do alvo (inferior centro)
	_posture_box = VBoxContainer.new()
	_posture_box.anchor_left = 0.5
	_posture_box.anchor_right = 0.5
	_posture_box.anchor_top = 1.0
	_posture_box.anchor_bottom = 1.0
	_posture_box.offset_left = -170.0
	_posture_box.offset_right = 170.0
	_posture_box.offset_top = -150.0
	_posture_box.offset_bottom = -120.0
	_posture_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_posture_box.visible = false
	_hud.add_child(_posture_box)
	_enemy_name_label = _make_label("Inimigo", 13, Color(0.95, 0.6, 0.4))
	_enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_posture_box.add_child(_enemy_name_label)
	_enemy_hp_bar = _make_bar(300, 12, Color(0.88, 0.32, 0.22))
	_posture_box.add_child(_enemy_hp_bar)
	_posture_bar = _make_bar(300, 10, Color(0.75, 0.55, 0.95))
	_posture_box.add_child(_posture_bar)

	# Aviso de Ruptura pronta
	_rupture_ready = _make_label("RUPTURA PRONTA — [F]", 19, Color(1.0, 0.75, 0.2))
	_rupture_ready.anchor_left = 0.5
	_rupture_ready.anchor_right = 0.5
	_rupture_ready.anchor_top = 1.0
	_rupture_ready.anchor_bottom = 1.0
	_rupture_ready.offset_left = -180.0
	_rupture_ready.offset_right = 180.0
	_rupture_ready.offset_top = -280.0
	_rupture_ready.offset_bottom = -248.0
	_rupture_ready.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rupture_ready.visible = false
	_hud.add_child(_rupture_ready)

	# Notificações (topo centro)
	_notif_label = _make_label("", 17, Color(0.98, 0.92, 0.7))
	_notif_label.anchor_left = 0.5
	_notif_label.anchor_right = 0.5
	_notif_label.anchor_top = 0.0
	_notif_label.anchor_bottom = 0.0
	_notif_label.offset_left = -370.0
	_notif_label.offset_right = 370.0
	_notif_label.offset_top = 84.0
	_notif_label.offset_bottom = 116.0
	_notif_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_notif_label.add_theme_constant_override("outline_size", 6)
	_notif_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_notif_label.modulate.a = 0.0
	_hud.add_child(_notif_label)

	# Marcador de impacto (X no centro, flash de 0,18s)
	_hit_marker = _make_label("✕", 34, Color(1.0, 0.9, 0.6))
	_hit_marker.anchor_left = 0.5
	_hit_marker.anchor_right = 0.5
	_hit_marker.anchor_top = 0.5
	_hit_marker.anchor_bottom = 0.5
	_hit_marker.offset_left = -20.0
	_hit_marker.offset_right = 20.0
	_hit_marker.offset_top = -52.0
	_hit_marker.offset_bottom = -12.0
	_hit_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hit_marker.add_theme_constant_override("outline_size", 8)
	_hit_marker.add_theme_color_override("font_outline_color", Color(0.2, 0.08, 0.02, 0.9))
	_hit_marker.modulate.a = 0.0
	_hud.add_child(_hit_marker)

	# Contador de combo (à direita da mira)
	_combo_label = _make_label("×2", 30, Color(1.0, 0.78, 0.3))
	_combo_label.anchor_left = 0.5
	_combo_label.anchor_top = 0.5
	_combo_label.offset_left = 78.0
	_combo_label.offset_right = 170.0
	_combo_label.offset_top = -24.0
	_combo_label.offset_bottom = 24.0
	_combo_label.add_theme_constant_override("outline_size", 8)
	_combo_label.add_theme_color_override("font_outline_color", Color(0.2, 0.08, 0.02, 0.9))
	_combo_label.modulate.a = 0.0
	_hud.add_child(_combo_label)

	# Aviso de "GOLPEIA AGORA" (alvo atordoado)
	_stagger_label = _make_label("GOLPEIA AGORA", 24, Color(1.0, 0.85, 0.35))
	_stagger_label.anchor_left = 0.5
	_stagger_label.anchor_right = 0.5
	_stagger_label.anchor_top = 1.0
	_stagger_label.anchor_bottom = 1.0
	_stagger_label.offset_left = -200.0
	_stagger_label.offset_right = 200.0
	_stagger_label.offset_top = -352.0
	_stagger_label.offset_bottom = -322.0
	_stagger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stagger_label.add_theme_constant_override("outline_size", 8)
	_stagger_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_stagger_label.visible = false
	_hud.add_child(_stagger_label)

	# Banner do chefe (primeira vez que o Guardião é fereido)
	_boss_box = Control.new()
	_boss_box.anchor_left = 0.5
	_boss_box.anchor_right = 0.5
	_boss_box.anchor_top = 0.5
	_boss_box.anchor_bottom = 0.5
	_boss_box.offset_left = -430.0
	_boss_box.offset_right = 430.0
	_boss_box.offset_top = -140.0
	_boss_box.offset_bottom = -50.0
	_boss_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boss_box.modulate.a = 0.0
	_boss_box.visible = false
	_hud.add_child(_boss_box)
	var band := ColorRect.new()
	band.color = Color(0.05, 0.04, 0.03, 0.72)
	band.anchor_right = 1.0
	band.anchor_bottom = 1.0
	_boss_box.add_child(band)
	_boss_title = _make_label("O GUARDIÃO DA PROVA", 40, Color(0.98, 0.78, 0.32))
	_boss_title.anchor_right = 1.0
	_boss_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_title.offset_top = 10.0
	_boss_title.offset_bottom = 60.0
	_boss_title.add_theme_constant_override("outline_size", 10)
	_boss_title.add_theme_color_override("font_outline_color", Color(0.15, 0.05, 0.0, 0.95))
	_boss_box.add_child(_boss_title)
	_boss_sub = _make_label("O último obstáculo entre ti e o final da Prova.", 15, Color(0.85, 0.84, 0.8))
	_boss_sub.anchor_right = 1.0
	_boss_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_sub.offset_top = 58.0
	_boss_sub.offset_bottom = 88.0
	_boss_sub.add_theme_constant_override("outline_size", 6)
	_boss_sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_boss_box.add_child(_boss_sub)

	# Mira (ponto central)
	_crosshair = ColorRect.new()
	_crosshair.color = Color(0.95, 0.93, 0.85, 0.9)
	_crosshair.anchor_left = 0.5
	_crosshair.anchor_right = 0.5
	_crosshair.anchor_top = 0.5
	_crosshair.anchor_bottom = 0.5
	_crosshair.offset_left = -2.5
	_crosshair.offset_right = 2.5
	_crosshair.offset_top = -2.5
	_crosshair.offset_bottom = 2.5
	_crosshair.visible = false
	_hud.add_child(_crosshair)

	# Dicas de controlos (inferior esquerdo)
	_controls_hint = _make_label("M1 ataque leve · M2 pesado · Espaço esquiva · Q bloquear/parry\nE interagir/Corrente · R poção · F Ruptura · Tab fixar · Esc menu", 11, Color(0.65, 0.66, 0.62, 0.9))
	_controls_hint.anchor_bottom = 1.0
	_controls_hint.anchor_top = 1.0
	_controls_hint.offset_left = 14.0
	_controls_hint.offset_top = -44.0
	_controls_hint.offset_bottom = -12.0
	_controls_hint.offset_right = 560.0
	_hud.add_child(_controls_hint)

func _make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = tr(text)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label

func _on_objective_changed(_text: String) -> void:
	_objective_label.text = tr(GameState.objective_text())
	_rebuild_side_objectives()

func _rebuild_side_objectives() -> void:
	for child in _side_box.get_children():
		child.queue_free()
	for line in GameState.side_objectives():
		var l := _make_label("· " + line, 12, Color(0.72, 0.78, 0.65))
		_side_box.add_child(l)

func _make_technique_slot(tid: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(132, 58)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.07, 0.14, 0.72)
	style.border_color = Color(0.72, 0.55, 0.95, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	var info: Dictionary = {
		"passo_vazio": {"key": "V", "name": "PASSO VAZIO"},
		"corrida_predador": {"key": "C", "name": "CORRIDA DO PREDADOR"},
		"queda_colosso": {"key": "Z", "name": "QUEDA DO COLOSSO"},
	}[tid]
	var name_label := Label.new()
	name_label.text = tr("%s — %s") % [String(info["key"]), String(info["name"])]
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(0.82, 0.7, 1.0))
	vbox.add_child(name_label)
	var status_label := Label.new()
	status_label.text = tr("PRONTA")
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.75, 0.6, 0.98))
	vbox.add_child(status_label)
	_technique_box.add_child(panel)
	return {"box": panel, "status": status_label}

func _make_ability_slot(aid: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(150, 62)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.06, 0.68)
	style.border_color = Color(0.62, 0.78, 0.9, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	panel.add_child(vbox)
	var info: Dictionary = {
		"liora": {"key": "1", "name": "MURMÚRIO DE VÉU"},
		"bram": {"key": "2", "name": "ECO DE FORJA"},
		"sena": {"key": "3", "name": "SEIVA"},
		"iven": {"key": "4", "name": "PASSO DE HORIZONTE"},
	}[aid]
	var name_label := Label.new()
	name_label.text = tr("%s — %s") % [String(info["key"]), String(info["name"])]
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", Color(0.72, 0.86, 0.97))
	vbox.add_child(name_label)
	var status_label := Label.new()
	status_label.text = tr("PRONTA")
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.55))
	vbox.add_child(status_label)
	_ability_box.add_child(panel)
	return {"box": panel, "status": status_label}

func _refresh_abilities() -> void:
	if _player_cache == null or not is_instance_valid(_player_cache):
		_player_cache = get_tree().get_first_node_in_group("player")
	var cds: Variant = null
	if _player_cache != null:
		cds = _player_cache.get("ability_cooldowns")
	for aid in _ability_slots:
		var slot: Dictionary = _ability_slots[aid]
		var owned := GameState.companions.has(aid)
		slot["box"].visible = owned
		if not owned:
			continue
		var cd := 0.0
		if cds is Dictionary:
			cd = float((cds as Dictionary).get(aid, 0.0))
		var status: Label = slot["status"]
		if cd <= 0.0:
			status.text = tr("PRONTA")
			status.add_theme_color_override("font_color", Color(0.6, 0.9, 0.55))
		else:
			status.text = tr("RECARGA %.0fs") % cd
			status.add_theme_color_override("font_color", Color(0.85, 0.6, 0.3))
	_refresh_techniques()

func _refresh_techniques() -> void:
	if _player_cache == null or not is_instance_valid(_player_cache):
		_player_cache = get_tree().get_first_node_in_group("player")
	var cds: Variant = null
	if _player_cache != null:
		cds = _player_cache.get("technique_cooldowns")
	for tid in _technique_slots:
		var slot: Dictionary = _technique_slots[tid]
		var owned := GameState.technique_unlocked(String(tid))
		slot["box"].visible = owned
		if not owned:
			continue
		var cd := 0.0
		if cds is Dictionary:
			cd = float((cds as Dictionary).get(tid, 0.0))
		var status: Label = slot["status"]
		if cd <= 0.0:
			status.text = tr("PRONTA")
			status.add_theme_color_override("font_color", Color(0.75, 0.6, 0.98))
		else:
			status.text = tr("RECARGA %.0fs") % cd
			status.add_theme_color_override("font_color", Color(0.85, 0.6, 0.3))

func _refresh_stats() -> void:
	_level_label.text = tr("Nv %d  ·  %d/%d XP") % [GameState.level, GameState.xp, GameState.xp_needed()]
	_xp_bar.value = GameState.xp_progress() * 100.0
	_marcos_label.text = tr("◈ %d marcos") % GameState.marcos
	_potions_label.text = tr("Poções: %d  (R)") % GameState.potions
	_rebuild_side_objectives()

# ------------------------------------------------------------- processo -----
func _process(delta: float) -> void:
	_time += delta
	_ability_timer -= delta
	if _ability_timer <= 0.0:
		_ability_timer = 0.25
		_refresh_abilities()
	if _player_cache == null or not is_instance_valid(_player_cache):
		_player_cache = get_tree().get_first_node_in_group("player")
	if _player_cache != null and in_game:
		var p: Node3D = _player_cache
		var max_hp := GameState.max_hp()
		var max_st := GameState.max_stamina()
		_hp_bar.max_value = max_hp
		_hp_bar.value = clampf(float(p.get("hp")), 0.0, max_hp)
		_stamina_bar.max_value = max_st
		_stamina_bar.value = clampf(float(p.get("stamina")), 0.0, max_st)
		_rupture_bar.value = GameState.rupture
		_rupture_ready.visible = GameState.rupture >= 100.0
		if _rupture_ready.visible:
			_rupture_ready.modulate.a = 0.6 + 0.4 * sin(_time * 6.0)
		# Ligações de sinais do jogador (uma vez) — Object + lookup por
		# string: o compilador não conhece os sinais em Node3D tipado
		var p_obj: Object = p
		if not _hit_marker_hooked and p_obj.has_signal("attack_landed"):
			var sig_hit: Signal = p_obj.get("attack_landed")
			sig_hit.connect(_on_hit_landed)
			_hit_marker_hooked = true
		if not _damage_hooked and p_obj.has_signal("damaged"):
			var sig_dmg: Signal = p_obj.get("damaged")
			sig_dmg.connect(_on_player_damaged)
			_damage_hooked = true
		# Barras de vida/postura do alvo fixado
		var locked: Node3D = p.get("locked_enemy")
		if locked != null and is_instance_valid(locked):
			_posture_box.visible = true
			_enemy_name_label.text = tr(String(locked.get("display_name")))
			var max_e_hp := float(locked.get("max_hp"))
			if max_e_hp > 0.0:
				_enemy_hp_bar.value = clampf(float(locked.get("hp")) / max_e_hp * 100.0, 0.0, 100.0)
			var max_posture := float(locked.get("max_posture"))
			if max_posture > 0.0:
				_posture_bar.value = clampf(float(locked.get("posture")) / max_posture * 100.0, 0.0, 100.0)
			# Aviso de "GOLPEIA AGORA" (atordoado/postura quebrada)
			var stunned := 0.0
			if locked.get("_stunned") != null:
				stunned = float(locked.get("_stunned"))
			if stunned > 0.6:
				_stagger_label.visible = true
				_stagger_label.modulate.a = 0.65 + 0.35 * sin(_time * 8.0)
			else:
				_stagger_label.visible = false
		else:
			_posture_box.visible = false
			_stagger_label.visible = false
		# Contador de combo
		var combo := 0
		if p.get("_combo") != null:
			combo = int(p.get("_combo"))
		if combo >= 2:
			_combo_label.text = "×%d" % combo
			_combo_label.modulate.a = 1.0
		else:
			_combo_label.modulate.a = maxf(0.0, _combo_label.modulate.a - 4.0 * delta)
		# Vinheta de vida baixa + flash de dano
		var hp_now := float(p.get("hp"))
		_vignette_hit = maxf(0.0, _vignette_hit - delta * 1.7)
		var vignette_target := _vignette_hit * 0.6
		if hp_now < max_hp * 0.3:
			vignette_target += 0.20 + 0.07 * sin(_time * 5.0)
		_vignette.modulate.a = clampf(vignette_target, 0.0, 1.0)
		# Banner do Guardião (primeira vez que é ferido)
		if not _boss_banner_shown:
			for enemy in get_tree().get_nodes_in_group("enemy"):
				if not is_instance_valid(enemy):
					continue
				if enemy.get("enemy_type") == "guardiao" and float(enemy.get("hp")) < float(enemy.get("max_hp")) * 0.999:
					_boss_banner_shown = true
					_boss_time = 3.0
					break
		# Prompt de interação
		var target: Node3D = p.get("current_interactable")
		if target != null and is_instance_valid(target) and target.has_method("get_prompt"):
			_prompt_label.text = tr(target.get_prompt())
			_prompt_label.visible = not is_blocking() and not Dialogue.active
		else:
			_prompt_label.visible = false
	if _hit_marker_t > 0.0:
		_hit_marker_t -= delta
		_hit_marker.modulate.a = clampf(_hit_marker_t / 0.18, 0.0, 1.0)
	else:
		_hit_marker.modulate.a = 0.0
	if _boss_time > 0.0:
		_boss_time -= delta
		var elapsed := 3.0 - _boss_time
		var fade_in: float = clampf(elapsed / 0.3, 0.0, 1.0)
		var fade_out: float = clampf(_boss_time / 0.6, 0.0, 1.0)
		_boss_box.modulate.a = minf(fade_in, fade_out)
		_boss_box.visible = true
	else:
		_boss_box.visible = false
	# Notificações
	if _notif_time > 0.0:
		_notif_time -= delta
		if _notif_time <= 0.35 and _notif_label.modulate.a > 0.0:
			_notif_label.modulate.a = clampf(_notif_time / 0.35, 0.0, 1.0)
		if _notif_time <= 0.0:
			_notif_label.modulate.a = 0.0
	elif not _notif_queue.is_empty():
		_notif_label.text = tr(_notif_queue.pop_front())
		_notif_label.modulate.a = 1.0
		_notif_time = 2.8

func _unhandled_input(event: InputEvent) -> void:
	if _rebinding != "":
		if event is InputEventKey and event.pressed and not event.echo:
			var key_event := event as InputEventKey
			if key_event.keycode == KEY_ESCAPE:
				_cancel_rebind()
			elif _reapply_binding(Keymap.dict_from_event(event)):
				pass
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT and _reapply_binding(Keymap.dict_from_event(event)):
				get_viewport().set_input_as_handled()
				return
		if event is InputEventJoypadButton and event.pressed:
			_reapply_binding(Keymap.dict_from_event(event))
			get_viewport().set_input_as_handled()
			return
		return
	if event.is_action_pressed("pause"):
		if ending_open or decision_open or external_block:
			return
		if attributes_open:
			_toggle_attributes(false)
			return
		if controls_open:
			_toggle_controls(false)
			return
		if map_open:
			_toggle_map(false)
			return
		if factions_open:
			_toggle_factions(false)
			return
		if Dialogue.active:
			return
		if pause_open:
			_close_pause()
		elif in_game:
			_open_pause()

# ---------------------------------------------------------------- pausa -----
func _build_pause() -> void:
	_pause_overlay = _make_dim_overlay()
	var panel := _make_panel(470, 560)
	_pause_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := _make_label("A ACADEMIA DO ZERO", 15, Color(0.87, 0.7, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := _make_label("— PAUSADO —", 24, Color(0.97, 0.95, 0.9))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	vbox.add_child(_make_button("Continuar", _close_pause))
	vbox.add_child(_make_button("Atributos", func(): _toggle_attributes(true)))
	vbox.add_child(_make_button("Mapa de Arkanor", func(): _toggle_map(true)))
	vbox.add_child(_make_button("Facções", func(): _toggle_factions(true)))
	var system_btn := _make_button("Entrar no Sistema (Sala Branca)", _enter_system)
	system_btn.name = "SystemButton"
	vbox.add_child(system_btn)
	var decision_btn := _make_button("A DECISÃO", _open_decision)
	decision_btn.name = "DecisionButton"
	vbox.add_child(decision_btn)
	vbox.add_child(_make_button("Guardar Jogo", _save_game))
	var load_btn := _make_button("Carregar Jogo", _load_game)
	load_btn.name = "LoadButton"
	vbox.add_child(load_btn)
	_difficulty_btn = _make_button(_difficulty_text(), _cycle_difficulty)
	vbox.add_child(_difficulty_btn)
	_music_btn = _make_button(_music_text(), _toggle_music)
	vbox.add_child(_music_btn)
	_colorblind_btn = _make_button(_colorblind_text(), _cycle_colorblind)
	vbox.add_child(_colorblind_btn)
	_subtitle_btn = _make_button(_subtitle_text(), _cycle_subtitle)
	vbox.add_child(_subtitle_btn)
	_aim_btn = _make_button(_aim_text(), _cycle_aim_assist)
	vbox.add_child(_aim_btn)
	_cel_btn = _make_button(_cel_text(), _cycle_cel)
	vbox.add_child(_cel_btn)
	_narration_btn = _make_button(_narration_text(), _cycle_narration)
	vbox.add_child(_narration_btn)
	_voice_btn = _make_button(_voice_text(), _cycle_voice)
	vbox.add_child(_voice_btn)
	vbox.add_child(_make_button("Controlos", func(): _toggle_controls(true)))
	vbox.add_child(_make_button("Sair para o Título", _quit_to_title))

func _make_dim_overlay() -> Control:
	var overlay := Control.new()
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.03, 0.62)
	dim.anchor_right = 1.0
	dim.anchor_bottom = 1.0
	overlay.add_child(dim)
	overlay.visible = false
	_layer.add_child(overlay)
	return overlay

func _make_panel(width: float, height: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -width * 0.5
	panel.offset_right = width * 0.5
	panel.offset_top = -height * 0.5
	panel.offset_bottom = height * 0.5
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.085, 0.1, 0.97)
	style.border_color = Color(0.72, 0.58, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	var m := 22.0
	style.content_margin_left = m
	style.content_margin_right = m
	style.content_margin_top = m
	style.content_margin_bottom = m
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_button(text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = tr(text)
	btn.custom_minimum_size = Vector2(0, 36)
	btn.add_theme_font_size_override("font_size", 15)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.16, 0.15, 0.17, 1.0)
	normal.border_color = Color(0.35, 0.32, 0.3)
	normal.border_width_left = 1
	normal.border_width_right = 1
	normal.border_width_top = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 7
	normal.corner_radius_top_right = 7
	normal.corner_radius_bottom_left = 7
	normal.corner_radius_bottom_right = 7
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.24, 0.22, 0.2, 1.0)
	hover.border_color = Color(0.82, 0.66, 0.3)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.3, 0.27, 0.22, 1.0)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	# Narração por botão (v1.0): lê o texto ao focar/passar o rato, se ativada.
	btn.focus_entered.connect(func(): GameState.tts_say(btn.text))
	btn.mouse_entered.connect(func(): GameState.tts_say(btn.text))
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.pressed.connect(func(): Audio.play("click"); callback.call())
	return btn

func _open_pause() -> void:
	if _difficulty_btn != null:
		_difficulty_btn.text = tr(_difficulty_text())
	pause_open = true
	_pause_overlay.visible = true
	_refresh_pause_buttons()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_pause() -> void:
	pause_open = false
	_pause_overlay.visible = false
	get_tree().paused = false
	if in_game:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _refresh_pause_buttons() -> void:
	var in_vale := get_tree().current_scene != null and get_tree().current_scene.name == "Main"
	var system_btn := _pause_overlay.find_child("SystemButton", true, false) as Button
	if system_btn:
		system_btn.visible = GameState.artifact_unlocked
		system_btn.disabled = not in_vale
		if GameState.artifact_unlocked and not in_vale:
			system_btn.text = tr("Sistema (disponível no Vale)")
		else:
			system_btn.text = tr("Entrar no Sistema (Sala Branca)")
	var decision_btn := _pause_overlay.find_child("DecisionButton", true, false) as Button
	if decision_btn:
		decision_btn.visible = GameState.main_stage >= 6
	var load_btn := _pause_overlay.find_child("LoadButton", true, false) as Button
	if load_btn:
		load_btn.disabled = not in_vale or not GameState.has_save()

func _save_game() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		notify("Sem jogador no mundo.")
		return
	if get_tree().current_scene == null or get_tree().current_scene.name != "Main":
		notify("Só podes guardar no Vale.")
		return
	GameState.save_game(player.global_position, float(player.get("hp")), float(player.get("stamina")))

func _load_game() -> void:
	if get_tree().current_scene == null or get_tree().current_scene.name != "Main":
		notify("Só podes carregar no Vale.")
		return
	if GameState.load_game():
		_close_pause()
		get_tree().reload_current_scene()

func _enter_system() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	GameState.system_return = player.global_position
	_close_pause()
	get_tree().change_scene_to_file("res://scenes/sala_branca.tscn")

func _quit_to_title() -> void:
	_close_all_overlays()
	set_in_game(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/title.tscn")

func _close_all_overlays() -> void:
	pause_open = false
	attributes_open = false
	controls_open = false
	decision_open = false
	ending_open = false
	map_open = false
	factions_open = false
	for overlay in [_pause_overlay, _attributes_overlay, _controls_overlay, _decision_overlay, _ending_overlay, _map_overlay, _factions_overlay]:
		if overlay:
			overlay.visible = false

# ------------------------------------------------------------------ mapa ----
const TRAVEL_DESTS := [
	{"id": "noro", "name": "Vale de Noro", "desc": "Casa. O poço, a forja e a estrada.", "level_req": 1, "scene": "res://scenes/main.tscn"},
	{"id": "academia", "name": "Academia Real de Veyra", "desc": "A prova de admissão reabriu as portas.", "level_req": 1, "scene": "res://scenes/academia.tscn"},
]
var _map_overlay: Control
var _map_rows: VBoxContainer
var _factions_overlay: Control
var _factions_rows: VBoxContainer

func _make_travel_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = tr(text)
	btn.custom_minimum_size = Vector2(110, 34)
	btn.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.19, 0.1, 0.95)
	normal.border_color = Color(0.85, 0.72, 0.4, 0.9)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", normal)
	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(0.13, 0.13, 0.14, 0.9)
	disabled_style.border_color = Color(0.4, 0.4, 0.42, 0.8)
	btn.add_theme_stylebox_override("disabled", disabled_style)
	btn.add_theme_color_override("font_color", Color(0.95, 0.87, 0.6))
	btn.add_theme_color_override("font_disabled_color", Color(0.55, 0.55, 0.57))
	btn.focus_entered.connect(func(): GameState.tts_say(btn.text))
	btn.mouse_entered.connect(func(): GameState.tts_say(btn.text))
	return btn

func _build_map() -> void:
	_map_overlay = _make_dim_overlay()
	var panel := _make_panel(700, 620)
	_map_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := _make_label("MAPA DE ARKANO", 24, Color(0.97, 0.82, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := _make_label("Onde queres que a estrada te leve, Kael?", 13, Color(0.72, 0.7, 0.66))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	_map_rows = VBoxContainer.new()
	_map_rows.add_theme_constant_override("separation", 6)
	_map_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_map_rows)
	vbox.add_child(_make_button("Fechar", func(): _toggle_map(false)))

func _all_destinations() -> Array:
	var dests: Array = TRAVEL_DESTS.duplicate()
	for r in GameState.REGIONS:
		var d: Dictionary = (r as Dictionary).duplicate()
		d["scene"] = "res://scenes/region.tscn"
		dests.append(d)
	return dests

func _refresh_map() -> void:
	for child in _map_rows.get_children():
		child.queue_free()
	for dest in _all_destinations():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var left := VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var id := String(dest["id"])
		var req := int(dest["level_req"])
		var name_label := _make_label(String(dest["name"]), 15, Color(0.95, 0.87, 0.6))
		left.add_child(name_label)
		var desc_label := _make_label(String(dest.get("desc", "")), 11, Color(0.68, 0.66, 0.62))
		left.add_child(desc_label)
		var status := "—"
		if id != "noro" and id != "academia":
			var clears := GameState.region_clear_count(id)
			var known := bool(GameState.region_known.get(id, false))
			if clears > 0:
				status = "Explorada ×%d" % clears
			elif known:
				status = "Descoberta, não concluída"
			else:
				status = "Desconhecida"
		status += "  ·  Nv %d+" % req
		var status_label := _make_label(status, 11, Color(0.47, 0.75, 0.78))
		left.add_child(status_label)
		row.add_child(left)
		var unlocked := GameState.level >= req
		var travel_btn := _make_travel_button("Viajar" if unlocked else "🔒 Nv %d" % req)
		travel_btn.disabled = not unlocked
		travel_btn.pressed.connect(_travel_to.bind(dest))
		row.add_child(travel_btn)
		_map_rows.add_child(row)

func _travel_to(dest: Dictionary) -> void:
	var id := String(dest["id"])
	if id != "noro" and id != "academia":
		if not GameState.region_unlocked(id):
			GameState.notify(tr("Ainda não estás à altura (Nv %d).") % int(dest["level_req"]))
			return
		GameState.current_region = id
		if not GameState.region_known.get(id, false):
			GameState.region_known[id] = true
			GameState.notify(tr("Região descoberta: %s") % String(dest["name"]))
		GameState.stats_changed.emit()
	_toggle_map(false)
	pause_open = false
	if _pause_overlay:
		_pause_overlay.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(String(dest["scene"]))

func _toggle_map(open_it: bool) -> void:
	map_open = open_it
	if _map_overlay == null:
		return
	_map_overlay.visible = open_it
	if open_it:
		_refresh_map()
		_pause_overlay.visible = false
	elif pause_open:
		_pause_overlay.visible = true

# --------------------------------------------------------------- fações -----
const FACTION_ORDER := ["imperial", "academia", "ordem", "arquivistas", "irmandade"]

func _build_factions() -> void:
	_factions_overlay = _make_dim_overlay()
	var panel := _make_panel(620, 560)
	_factions_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := _make_label("FACÇÕES DE ARKANO", 24, Color(0.97, 0.82, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var sub := _make_label("A tua reputação abre e fecha portas — e finais.", 13, Color(0.72, 0.7, 0.66))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)
	_factions_rows = VBoxContainer.new()
	_factions_rows.add_theme_constant_override("separation", 10)
	_factions_rows.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_factions_rows)
	vbox.add_child(_make_button("Fechar", func(): _toggle_factions(false)))

func _refresh_factions() -> void:
	for child in _factions_rows.get_children():
		child.queue_free()
	for faction in FACTION_ORDER:
		var rep := int(GameState.reputation.get(faction, 0))
		var rank := GameState.reputation_rank(faction)
		var block := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.11, 0.105, 0.12, 0.9)
		style.set_corner_radius_all(8)
		style.set_border_width_all(1)
		style.border_color = Color(0.4, 0.37, 0.32, 0.7)
		style.content_margin_left = 12.0
		style.content_margin_right = 12.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		block.add_theme_stylebox_override("panel", style)
		var row_vbox := VBoxContainer.new()
		row_vbox.add_theme_constant_override("separation", 3)
		block.add_child(row_vbox)
		var top := HBoxContainer.new()
		var name_label := _make_label(String(GameState.REPUTATION_NAMES.get(faction, faction)), 14, Color(0.95, 0.9, 0.78))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		var rank_color := Color(0.7, 0.7, 0.72)
		if rep >= 20: rank_color = Color(0.62, 0.88, 0.62)
		elif rep < -30: rank_color = Color(0.92, 0.55, 0.45)
		var rank_label := _make_label("%s  (%+d)" % [rank, rep], 12, rank_color)
		top.add_child(rank_label)
		row_vbox.add_child(top)
		var bar := _make_bar(520, 8, Color(0.78, 0.68, 0.35))
		bar.min_value = -100.0
		bar.max_value = 100.0
		bar.value = float(rep)
		row_vbox.add_child(bar)
		_factions_rows.add_child(block)

func _toggle_factions(open_it: bool) -> void:
	factions_open = open_it
	if _factions_overlay == null:
		return
	_factions_overlay.visible = open_it
	if open_it:
		_refresh_factions()
		_pause_overlay.visible = false
	elif pause_open:
		_pause_overlay.visible = true

# ------------------------------------------------------------ atributos ------
var _attr_points_label: Label
var _attr_state_label: Label
var _attr_value_labels: Dictionary = {}

func _build_attributes() -> void:
	_attributes_overlay = _make_dim_overlay()
	var panel := _make_panel(640, 600)
	_attributes_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	_attr_points_label = _make_label("Atributos — 0 pontos", 20, Color(0.97, 0.9, 0.65))
	_attr_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_attr_points_label)
	_attr_state_label = _make_label("Saudável · Fadiga 0/3", 12, Color(0.75, 0.8, 0.85))
	_attr_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_attr_state_label)
	for key in GameState.ATTR_KEYS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var name_label := _make_label(String(GameState.ATTR_NAMES[key]), 15, Color(0.93, 0.92, 0.88))
		name_label.custom_minimum_size = Vector2(118, 0)
		row.add_child(name_label)
		var hint := _make_label(String(GameState.ATTR_HINTS[key]), 10, Color(0.55, 0.56, 0.52))
		hint.custom_minimum_size = Vector2(220, 0)
		hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(hint)
		var value_label := _make_label("1", 16, Color(0.9, 0.8, 0.45))
		value_label.custom_minimum_size = Vector2(34, 0)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(value_label)
		_attr_value_labels[key] = value_label
		var add_btn := Button.new()
		add_btn.text = tr("+")
		add_btn.custom_minimum_size = Vector2(36, 28)
		add_btn.pressed.connect(func(): _add_attribute(key))
		row.add_child(add_btn)
		vbox.add_child(row)
	var note := _make_label("O teu maior talento é sobreviver. Mas talento sem treino é só sobrevivência.", 11, Color(0.5, 0.5, 0.47))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(note)
	vbox.add_child(_make_button("Voltar", func(): _toggle_attributes(false)))

func _add_attribute(key: String) -> void:
	if GameState.spend_attribute(key):
		_refresh_attribute_panel()
	else:
		notify("Sem pontos de atributo. Níveis e o Sistema dão pontos.")

func _toggle_attributes(open_it: bool) -> void:
	attributes_open = open_it
	_attributes_overlay.visible = open_it
	if open_it:
		_pause_overlay.visible = false
		_refresh_attribute_panel()
	elif pause_open:
		_pause_overlay.visible = true

func _refresh_attribute_panel() -> void:
	_attr_points_label.text = tr("Atributos — %d ponto(s) disponível(eis)") % GameState.attribute_points
	var estado: String = ["Saudável", "Magoado", "Grave"][clampi(GameState.injury, 0, 2)]
	_attr_state_label.text = tr("Estado: %s (lesão %d/%d) · Fadiga %d/%d") % [estado, GameState.injury, GameState.MAX_INJURY, GameState.fatigue, GameState.MAX_FATIGUE]
	for key in GameState.ATTR_KEYS:
		(_attr_value_labels[key] as Label).text = str(int(GameState.attributes[key]))

# ------------------------------------------------------------ controlos -----
func _build_controls() -> void:
	_controls_overlay = _make_dim_overlay()
	var panel := _make_panel(660, 620)
	_controls_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)
	var title := _make_label("CONTROLOS", 22, Color(0.97, 0.9, 0.65))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	_rebind_hint = _make_label("", 12, Color(0.95, 0.75, 0.35))
	_rebind_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rebind_hint.visible = false
	vbox.add_child(_rebind_hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 4)
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var header := _make_label("— Clica num botão e primes a nova tecla/botão —", 13, Color(0.7, 0.68, 0.6))
	rows.add_child(header)
	_rebind_rows.clear()
	for def in Keymap.ACTIONS:
		var action := String(def["action"])
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl := _make_label(String(Keymap.ACTION_NAMES.get(action, action)), 13, Color(0.9, 0.89, 0.85))
		name_lbl.custom_minimum_size = Vector2(230, 0)
		row.add_child(name_lbl)
		var summary := _make_button(Keymap.binding_summary(action), _start_rebind.bind(action))
		summary.custom_minimum_size = Vector2(0, 32)
		summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		summary.add_theme_font_size_override("font_size", 12)
		row.add_child(summary)
		_rebind_rows[action] = summary
		rows.add_child(row)
	rows.add_child(_make_button("Repor predefinições", _reset_bindings))
	var lore := _make_label("«A ausência de magia é a arma mais antiga do mundo.»", 12, Color(0.6, 0.58, 0.5))
	lore.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(lore)
	vbox.add_child(_make_button("Voltar", func(): _toggle_controls(false)))

func _toggle_controls(open_it: bool) -> void:
	controls_open = open_it
	_controls_overlay.visible = open_it
	if open_it:
		_pause_overlay.visible = false
	elif pause_open:
		_pause_overlay.visible = true

# ------------------------------------------------------------- decisão ------
var _ending_title: Label
var _ending_portrait: TextureRect
var _ending_text: Label
var _credits_label: Label

func _build_decision() -> void:
	_decision_overlay = _make_dim_overlay()
	var panel := _make_panel(700, 648)
	_decision_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := _make_label("A DECISÃO", 30, Color(0.97, 0.82, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	var story_row := HBoxContainer.new()
	story_row.add_theme_constant_override("separation", 14)
	vbox.add_child(story_row)
	var kael_art := TextureRect.new()
	kael_art.custom_minimum_size = Vector2(146, 196)
	kael_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	kael_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portraits_script = preload("res://src/ui/portraits.gd")
	var kael_tex: Texture2D = portraits_script.texture_for("kael", "battle")
	kael_art.texture = kael_tex
	story_row.add_child(kael_art)
	var story_col := VBoxContainer.new()
	story_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_row.add_child(story_col)
	var story := _make_label("O Guardião da Prova jaz aos teus pés. Os portões de Veyra estão abertos — e todas as portas do mundo também.\nA tua reputação entre as fações abre caminhos que o menu não mostra. O que fazes agora com a força que construíste?", 13, Color(0.85, 0.84, 0.8))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_col.add_child(story)
	for key in ["academia", "vagabundo", "revolta", "estandarte", "arquivo", "vacuo"]:
		var ending: Dictionary = ENDINGS[key]
		var btn := _make_button(String(ending["choice"]) + "\n" + String(ending["desc"]), _choose_ending.bind(key))
		btn.custom_minimum_size = Vector2(0, 58)
		btn.add_theme_font_size_override("font_size", 12)
		if ending.has("req"):
			var req: Dictionary = ending["req"]
			var faction := String(req["faction"])
			var amount := int(req["amount"])
			var rep := int(GameState.reputation.get(faction, 0))
			if rep < amount:
				var fname := String(GameState.REPUTATION_NAMES.get(faction, faction))
				btn.text = "🔒 " + String(ending["choice"]) + tr("\nRequer: %s %d  (tens %d)") % [fname, amount, rep]
				btn.disabled = true
		if key == "academia" and GameState.world_flag("golpe", "hidden") == "silent":
			btn.text = "🔒 " + String(ending["choice"]) + tr("\nA Academia caiu: calaste-te quando a Custódia marchou.")
			btn.disabled = true
		vbox.add_child(btn)

func _open_decision() -> void:
	decision_open = true
	_pause_overlay.visible = false
	_decision_overlay.visible = true

func _choose_ending(key: String) -> void:
	GameState.ending = key
	GameState.main_stage = 7
	GameState.register_ending(key)
	# Autosave na decisão: sem isto o final nunca era gravado (os saves são
	# manuais no menu de pausa) e "finais anteriores" fica letra morta.
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		GameState.save_game(player.global_position, float(player.get("hp")), float(player.get("stamina")))
	decision_open = false
	_decision_overlay.visible = false
	ending_open = true
	var ending: Dictionary = ENDINGS[key]
	var ending_text := String(ending["text"])
	var rid := GameState.romance_id
	if rid != "" and ROMANCE_EPILOGUES.has(rid):
		var epilogue := String(ROMANCE_EPILOGUES[rid])
		if ROMANCE_EPILOGUES_WARM.has(rid) and GameState.companion_loyalty(rid) >= 60:
			epilogue = String(ROMANCE_EPILOGUES_WARM[rid])
		ending_text += "\n\n— «Incluindo, claro», pensa Kael.\n" + epilogue
	var portraits_script2 = preload("res://src/ui/portraits.gd")
	var art_tex: Texture2D = portraits_script2.texture_for(String(rid)) if rid != "" else null
	if art_tex == null:
		art_tex = portraits_script2.texture_for("kael", "determined")
	_ending_portrait.texture = art_tex
	_ending_title.text = tr(String(ending["title"]))
	_ending_text.text = tr(ending_text)
	_credits_label.text = tr(_build_credits_text())
	_ending_overlay.visible = true

func _build_ending() -> void:
	_ending_overlay = _make_dim_overlay()
	var panel := _make_panel(700, 620)
	_ending_overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	_ending_portrait = TextureRect.new()
	_ending_portrait.custom_minimum_size = Vector2(140, 124)
	_ending_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ending_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_ending_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(_ending_portrait)
	_ending_title = _make_label("", 26, Color(0.97, 0.82, 0.3))
	_ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_ending_title)
	_ending_text = _make_label("", 15, Color(0.9, 0.89, 0.85))
	_ending_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ending_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_ending_text)
	_credits_label = _make_label("", 12, Color(0.58, 0.58, 0.55))
	_credits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_credits_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_credits_label)
	vbox.add_child(_make_button("Voltar ao Título", func(): _quit_to_title()))

func _build_credits_text() -> String:
	GameState.objective_changed.emit("")
	var lines := [
		tr("A ACADEMIA DO ZERO — vertical slice"),
		tr("Kael Noro, o rapaz sem Núcleo"),
		tr("Vladimir, o Guardião da Prova"),
		tr("Elen Noro · Garr · Tomás · Liora Venn · Mestre Dario Vale"),
		"",
		tr("O mundo de Arkanor continua. Tu também."),
		tr("Obrigado por jogar."),
		"",
		tr("Nv %d · %d marcos · %d XP totais") % [GameState.level, GameState.marcos, GameState.xp],
		tr("Finais vividos: %d") % GameState.endings_seen.size(),
	]
	var ferida: String = String(GameState.world_flag("ferida", "hidden"))
	match ferida:
		"resolved_closed":
			lines.append(tr("A Ferida — selada com o engenho dos Engenheiros."))
		"resolved_fed":
			lines.append(tr("A Ferida — adormecida a Núcleo, por enquanto."))
		"resolved_truth":
			lines.append(tr("A Ferida — a verdade, finalmente crúne."))
	var golpe: String = String(GameState.world_flag("golpe", "hidden"))
	match golpe:
		"foiled_report":
			lines.append(tr("O Golpe da Custódia — denunciado; Veyra guarda as leis."))
		"silent":
			lines.append(tr("O Golpe da Custódia — calaste-te; a Academia que resta é outra."))
	return "\n".join(lines)
