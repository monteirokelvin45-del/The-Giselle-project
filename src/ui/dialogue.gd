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
		"choices": [
			{"text": "«Ver a oficina.» (Compras)", "next": "garr_shop"},
			{"text": "«Preciso descansar um dia.» (Trata lesões e recupera tudo)", "action": "rest_durr"},
			{"text": "«Só vim dizer nada.»", "action": "none"},
		],
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

	"bram_pre": {
		"name": "Bram Ferro",
		"text": "Um sem-magia na Academia Real de Veyra. Que a forja mais cheia de faíscas faça sentido de ti, forasteiro. Eu sou Bram Ferro — quarto-mestre da Forja. Se quiseres ver o que vales, tens a Prova de Duelo: de frente para mim, sem magia, sem desculpas.",
		"choices": [
			{"text": "«Aceito a Prova de Duelo.» (Exame: 1v1 contra Bram)", "action": "exam_duelo", "next": "bram_pre_ok"},
			{"text": "«Ainda não estou pronto.»", "action": "none"},
		],
	},
	"bram_pre_ok": {
		"name": "Bram Ferro",
		"text": "Bem dito. Arena do lado nascente, quando quiseres. Não vou à tua procura — a prova é tua para começar.",
	},
	"bram_done": {
		"name": "Bram Ferro",
		"text": "O aço não mente, forasteiro. Viste o meu cansaço e não hesitaste. É por isso que eu e a corrente temos respeito por ti. Precisas de alguma coisa da forja?",
	},
	"bram_golpe": {
		"name": "Bram Ferro",
		"text": "Fica aqui, junto à forja, onde só ouvimos os martelos. Aquela ronda nova da Custódia não desfila — apronta. O Marechal Cadena escolheu a semana da Prova Final para «limpar» a Academia: numa só noite, os sem-magia — caloiros, tu, eu — e os mestres que os deixaram entrar. Desta data a Custódia ouve quem souber cedo.",
		"choices": [
			{"text": "«Conto aos Mestres hoje. Com datas e testemunhas.» (Imperial +15 · Academia +10)", "action": "golpe_report", "next": "bram_golpe_foil"},
			{"text": "«Não é comigo. A minha cabeça no ninho não salva ninhos.» (Academia −25 · O fim «O Reformado» fica bloqueado)", "action": "golpe_silent", "next": "bram_golpe_silent"},
			{"text": "«Ainda não decidi. Preciso de tempo.»", "action": "none"},
		],
	},
	"bram_golpe_foil": {
		"name": "Bram Ferro",
		"text": "Boa. Boa! Os Mestres sabem às quatro; às seis, Cadena dorme numa cela de pedra e Veyra faz jurar a Custódia de novo. Devias sentir alívio... só me sinto cansado. Mas dorme descansado hoje, forasteiro.",
	},
	"bram_golpe_silent": {
		"name": "Bram Ferro",
		"text": "Eu... antes preferia não saber. Mas se guardares silêncio, guarda pelo menos com os olhos abertos: naquela noite vais saber exactamente de que é feita a Academia que se salva — e a que se deixa queimar.",
	},
	"bram_romance": {
		"name": "Bram Ferro",
		"text": "Olha... não sou bom com palavras bonitas. Mas desde que me devolveste a espada, não consigo deixar de pensar onde acabas os teus dias. Algo mais do que camaradagem, entre nós dois?",
		"choices": [
			{"text": "«Sim. Há algo mais.» (Iniciar romance com Bram)", "action": "romance_bram", "next": "romance_ok"},
			{"text": "«Só camaradagem, Bram. Lamento.»", "action": "none", "next": "romance_no"},
		],
	},
	"sena_pre": {
		"name": "Sena Raiz",
		"text": "Bem-vindo aos Jardins de Ruun, onde o verde fala mais alto que os Núcleos. Eu sou Sena, dos Raízes. A Prova da Floresta não é de força: é de leitura — seguir rastros, escolher o momento, não derrubar o que não precisa de ser derrubado.",
		"choices": [
			{"text": "«Aceito a Prova da Floresta.» (Exame: caçar lobos e o salteador)", "action": "exam_floresta", "next": "sena_pre_ok"},
			{"text": "«Preciso de ar. Volto já.»", "action": "none"},
		],
	},
	"sena_pre_ok": {
		"name": "Sena Raiz",
		"text": "Pois bem. Vai ao clareira do sul quando estiveres pronto. E lembra-te: no verde, quem tem pressa vira ceia dos lobos.",
	},
	"sena_done": {
		"name": "Sena Raiz",
		"text": "As raízes crescem para onde há água — e os bons guardiões crescem para onde há confiança. Obrigada por ouvires o jardim antes de o cortar.",
	},
	"sena_romance": {
		"name": "Sena Raiz",
		"text": "Sabes? As ervas que curaste, o lobo que poupou? Eu acompanhei cada gesto. Disseram-me que o coração dos Raízes só se explica falando... Queres que eu diga?",
		"choices": [
			{"text": "«Diz. E ouve também.» (Iniciar romance com Sena)", "action": "romance_sena", "next": "romance_ok"},
			{"text": "«Agora não. Só companhia de viagem.»", "action": "none", "next": "romance_no"},
		],
	},
	"iven_pre": {
		"name": "Iven Lago",
		"text": "Shh. Não faças barulho na torre — os Horizontes não gostam de anunciar chegadas. Eu sou Iven. A Prova do Labirinto Arcano mede o que nenhum mapa mede: coragem de um homem sem bússola. Quatro conjuradores cinzentos escondem-se no labirinto. Encontra-os — ou deixa-te encontrar.",
		"choices": [
			{"text": "«Aceito o Labirinto Arcano.» (Exame: 4 conjuradores)", "action": "exam_labirinto", "next": "iven_pre_ok"},
			{"text": "«Prefiro estudar o labirinto primeiro.»", "action": "none"},
		],
	},
	"iven_pre_ok": {
		"name": "Iven Lago",
		"text": "Boa escolha — ou boa fuga, só o tempo dirá. A entrada está a leste. Os corredores mentem; os teus pés, não. Confia neles.",
	},
	"iven_done": {
		"name": "Iven Lago",
		"text": "Aos sem-magia costuma-se mentir: «não há lugar para ti». Eu menti muitas vezes. Desta dei meia-volta quando te vi completar o labirinto. Obrigado — por me forçares a ser honesto uma vez.",
	},
	"iven_romance": {
		"name": "Iven Lago",
		"text": "Navios inteiros naufragaram por algo que eu só consigo descrever numa carta de navegação. Mas posso dizer-te o seguinte, e só uma vez: eu quero ser o porto onde cais, Kael. O que dizes?",
		"choices": [
			{"text": "«Quero ser esse porto.» (Iniciar romance com Iven)", "action": "romance_iven", "next": "romance_ok"},
			{"text": "«É uma metáfora bonita. Só isso, por agora.»", "action": "none", "next": "romance_no"},
		],
	},
	"liora_academia_pre": {
		"name": "Liora Venn",
		"text": "Bem-vindo a Veyra, Kael Noro. A Academia Real não se abre com Núcleos — abre com escolhas. Eu sou Liora, da Véu. A Prova de Equipas mede o que decides quando o grupo tropeça: Salvamentos, cobertura, decisões a quente. Cinco salteadores à tua espera na arena.",
		"choices": [
			{"text": "«Aceito a Prova de Equipas.» (Exame: 5 salteadores em equipa)", "action": "exam_equipas", "next": "liora_academia_pre_ok"},
			{"text": "«Preciso de ver a arena primeiro.»", "action": "none"},
		],
	},
	"liora_academia_pre_ok": {
		"name": "Liora Venn",
		"text": "A arena fica nascente. Leva a tua Corrente — mas leva também a cabeça. Cinco contra um só se ganha se um deles não souber que és só um.",
	},
	"liora_academia_done": {
		"name": "Liora Venn",
		"text": "Escolheste proteger antes de atacar. Foi o que eu fiz — e é o que farei por ti. A Véu guarda os seus segredos, mas contigo, Kael, eu escolhi partilhar um.",
	},
	"liora_academia_romance": {
		"name": "Liora Venn",
		"text": "Dizem que a Véu não ama — estuda. Eu estudei-te durante toda a Prova, e cada relatório dizia a mesma coisa. Queres saber o que diz o último?",
		"choices": [
			{"text": "«Diz.» (Iniciar romance com Liora)", "action": "romance_liora", "next": "romance_ok"},
			{"text": "«Guarda o teu relatório, Liora.»", "action": "none", "next": "romance_no"},
		],
	},
	"romance_ok": {
		"name": "Sistema",
		"text": "Algo mudou. O ar à volta de Kael sente-se diferente — como um fio a mais sendo tecido num tecido antigo. O Sistema observa. O Sistema regista.",
	},
	"romance_no": {
		"name": "Sistema",
		"text": "Respeito. Há coisas que se devem ganhar devagar, e há quem prefira o silêncio a um coração mal lido. O Sistema não julga. O Sistema apenas regista.",
	},
	"dario_academia": {
		"name": "Mestre Dario Vale",
		"text": "Bem-vindo à Academia, Kael. Aqui ensinamos os que nasceram sem Núcleo a fazer dos dois braços vergões que a magia nunca terá. Treino sério custa 120 marcos a sessão — ou contas, ou suor. O que preferes?",
		"choices": [
			{"text": "«Treino físico — 120 marcos.» (+1 ponto de atributo)", "action": "train_attr"},
			{"text": "«Conta-me sobre a Guarda do Arquivo.»", "action": "none", "next": "dario_academia_lore"},
			{"text": "«Volto depois.»", "action": "none"},
		],
	},
	"dario_academia_lore": {
		"name": "Mestre Dario Vale",
		"text": "O Arquivo Proibido fica abaixo da torre poente. A Academia fingiu durante cem anos que era ficção proibida. Os Arquivistas, esses, sabem que não é. Se um dia alguém te disser que o Vazio pode destruir Núcleos por dentro — não duvides dele. Nem procures prova. Algumas verdades queimam quem as segura.",
	},
	"voss": {
		"name": "Arquivista Voss",
		"text": "Psiu. Aqui fala-se baixo porque as paredes não guardam segredos — repetem-nos. Eu sou Voss, dos Arquivistas do Proibido. Se um dia te convidarem a descer abaixo da torre, lembra-te: a verdade não se pede, descobre-se. E quem a descobre nunca mais dorme tranquilo.",
		"choices": [
			{"text": "«Quero saber mais.» (Conhecer os Arquivistas)", "action": "voss_meet"},
			{"text": "«Prefiro ficar por cima.»", "action": "none"},
		],
	},
	"voss_after": {
		"name": "Arquivista Voss",
		"text": "Ainda aqui? Bom. Os que ficam são os que veem. Quando a Academia cair — e vai cair —, sê o que a segura. Ou o que a deixa cair. A escolha será tua, como sempre foi.",
	},
	"voss_ferida": {
		"name": "Arquivista Voss",
		"text": "Perguntaste. Bom. Khar treme há três semanas, e os últimos três epicentros formam um triângulo perfeito. Lá em cima, por cima de Orun, a fechadura dos Engenheiros está a ceder. O Núcleo daquela montanha está a vazar — e a Ferida sangra para cima, pelo céu.",
		"choices": [
			{"text": "«Os arquivos têm a planta da fechadura. Sela-se isto.» (Arquivistas +15 · Imperial +10)", "action": "ferida_closed", "next": "voss_ferida_closed"},
			{"text": "«Núcleo para quem dorme. Alimenta-se — e cala-se.» (Irmandade +20 · Imperial −15)", "action": "ferida_fed", "next": "voss_ferida_fed"},
			{"text": "«O mundo tem de saber. Publica tudo.» (Arquivistas +25 · Imperial −20)", "action": "ferida_truth", "next": "voss_ferida_truth"},
			{"text": "«Ainda não sei. Volto quando souber.»", "action": "none"},
		],
	},
	"voss_ferida_closed": {
		"name": "Arquivista Voss",
		"text": "Planta no cofre poente, ferraria a norte, uma visita à cumeeia... e uma lua calada. Está feito — e eu carrego o fardo. Que Veyra durma descansada sem sequer saber o que se evitou.",
	},
	"voss_ferida_fed": {
		"name": "Arquivista Voss",
		"text": "Ai... a Irmandade aprovaria. Um Núcleo de visita largado na boca da Ferida — e o silêncio a seguir. Celebra-se cedo demais: o que se alimenta nunca morre — apenas aprende a esperar.",
	},
	"voss_ferida_truth": {
		"name": "Arquivista Voss",
		"text": "Os pergaminhos saíram antes do amanhecer. Amanhã Veyra acorda sem o sono da ignorância — e com a ira na garganta. Espero que tenhamos feito a coisa certa, rapaz sem magia.",
	},
	"garr_shop": {
		"name": "Garr, o Ferreiro",
		"text": "Ora bem, freguês! O que lhe falta hoje? Tenho poções, pregos de ruptura e umas quantas coisas para quem não tem magia e ainda assim se recusa a morrer.",
		"choices": [
			{"text": "Poção — 30 marcos", "action": "shop_potion"},
			{"text": "Prego de Ruptura — 45 marcos (+25 Ruptura)", "action": "shop_prego"},
			{"text": "Bálsamo de Salvação — 60 marcos (vida completa + trata lesões)", "action": "shop_balsamo"},
			{"text": "Remendo do curandeiro — 45 marcos (−1 nível de lesão)", "action": "shop_remendo"},
			{"text": "Elixir do Sistema — 120 marcos (+50 Ruptura)", "action": "shop_elixir"},
			{"text": "Forjar poção — 2 Fibras de Ruína + 10 marcos", "action": "craft_potion"},
			{"text": "Forjar Bálsamo — 3 Fibras de Ruína + 20 marcos", "action": "craft_balsamo"},
			{"text": "Temperar a lâmina — 150 marcos (+12% dano, permanente)", "action": "craft_temper"},
			{"text": "«Agora não, Garr.»", "action": "none"},
		],
	},
	"berta": {
		"name": "Berta, a Padeira",
		"text": "Pão quente, Kael? A Academia come-te vivo — os rapazes voltam de lá pálidos, mas contentes.",
	},
	"renzo": {
		"name": "Renzo, guarda do portão",
		"text": "O portão só abre para ti ou para mestres selados. Fila para os outros — mesmo para os de família antiga.",
	},
	"otavio": {
		"name": "Otávio, o velho do poço",
		"text": "Vi este Vale ser só capim e poeira. Já fartei de contar impérios... deste poço, nunca.",
	},
	"lia": {
		"name": "Lia, aprendiz do Garr",
		"text": "Garr diz que sou quente demais para a bigorna. Quando ferrares por mim, queixas-te ao velho.",
	},
	"betinha": {
		"name": "Betinha, a rapariga da praça",
		"text": "És tu o tal Vazio? O Tomás diz que tens medo de ti. Eu acho giríssimo um sem nome.",
	},
	"silas": {
		"name": "Silas, o caravaneiro",
		"text": "Trouxe sal de Khar e vinho amargo até ao vosso ferreiro. Diz-lhe que a corda aguenta — o salitre é que cansa.",
	},
	"nina": {
		"name": "Nina, a estudante",
		"text": "Entre nós: os mestres debatem como curar a cabeça de um Vazio. Eu voto estudo sem tocar em nada... com mel à mesa.",
	},
	"ennio": {
		"name": "Ennio, o arrogante",
		"text": "Dizem que vais ganhar a prova e ser favorito do conselho. Também dizem que a Veyra engole torres. Acredita se quiseres.",
	},
}

var active := false
var _layer: CanvasLayer
var _panel: PanelContainer
var _subtitle_scale: float = 1.0
var _name_label: Label
var _text_label: Label
var _portrait: TextureRect
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
	_panel.offset_top = -232.0
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

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	vbox.add_child(row)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(118, 148)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.visible = false
	row.add_child(_portrait)
	var text_col := VBoxContainer.new()
	text_col.add_theme_constant_override("separation", 6)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text_col)
	_name_label = Label.new()
	_name_label.add_theme_color_override("font_color", Color(0.87, 0.7, 0.3))
	_name_label.add_theme_font_size_override("font_size", 17)
	text_col.add_child(_name_label)

	_text_label = Label.new()
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0, 58)
	_text_label.add_theme_font_size_override("font_size", 16)
	text_col.add_child(_text_label)

	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 4)
	vbox.add_child(_choices_box)

	_hint_label = Label.new()
	_hint_label.text = tr("E / Espaço — continuar ▸")
	_hint_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_hint_label.add_theme_font_size_override("font_size", 12)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_hint_label)

func set_subtitle_scale(scale: float) -> void:
	_subtitle_scale = clampf(scale, 0.8, 1.6)
	if _name_label != null:
		_name_label.add_theme_font_size_override("font_size", int(17 * _subtitle_scale))
	if _text_label != null:
		_text_label.add_theme_font_size_override("font_size", int(16 * _subtitle_scale))
	if _hint_label != null:
		_hint_label.add_theme_font_size_override("font_size", int(12 * _subtitle_scale))

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
	var speaker := String(node.get("name", "???"))
	_name_label.text = tr(speaker)
	var portraits_script = preload("res://src/ui/portraits.gd")
	var tex: Texture2D = portraits_script.texture_for(speaker)
	_portrait.visible = tex != null
	_portrait.texture = tex
	_text_label.text = tr(String(node.get("text", "")))
	_text_label.visible_characters = 0
	_char_count = 0.0
	_typing = true
	# Limpar escolhas anteriores
	for child in _choices_box.get_children():
		child.queue_free()
	var choices: Array = node.get("choices", [])
	for choice in choices:
		var btn := Button.new()
		btn.text = tr(String(choice.get("text", "...")))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", int(14 * _subtitle_scale))
		var next_id := String(choice.get("next", ""))
		var action := String(choice.get("action", ""))
		btn.pressed.connect(func(): _on_choice(next_id, action))
		btn.mouse_entered.connect(func(): GameState.tts_say(btn.text))
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
		var k: int = event.keycode
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
