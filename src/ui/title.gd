extends Control
## Ecrã de título: arte principal + menu.

func _ready() -> void:
	UI.set_in_game(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build()

func _build() -> void:
	# Arte de fundo
	var art := TextureRect.new()
	var tex: Texture2D = load("res://assets/art/key_art.jpg")
	art.texture = tex
	art.anchor_right = 1.0
	art.anchor_bottom = 1.0
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(art)
	# Escurecer ligeiramente para legibilidade
	var shade := ColorRect.new()
	shade.color = Color(0.03, 0.03, 0.05, 0.38)
	shade.anchor_right = 1.0
	shade.anchor_bottom = 1.0
	add_child(shade)
	# Gradiente inferior (fade extra atrás do texto)
	var bottom := ColorRect.new()
	bottom.color = Color(0.02, 0.02, 0.03, 0.0)
	bottom.anchor_top = 0.55
	bottom.anchor_right = 1.0
	bottom.anchor_bottom = 1.0
	add_child(bottom)

	# Coluna de texto à esquerda
	var margin := MarginContainer.new()
	margin.anchor_bottom = 1.0
	margin.offset_left = 56.0
	margin.offset_right = 660.0
	margin.offset_top = 0.0
	margin.offset_bottom = 0.0
	margin.add_theme_constant_override("margin_left", 0)
	margin.add_theme_constant_override("margin_top", 0)
	add_child(margin)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var kicker := Label.new()
	kicker.text = tr("UM MUNDO COM MAGIA. UM RAPAZ SEM ELA.")
	kicker.add_theme_font_size_override("font_size", 13)
	kicker.add_theme_color_override("font_color", Color(0.88, 0.74, 0.32))
	kicker.add_theme_constant_override("outline_size", 4)
	kicker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	col.add_child(kicker)

	var title := Label.new()
	title.text = tr("A ACADEMIA\nDO ZERO")
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color(0.97, 0.95, 0.88))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.04, 0.95))
	col.add_child(title)

	var subtitle := Label.new()
	subtitle.text = tr("Kael Noro, o rapaz sem Núcleo, e o mundo que esqueceu os sem-magia.")
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.83, 0.78))
	subtitle.add_theme_constant_override("outline_size", 5)
	subtitle.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	col.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 18)
	col.add_child(spacer)

	var continue_btn := _menu_button("CONTINUAR", 22)
	continue_btn.disabled = not GameState.has_save()
	continue_btn.pressed.connect(_on_continue)
	col.add_child(continue_btn)

	var new_btn := _menu_button("NOVO JOGO", 22)
	new_btn.pressed.connect(_on_new_game)
	col.add_child(new_btn)

	var quit_btn := _menu_button("SAIR", 16)
	quit_btn.pressed.connect(_on_quit)
	col.add_child(quit_btn)

	# Botão de idioma (canto inferior direito) — alterna PT → EN → ES
	var lang_btn := Button.new()
	lang_btn.text = String(GameState.ENDONYMS.get(GameState.locale, GameState.locale)) + "  ⟳"
	lang_btn.custom_minimum_size = Vector2(150, 36)
	lang_btn.anchor_left = 1.0
	lang_btn.anchor_right = 1.0
	lang_btn.anchor_top = 1.0
	lang_btn.anchor_bottom = 1.0
	lang_btn.offset_left = -170.0
	lang_btn.offset_right = -20.0
	lang_btn.offset_top = -46.0
	lang_btn.offset_bottom = -10.0
	lang_btn.focus_mode = Control.FOCUS_NONE
	lang_btn.pressed.connect(_on_cycle_language)
	add_child(lang_btn)

	# Versão em baixo
	var version := Label.new()
	version.text = tr("Vertical Slice v0.1 · Arkanor, o Vale de Noro · Feito em Godot 4")
	version.add_theme_font_size_override("font_size", 11)
	version.add_theme_color_override("font_color", Color(0.62, 0.6, 0.55, 0.9))
	version.anchor_top = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = 20.0
	version.offset_top = -30.0
	version.offset_bottom = -10.0
	add_child(version)

func _menu_button(text: String, size: int) -> Button:
	var btn := Button.new()
	btn.text = tr(text)
	btn.focus_entered.connect(func(): GameState.tts_say(btn.text))
	btn.mouse_entered.connect(func(): GameState.tts_say(btn.text))
	btn.custom_minimum_size = Vector2(300, 52 if size > 16 else 44)
	btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.add_theme_font_size_override("font_size", size)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.1, 0.09, 0.78)
	normal.border_color = Color(0.72, 0.58, 0.25, 0.85)
	normal.border_width_left = 2
	normal.border_width_right = 2
	normal.border_width_top = 2
	normal.border_width_bottom = 2
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.26, 0.21, 0.14, 0.9)
	hover.border_color = Color(0.95, 0.78, 0.35)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.35, 0.28, 0.16, 0.95)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	disabled.border_color = Color(0.3, 0.3, 0.3, 0.6)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled)
	return btn

func _on_continue() -> void:
	Audio.play("click")
	if GameState.load_game():
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_new_game() -> void:
	Audio.play("click")
	GameState.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_cycle_language() -> void:
	Audio.play("click")
	GameState.cycle_locale()
	get_tree().reload_current_scene()

func _on_quit() -> void:
	Audio.play("click")
	get_tree().quit()
