# A Academia do Zero

[![CI — Godot headless smoke](https://github.com/monteirokelvin45-del/The-Giselle-project/actions/workflows/headless-smoke.yml/badge.svg)](https://github.com/monteirokelvin45-del/The-Giselle-project/actions/workflows/headless-smoke.yml)

<img src="assets/art/key_art.jpg" alt="Kael Noro acima da vila de Noro, com a Academia Real ao fundo" width="560">

**RPG de ação em terceira pessoa, de mundo aberto, sobre um rapaz sem magia num mundo que adora magia.**
Um Vazio que vale mais pelos dois braços do que os magos valem pelos Núcleos.

> Estado: **v1.14 — mundo auditado** («Auditoria integral»), branch `arena/498f65a7-the-giselle-project` — [o que mudou na v1.9→v1.14](#o-que-mudou-na-v19-v114-2026-11-09).

---

## Sobre o jogo

Num mundo onde governos, exércitos, escolas, hospitais e transportes dependem
da magia, nasceu **Kael Noro** — sem Núcleo Arcano, sem feitiços, sem valor
aos olhos da sociedade. Criado na aldeia de **Noro**, treinou o corpo até se
tornar algo que o mundo mágico diz não existir: alguém que enfrenta magos
de igual para igual, à força de músculo, técnica e uma Corrente de Âncora.

O documento de design completo (mundo de Arkanor, as seis disciplinas mágicas,
as faculdades, os finais e tudo o resto) está em [`docs/GDD.md`](docs/GDD.md).
O caminho até à v1.0 está em [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Como correr

1. Instala o **Godot Engine 4.2 ou superior** (gratuito, de [godotengine.org](https://godotengine.org) — a versão padrão, *não* a Mono/.NET).
2. Abre o Godot → **Importar/Scan** → seleciona a pasta do repositório (ou o ficheiro `project.godot`).
3. Carrega **F5** (ou `godot --path .` no terminal).
4. O jogo abre no ecrã de título. Em nova campanha: **Novo Jogo**.

Não é preciso instalar dependências — os modelos 3D (CC0, KayKit) estão incluídos
no repositório em `assets/models/`, e os efeitos sonoros são sintetizados em
`assets/audio/`. A key art do título foi gerada por IA (`assets/art/key_art.jpg`) e os retratos
do elenco também (`assets/art/portraits/`).
Detalhes e licenças: [`docs/ASSETS.md`](docs/ASSETS.md).

## Jogar no Android (novo)

O jogo agora também corre em Android (telemóveis de gama alta — escolha do dono do projeto):

1. Instala o **Godot Engine 4.2+** e no **Editor → Preferências → Exportar → Android** configura
   o `JAVA_HOME` e o caminho do Android SDK (o editor gera a keystore de debug sozinho).
2. Abre o projeto → **Projeto → Exportar… → Android** — o preset já está pronto em
   `export_presets.cfg` (package `com.thegiselleproject.academiazero`, minSdk 24, arm64-v8a,
   sem permissão de Internet — o jogo é offline). Confirma os ícones gerados em
   `assets/art/icons/` e ajusta se o Godot reclamar.
3. **Exportar projeto** → instala o `.apk` com `adb install app.apk` ou por ficheiro.
4. **Nunca commites keystore nem passwords** — o preset vem sem assinatura de release.

**Como se joga no ecrã de toque** (definido com o dono do projeto):

| Zona | Ação |
|---|---|
| Metade esquerda (tocar e arrastar) | Joystick virtual — mover |
| Metade direita (arrastar) | Câmara |
| LEVE / FORTE | Ataque leve (combo) / pesado |
| ESQV | Esquiva |
| BLOQ (segurar) | Bloquear / parry no instante certo |
| E | Interagir / Corrente de Âncora |
| POT | Beber poção |
| RUPT | Estado de Ruptura |
| ALVO | Fixar alvo |
| II | Pausa |

Os botões táteis só aparecem em cenas de jogo (Main/Sala Branca), fora de diálogos/menus, e
emitem as **mesmas ações de input** do teclado — a lógica do jogo é idêntica nas duas plataformas.
Para testar o esquema no PC, põe `const FORCE_TOUCH := true` em `src/mobile/touch_controls.gd`.

## Controlos

| Tecla | Ação |
|---|---|
| W/A/S/D ou Setas | Mover |
| Rato | Câmara (clicar no jogo para focar o rato) |
| Botão esquerdo | Ataque leve (combo de 3) |
| Botão direito | Ataque pesado |
| Espaço | Esquiva (curta invulnerabilidade) |
| Shift | Correr |
| Q (segurar) | Bloquear |
| Q (no instante certo) | **Parry perfeito** (quebra postura, enche Ruptura) |
| E | Interagir / **Corrente de Âncora** (puxa e interrompe feitiços) |
| R | Beber poção (+45 vida) |
| F | **Estado de Ruptura** (quando a barra está cheia) |
| Tab | Fixar / largar alvo |
| Esc | Menu de pausa (salvar/carregar, atributos, Sistema, a Decisão, **Dificuldade**) |
| Gamepad | A analógico — mover · R analógico — câmara · X ataque · Y pesado · A esquiva · B interagir · LB bloquear · RB Ruptura · L3 correr · R3 alvo · D-Pad↓ poção · Start pausa |

## O que está pronto na v1.0 (2026-11-07)

- **Look cel/toon nativo** (`DIFFUSE_TOON` + `SPECULAR_TOON` + rim) em todos os
  modelos; toggle no menu de Pausa; detalhes e o porquê em `docs/VISUALS.md`.
  Inspirado por Genshin Impact (técnica, nunca conteúdo) — atribuição completa em
  `docs/INSPIRATION.md`.
- **Duas meta-quests globais com estado de mundo persistido** (`world_flags`):
  «A Ferida» (Arquivista Voss — selar/alimentar/revelar; consequências de
  reputação e recompensa) e «O Golpe da Custódia» (Bram Ferro — denunciar vs.
  silenciar; silenciar **bloqueia o fim «O Reformado»** na Decisão). Ver `docs/GDD.md` cap. 38–39.
- **Romances com memória**: epílogos variam com a lealdade (prova superada
  juntos ⇒ versão «provada»). Ver `docs/GDD.md` cap. 40.
- **i18n completo**: 460/460 chaves PT/EN/ES com `l10n_build.py --check` no CI.
- **Todos os mapas em composição v1.0**: composição única por bioma (dupla copa
  para a floresta de Ruun) e POIs originais — acampamento abandonado, templos,
  torre, obeliscos, farol, doca, ilhas flutuantes, altar do Abismo.
  Ver `docs/WORLD.md` e cap. 41 do GDD.
- **Ambiente vivo** (v1.1): vento automático em toda a vegetação, bandos de
  pássaros, partículas por bioma (folhas/brasas/vaga-lumes/neve/motes),
  feixe rotativo no farol de Lume e ilhas flutuantes leves — cap. 42 GDD.
- **QA humano**: checklist obrigatória em `docs/PLAYTEST.md` (F5, GPU, Android,
  QA nativo) — nada disso pode ser substituído por CI.

## O que mudou na v1.9→v1.14 (2026-11-09)

- **v1.9 «Disciplinas Vivas»** — elementos de verdade no mundo (Cinética e Lúmina
  com fontes; Ruptura AoE, Ferida, glow; dados em `balance/elements.json`), HUD.
- **v1.10 «O mundo respira»** — a aldeia de Noro e o campus ganham vozes: +6 aldeões
  no Vale (Berta, Renzo, Otávio, Lia, Betinha, Silas) +2 no campus (Nina, Ennio);
  **escalas dos edifícios KayKit medidas e corrigidas** (accessor min/max dos GLTF —
  «casas a 0.5 m» acabaram); bigorna procedural no lugar do ícone em falta;
  acampamento abandonado na floresta.
- **v1.11 «O eco das regiões»** — uma voz solitária por região de expedição:
  Hex (Ruun), Zafira (Sahr), Dane (Khar), Cafu (Lume), Urik (Aer), Mira (Orun/Abismo) —
  a alma de cada lugar, sem quests inventadas.
- **v1.12/v1.13 «Multidão» / «Multidão plena»** — figurantes KayKit determinísticos
  (sem interação, sem colliders, zero raycasts extra): **73** no Vale + 6 vozes = **79**;
  **117** no campus + 8 vozes = **125** — os números pedidos pelo dono.
- **v1.14 «Auditoria integral»** — 1 perf-bug corrigido (lookup de player por figurante
  por frame → cache de 1 Hz); AUDIT §32 (git/CI/gates/assets/censo numérico:
  `NPC_MODELS` 25 · `ROOTED_IDS` 16 · `TREES` 65 · CSV 518); ~2 MB de assets órfãos
  (ex.: `icon_1024.png`, texturas KayKit soltas) **à espera da palavra do dono** —
  nada apagado.
- **Fora do jogo, de caso pensado:** interiores de casas/camargo, Veyra, Camada 2
  (Kael imbuído), `enemy_discipline` — pendentes da palavra do dono do projeto.

Histórico completo das rondas e dos limites honestos de cada uma:
[`docs/AUDIT.md`](docs/AUDIT.md) (§28–§32) e [`docs/GDD.md`](docs/GDD.md) (cap. 50–53).

## O que mudou na v0.2

- **Android**: controlos táteis completos (joystick dinâmico + câmara por arrasto + botões de
  ação que reutilizam o mesmo pipeline de input), orientação landscape, stretch `canvas_items`,
  texturas ETC2/ASTC, ícones e `export_presets.cfg` prontos. Ver [Jogar no Android](#jogar-no-android-novo).

Evolução de qualidade sobre a v0.1 (o conteúdo de jogo é o mesmo; o mundo e o combate ganharam vida):

- **Personagens por modelos 3D esqueléticos** (KayKit Adventures, CC0): Kael (Rogue Hooded tingido
  carvão, a condizer com a referência de personagem em `assets/art/kael_reference.jpg`),
  inimigos humanoides (Salteador = Barbarian tintada, Mago de Cinza = Mage tintada,
  Guardião = Barbarian gigante em pedra) e os 5 NPCs — cada um com **Idle/Walking/Running**,
  **ataques**, **hit**, **block**, **dodge** e **morte** animados.
- **Mundo com modelos KayKit Medieval Hexagon** (CC0): casas, taverna, capela, forja, mercado,
  poço, castelos academias, torres e muralha do portão, árvores, rochas, montanhas e props
  (barris, caixas, sacos, escadas, tendas, bandeiras, alvos de treino...). Estruturas de colisão de jogo
  são independentes dos modelos.
- **Lobo esquelético** (Quaternius, CC0): Idle/Walk/Attack/Death/HitReact — o inimigo
  da Floresta deixou de ser "caixas com orelhas".
- **Vegetação baixa** (gobkit, CC0): relva, arbustos e escarpas junto à estrada, floresta, vila
  e portão — o chão deixou de ser um plano verde vazio.
- **Canal de conjuração do Mago de Cinza**: feitiço é telegrafado (Spellcast_Raise → disparo)
  e pode ser **interrompido pela Corrente de Âncora** — a mecânica anti-magia passou a ter uma
  janela real de contra-jogo.
- **Game feel**: screen shake (impacto, parry, dano sofrido), partículas de impacto,
  números de dano flutuantes e *hit-flash* branco nos modelos.
- **Gamepad completo** e **dificuldade** Casual/Normal/Pesadelo (+50% XP) persistida no save.
- **IA cooperante**: o Salteador protege o Mago de Cinza (guarda-costas) ou flanqueia pelo lado
  oposto (dois Salteadores), e o Mago recua mais longe quando tem guarda — a emboscada já não é
  três inimigos a correr na mesma linha reta.
- **Hit-stop**: ~90–130 ms de pausa dramática em cada acerto (impacto a sério).
- **Auditoria alargada** (`docs/AUDIT.md`): findings técnicos, conselho de especialistas com
  votação e o roadmap de riscos abertos.
- **Correções**: identificadores não declarados nos fallbacks procedurais (quebrariam a
  compilação do script de inimigos), reset de estado de morte (Kael volta a pôr-se de pé após
  renascer), validação cruzada de todos os caminhos de modelos contra o disco, tipagem estrita
  do Godot 4 (`instantiate()` devolve `Node`).

## O que está pronto na v0.1

Implementação do escopo do "Capítulo 35 — Escopo Realista" do documento de design:

- **Mundo aberto pequeno mas vivo**: Vila de Noro (praça, forja, poço, mercado),
  a Estrada Imperial pela **Floresta Baixa**, o **Portão da Academia** com
  Liora Venn e o **Mestre Dario Vale**, e a **arena** do Guardião da Prova.
- **Combate físico completo**: ataques leves/pesados com combo, esquiva com
  i-frames, bloqueio, **parry**, barra de **postura** nos inimigos, ataques
  aéreos... (quase — ver [limitações](#limitações-conhecidas)), e a
  **Corrente de Âncora** como ferramenta anti-magia.
- **Estado de Ruptura**: meter de tensão que carrega com parries, golpes e
  dano — ativa fúria temporária com F.
- **8 atributos** com progressão por XP e pontos para gastar
  (Força, Velocidade, Reflexos, Resistência, Fôlego, Técnica, Perceção, Adaptação).
- **4 inimigos originais**: Lobo de Cinza, Salteador de Ruína, Mago de Cinza
  (projéteis arcanos) e o chefe **Guardião da Prova** (golpe de área
  telegrafado).
- **Missão principal** completa (falar com a mãe → ferreiro → floresta →
  Liora → prova → Guardião → **decisão final com 3 finais possíveis**),
  **2 missões secundárias** (Lobos da Estrada, Luz para as Lâmpadas).
- **O Sistema (Sala Branca)**: a dimensão secreta de treino, com boneco de
  treino, legendas misteriosas e **avaliação de desempenho** (golpes,
  precisão, dano sofrido) que recompensa com pontos de atributo (máx. 5).
- **Save/load** em JSON (menu de pausa), morte estilo Dark Souls leve
  (perde 10% dos marcos, acorda na vila).
- Menus completos: título com key art, pausa, atributos, controlos,
  HUD com objetivo rastreado, notificações, fixar-alvo com barra de postura.
- **Acessibilidade**: legendas de diálogo, alto contraste nos elementos,
  barras de vida/fôlego/postura/ruptura separadas, texto ajustável pela janela.

## Limitações conhecidas

- **O código foi validado estruturalmente** (syntax via `gdparse`, referências
  `res://`, `.tscn`/`project.godot`), mas **não foi executado numa máquina com a
  engine dentro deste ambiente** — alguns bugs visuais/de jogabilidade são
  esperados na primeira execução. Reporta problemas (abre uma issue) e corrige-se.
- Arte 3D agora com **modelos KayKit (CC0)**, estilizados e low-poly — coerente e
  consistente, mas ainda "de pack"; falta: direção de arte própria, VFX elaborados,
  sombras/iluminação mais ricas e afinação fina de escala/posicionamento em execução
  (os colisores são invisíveis, por isso o jogo funciona mesmo se um modelo estiver
  um pouco desalinhado).
- Modelos assumem **+Z como frente** e escala estimada por olho; se algo aparecer
  virado ao contrário ou desproporcional, os ajustes estão em
  `src/visuals/model_factory.gd` (`MODEL_FACING_OFFSET`) e na escala por modelo
  em `world_builder.gd`.
- O áudio são **bleeps sintetizados** (placeholder honesto, fica melhor com uma
  verdadeira sessão de sound design).
- Mundo **fixo em um vale**: sem streaming, sem mudança de época/dia, sem
  persistência de NPCs, sem respawn de inimigos fora do Vale.
- Sem conjuradores a cooperar taticamente, sem montarias, sem economia
  completa — tudo isso está no GDD e no roadmap. (As relações e os romances
  chegaram na v1.0: epílogos por companheiro com lealdade.)
- Death during boss resets you at the arena entrance with the guardian's
  current HP (sem reset total).

## Estrutura do repositório

```
project.godot            # configuração do projeto Godot 4
scenes/                  # cenas (.tscn): título, principal, jogador, inimigos...
src/
  core/                  # estado global, input map, orquestração da cena
  player/                # Kael: movimento, combate, câmara
  enemies/               # IA e tipos de inimigos + projéteis
  world/                 # construção do Vale de Noro (modelos + primitivos)
  interaction/           # NPCs e Fibras de Ruína
  system/                # a Sala Branca (Sistema) e bonecos de treino
  ui/                    # título, HUD, pausa, atributos, diálogos, decisão
  visuals/               # fábrica de modelos/animações + efeitos (shake, bursts)
assets/models/           # modelos CC0: characters/ env/ (KayKit), creatures/ (Quaternius), nature/ (gobkit) — ver docs/ASSETS.md
assets/art/              # key art (título) + referência de personagem (kael_reference.jpg)
assets/audio/            # SFX sintetizados (tools/synth_audio.py)
tools/                   # validate.py, headless_check.sh, smoke_*.tscn, perf_probe.tscn
docs/                    # GDD.md, ROADMAP.md, ASSETS.md, licenses/, INSPIRATION.md, VISUALS.md, PLAYTEST.md
```

## Ferramentas de qualidade

```bash
# dependências de dev (gdparse/gdtoolkit — o resto é só a engine):
pip3 install -r requirements-dev.txt
python3 tools/validate.py                        # estrutura: gdparse, caminhos res://, .tscn

# regenerar SFX (WAV 16-bit, 22050 Hz):
python3 tools/synth_audio.py

# validar dentro da engine (Godot 4.7.2 — ver docs/BUILD.md; ferramentas de
# ambiente persistente em tools/setup_env.sh + tools/godot.sh):
tools/headless_check.sh /caminho/para/godot      # import + boot das 5 cenas (falha em SCRIPT ERROR)
godot --headless --path . res://tools/smoke_test.tscn   # 24 asserções de jogabilidade
godot --headless --path . res://tools/smoke_flows.tscn  # 5 asserções de fluxo (Sala Branca → Academia)
godot --headless --path . res://tools/perf_probe.tscn   # sonda de performance CPU-side
```

**CI**: cada push/PR corre o [workflow headless smoke](.github/workflows/headless-smoke.yml) no
GitHub Actions — validate.py, import de recursos, boot das 5 cenas (o gate
**falha em erros de script**), 24 asserções de jogabilidade e os 5 fluxos
Sala Branca/Academia, com o binário oficial do Godot 4.7.2-stable.

## Licença e autoria

O mundo, a história e os personagens pertencem ao projeto. Documento de
design original em `docs/GDD.md`.

Modelos 3D: **KayKit** (Kay Lousberg), licença **CC0** — ver
[`docs/ASSETS.md`](docs/ASSETS.md) e `docs/licenses/`.
Feito com Godot Engine (MIT).
