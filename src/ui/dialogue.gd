extends Node
## Motor de diálogo: árvores simples name/text/next/choices/action.
## Pausa o mundo enquanto a caixa está visível (árvore em processo ALWAYS).

signal dialogue_finished(action: String)

const TREES := {
	"elen": {
		"name": "Elen Noro",
		"text": "Kael... o vento muda outra vez. Hoje olhei para a estrada e pensei em ti, parado à porta da Academia Real.",
		"next": "elen_2",
	},
	"elen_2": {
		"name": "Elen Noro",
		"text": "O teu pai passava os dias entre ruínas à procura de respostas sobre os Primeiros Engenheiros. Nunca esqueceste isso, não foi?",
		"next": "elen_3",
	},
	"elen_3": {
		"name": "Elen Noro",
		"text": "Ouvi dizer que as provas de admissão da Academia reabriram esta estação. Tu queres mesmo ir?",
		"choices": [
			{"text": "«Quero. Quero saber por que nasci sem Núcleo.»", "next": "elen_4", "action": "elen_talked"},
			{"text": "«Ainda não tenho a certeza.»", "next": "elen_5", "action": "elen_talked"},
		],
	},
	"elen_4": {
		"name": "Elen Noro",
		"text": "Então ouve. As Fibras de Ruína — aqueles cristais âmbar que brilham na floresta — curam o que a magia não cura a tempo. Traz cinco para as lâmpadas do santuário.",
		"choices": [
			{"text": "«Contamos com elas.» (Aceitar missão: Luz para as Lâmpadas)", "action": "herb_accept"},
		],
	},
	"elen_5": {
		"name": "Elen Noro",
		"text": "A dúvida também é coragem, filho. A floresta está cheia de lobos e ruínas antigas — vai com cuidado. E se vires Fibras de Ruína, traz cinco. O santuário precisa.",
		"choices": [
			{"text": "«Trago as Fibras.» (Aceitar missão: Luz para as Lâmpadas)", "action": "herb_accept"},
		],
	},
	"elen_idle": {
		"name": "Elen Noro",
		"text": "Come qualquer coisa antes de sair. Ninguém luta bem de estômago vazio — nem com magia, nem sem ela.",
	},
	"garr": {
		"name": "Garr, o Ferreiro",
		"text": "Ora bolas, o filho da Elen! Boas notícias: a tua Corrente de Âncora está pronta. Aço de Primeiro Engenheiro — puxa inimigos, destrói posturas e interrompe feitiços a meio.",
		"next": "garr_2",
	},
	"garr_2": {
		"name": "Garr, o Ferreiro",
		"text": "Com isto, talvez sobrevivas a um mago de verdade. Se ainda os quiseres enfrentar, claro.",
		"choices": [
			{"text": "«Quero a Corrente.» (Obter a Corrente de Âncora)", "action": "garr_chain", "next": "garr_3"},
		],
	},
	"garr_3": {
		"name": "Garr, o Ferreiro",
		"text": "Sente o peso dela. Agora escuta: três lobos de cinza têm atacado a Estrada Imperial. Há um preço sobre as peles. Se quiseres uns marcos extra...",
		"choices": [
			{"text": "«Eu trato dos lobos.» (Aceitar missão: Lobos da Estrada)", "action": "wolf_accept"},
			{"text": "«Já tenho que fazer.»", "action": ""},
		],
	},
	"garr_idle": {
		"name": "Garr, o Ferreiro",
		"text": "O aço não mente, rapaz. As pessoas... mentem bastante.",
	},
	"aldeao": {
		"name": "Tomás, o Aldeão",
		"text": "Dizem que na capital as fontes correm sozinhas e os portais levam qualquer um a qualquer sítio num piscar de olhos. Aqui temos poço e pés, como deve ser.",
		"next": "aldeao_2",
	},
	"aldeao_2": {
		"name": "Tomás, o Aldeão",
		"text": "Ainda bem que nasceste com braços fortes, rapaz. Neste mundo, ou vales um Núcleo... ou vales dois braços. Tu vales os dois braços.",
	},
	"liora": {
		"name": "Liora Venn",
		"text": "Um Vazio à porta da Academia Real? Os porteiros acordaram com humor perverso hoje.",
		"next": "liora_2",
	},
	"liora_2": {
		"name": "Liora Venn",
		"text": "Agora a sério. Passaste a floresta sozinho? Com lobos na estrada e um salteador morto de pé, segundo me disseram.",
		"next": "liora_3",
	},
	"liora_3": {
		"name": "Liora Venn",
		"text": "Eu sou Liora Venn. Faculdade do Véu — aprendo a ser invisível e a fazer os outros verem quando não devem. (ri) O Mestre Dario espera na arena. Convence-o. E, já agora, convence-me a mim também.",
		"action": "liora_met",
	},
	"liora_after": {
		"name": "Liora Venn",
		"text": "Não sei o que estás a esconder, Noro. Aquela coisa dentro de ti... ontem à noite, na arena, senti-a como uma onda sem mar. Quando decidires contar, eu ouço. Não prometo não ter ciúmes — ou medo.",
	},
	"dario_early": {
		"name": "Mestre Dario Vale",
		"text": "Não recebo candidatos antes de falarem com quem está no portão. É tradição. É irritante. Mas é tradição.",
	},
	"dario": {
		"name": "Mestre Dario Vale",
		"text": "Kael Noro. O teu nome chegou antes de ti: um rapaz sem Núcleo pede prova de admissão. Isto acontece uma vez a cada geração — geralmente uma vez a menos.",
		"next": "dario_2",
	},
	"dario_2": {
		"name": "Mestre Dario Vale",
		"text": "A prova é simples de explicar e difícil de fazer. Um Guardião, forjado pelos Primeiros Engenheiros, testa quem chega à arena. Derruba-o — e a Academia terá de te considerar.",
		"choices": [
			{"text": "«Estou pronto.» (Iniciar a Prova do Portão)", "action": "accept_trial"},
			{"text": "«Preciso de mais treino.»", "action": ""},
		],
	},
	"dario_mid": {
		"name": "Mestre Dario Vale",
		"text": "O Guardião espera dentro da arena. Ele não cansa. Tu podes. Vai com calma.",
	},
	"dario_done": {
		"name": "Mestre Dario Vale",
		"text": "O Guardião era uma prova — e tu vieste como resposta. Descansa, Vazio. E não confies em nada que pisque um olho num canto da tua mente.",
	},
}

var active := false
var _layer: CanvasLayer
var _panel: PanelContainer
var _name_label: Label
var _text_label: Label
var _choices_box: VBoxContainer
var _hint_label: Label
var _current_node := {}
var _collected_actions: Array[String] = []
var _typing := false
var _char_count := 0.0

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 25
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.07
	_panel.anchor_right = 0.93
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_top = -215.0
	_panel.offset_bottom = -22.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.09, 0.94)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.78, 0.62, 0.25, 0.9)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	_panel.add_theme_stylebox_override("panel", style)
	_panel.visible = false
	_layer.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", Color(0.87, 0.7, 0.3))
	_name_label.add_theme_font_size_override("font_size", 17)
	vbox.add_child(_name_label)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0, 58)
	_text_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_text_label)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_choices_box)

	_hint_label = Label.new()
	_hint_label.text = "E / Espaço — continuar ▸"
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_hint_label)

func start(tree_id: String) -> void:
	if not TREES.has(tree_id):
		push_warning("Diálogo desconhecido: %s" % tree_id)
		return
	active = true
	_collected_actions.clear()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_panel.visible = true
	_show_node(tree_id)

func _show_node(node_id: String) -> void:
	var node: Dictionary = TREES.get(node_id, {})
	if node.is_empty():
		_finish()
		return
	_current_node = node
	_name_label.text = String(node.get("name", "???"))
	_text_label.text = String(node.get("text", ""))
	_text_label.visible_characters = 0
	_char_count = 0.0
	_typing = true
	# Limpar escolhas anteriores
	for child in _choices_box.get_children():
		child.queue_free()
	var choices: Array = node.get("choices", [])
	for choice in choices:
		var btn := Button.new()
		btn.text = String(choice.get("text", "..."))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 14)
		var next_id := String(choice.get("next", ""))
		var action := String(choice.get("action", ""))
		btn.pressed.connect(func(): _on_choice(next_id, action))
		btn.focus_mode = Control.FOCUS_NONE
		_choices_box.add_child(btn)
	_hint_label.visible = choices.is_empty()

func _process(delta: float) -> void:
	if not active or not _typing:
		return
	_char_count += delta * 55.0
	var total := _text_label.text.length()
	_text_label.visible_characters = mini(int(_char_count), total)
	if _char_count >= float(total):
		_typing = false

func _input(event: InputEvent) -> void:
	if not active:
		return
	var advance := false
	if event is InputEventKey and event.pressed and not event.echo:
		var k := event.keycode
		if k == KEY_E or k == KEY_SPACE or k == KEY_ENTER:
			advance = true
	if not advance:
		return
	if _typing:
		_text_label.visible_characters = -1
		_typing = false
		get_viewport().set_input_as_handled()
		return
	# Só avança com botão de continuar se não houver escolhas
	if not _choices_box.get_children().is_empty():
		return
	var action := String(_current_node.get("action", ""))
	var next_id := String(_current_node.get("next", ""))
	_on_choice(next_id, action)
	get_viewport().set_input_as_handled()

func _on_choice(next_id: String, action: String) -> void:
	if action != "":
		_collected_actions.append(action)
	if next_id != "":
		_show_node(next_id)
	else:
		_finish()

func _finish() -> void:
	active = false
	_panel.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for action in _collected_actions:
		dialogue_finished.emit(action)
