# Auditoria de projeto e Conselho de Especialistas — v0.2 (2026-11-06)

Método: (1) auditoria técnica real ao repositório (leitura de todos os `src/`,
validação de todos os assets no disco, `gdparse`, varredura própria de
identificadores não declarados); (2) exercício de conselho — 16 personas
up-votando 8 propostas; (3) implementação imediata dos vencedores.

> **Honestidade sobre o "conselho"**: as personas são um método de priorização
> estruturada, não pessoas reais; os votos são heurísticos para ordenar
> trabalho, não decisões de ninguém. A auditoria técnica, essa, é real.

## 1. Auditoria técnica — findings

| # | Severidade | Finding | Estado |
|---|---|---|---|
| A1 | 🔴 crítico | `enemy.gd` não compilava: `mace_stick`/`staff` eram identificadores nunca declarados (fallback procedural) | ✅ Corrigido (5de0233) |
| A2 | 🔴 crítico | `PackedScene.instantiate()`/`get_first_node_in_group()` tipados como `Node` → "Cannot find member" em cascata na 1ª abertura Godot 4 | ✅ Corrigido (5de0233, varredura completa) |
| A3 | 🔴 crítico | Morte do jogador nunca repunha o estado de animação (Kael ficava caído para sempre após renascer) | ✅ Corrigido (23a8af2) |
| A4 | 🟡 alto | Nenhum sistema de dificuldade (pedido de acessibilidade explícito do dono desde a v0.1) | ✅ **Implementado agora** |
| A5 | 🟡 alto | Zero suporte a gamepad (um RPG TPS sem comandos de consola era meio-pronto para o género) | ✅ **Implementado agora** |
| A6 | 🟡 alto | IA de inimigos sem coordenação (contradiz restrição original do dono: conjurador+tanque, flanco) | ✅ **Implementado agora** |
| A7 | 🟡 médio | Impacto de combate sem "hit-stop" (sensação de soco) | ✅ **Implementado agora** |
| A8 | 🟡 médio | Save sem versionamento/migração (`"version": 1` sem uso) | ⚠️ Aceitável no slice; documentado |
| A9 | 🟡 médio | Engine **nunca executada** neste ambiente (binário indisponível nos hosts permitidos): escalas de modelos, eixo `+Z` assumido, AnimationPlayer via `find_child`, performance em GL Compatibility | ⚠️ Risco residual — o primeiro F5 no editor é o teste real |
| A10 | 🟢 baixo | `set_master_volume_db` existia mas não era exposto em nenhum menu (ficava morto) | ✅ Agora acessível via pausa (volume mestre via slider está em aberto — ver §5) |
| A11 | 🟢 baixo | Documentação/créditos/licenças inconsistentes (assets fora do controlo de versão, KayKit sem texto de licença no repo) | ✅ ASSETS.md, REFERENCES.md, CHARACTER.md, licenses/ |
| A12 | 🟢 baixo | 17 scripts GDScript com estilo gdlint hostil (111 avisos) | ⏭️ Mantido como dívida de estilo, sem impacto funcional |

Verificações mecânicas: `python3 tools/validate.py` → **OK** (gdparse 17 scripts,
`res://`, `.tscn`, `project.godot`); todos os 85+ modelos referenciados existem
no disco (0 refs quebradas, atlas e `.bin` conferidos); 40/40 glTF/GLB parseados.

## 2. O Conselho — 16 personas, 8 propostas, votação

Presentes: Diretor de Jogos AAA (30a), Diretor Criativo de RPG (29a), Produtor
Executivo (28a), Designer de RPG (27a), Designer de Mundo Aberto (26a), Designer
de Missões (25a), Designer de Combate (30a), Designer de Sistemas (20a),
Programador Godot (28a), Diretor de Arte (30a), Programador de Câmera TPS (30a),
Diretor de QA (30a), Especialista em Acessibilidade (13a), Especialista em IA de
Inimigos (9a), Designer de Recompensas (17a), Designer de Diálogos (15a).
Cada persona: 3 pontos nas propostas que mais importam.

| Prop | Proposta | AAA | Criat | Prod | RPG | MOpen | Miss | Cbt | Sis | Gdt | Arte | TPS | QA | Acess | IA | Recomp | Diál | Total |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P1 | **Gamepad completo** (analógico mover/câmara, X/Y/A/B/LB/RB/L3/R3/Start/D-Pad↓) | ● | ● | ● | | ● | | ● | ● | ● | | ● | ● | ● | | | ● | **11** |
| P2 | **Dificuldade** Casual/Normal/Pesadelo + persistência no save | ● | | ● | ● | | ● | | ● | ● | ● | | ● | ● | ● | ● | ● | **12** |
| P3 | **IA cooperante**: Salteador protege Mago (guarda-costas); dois Salteadores flanqueiam por lados opostos; Mago recua mais longe com guarda | ● | ● | | ● | ● | | ● | | | | ● | | | ● | | | **7** |
| P4 | **Hit-stop** (~90–130 ms a time_scale 0.2) nos acertos | | | ● | | ● | ● | ● | | ● | ● | ● | ● | | ● | ● | | **10** |
| P5 | Kael à medida (Blender ou VRoid→VRM) | | ● | | | | | | | | ● | | | | | | | **2** |
| P6 | Música dinâmica (exploração/perigo/combate) | | | | | | | | | | | | | | | | | **0** |
| P7 | Mapa + viagem rápida | | | | | | | | | | | | | | | | | **0** |
| P8 | Balanceamento data-driven (dano/parry/XP por ficheiro) | | | | ● | | ● | | ● | | | | | ● | | ● | ● | **6** |

### Decisões
- **A1 — Implementado nesta iteração** (vencedores): P1, P2, P3, P4.
- **A2 — Adiados, com dono e condição**: P8 (após playtest real no editor — agora seria ajustar às cegas); P5 (quando o dono validar escala/facing no F5, ou entregar `.vrm` do VRoid para `v-sekai/godot-vrm`); P6 (v0.3, quando houver trilha licenciada/composta — música não é CC0-trivial); P7 (v0.5 per ROADMAP).
- **A3 — Rejeitados nesta fase**: P6/P7 por custo/risco agora (não rejeitados para sempre).

## 3. Implementado nesta iteração

> **Addendum (mesmo dia) — Android confirmado pelo dono do projeto**: alvo
> "gama alta", Android apenas (iOS pendente de Mac/Xcode). Controlos táteis
> standard (joystick dinâmico + câmara por arrasto + botões de ação via
> `InputEventAction` — a lógica do jogo não mudou), `window/handheld/orientation=landscape`,
> stretch `canvas_items`/`expand`, ETC2/ASTC, ícones, `export_presets.cfg`.
> Novo autoload `Touch` (camada 30), visível só em Main/SalaBranca e com menus
> fechados. Ver "Jogar no Android" no README.

1. **Gamepad completo** (`input_setup.gd`, `player.gd`): movimento analógico
   (L3/eixos com deadzone 0.2), câmara por stick direito (yaw/pitch com deadzone),
   todos os botões mapeados (X ataque leve, Y pesado, A esquiva, B interagir,
   LB bloquear, RB Ruptura, L3 correr, R3 fixar alvo, D-Pad↓ poção, Start pausa).
   Ecrã de Controlos agora lista teclado **e** gamepad.
2. **Dificuldade** (`game_state.gd`, `ui.gd`, `enemy.gd`, `player.gd`):
   Casual (dano sofrido ×0.65, inimigos −25% HP), Normal, Pesadelo (+35%
   dano sofrido, inimigos +25% HP, **+50% XP**). Botão no menu de pausa
   (`Dificuldade: … ⟳`) que cicla; persistida no save (`"difficulty"`),
   aplicada ao dano recebido imediatamente e ao HP inimigo em novos spawns.
3. **IA cooperante** (`enemy.gd`): Salteador sem Mago por perto escolhe lado de
   flanco por instância (lados opostos garantidos); com Mago vivo, o Salteador
   posiciona-se de guarda-costas (entre o Mago e o jogador); o Mago com guarda
   mantém 13/8 m em vez de 11.5/6 m.
4. **Hit-stop** (`player.gd`): `Engine.time_scale = 0.2` durante 90 ms (leve)
   ou 130 ms (pesado) com temporizador `ignore_time_scale`; stackável (idempotente).

## 4. Verificação

`python3 tools/validate.py` → OK; `gdparse` limpo nos 17 scripts; varredura de
identificadores → limpa; nenhuma cena `.tscn` alterada; save mantém
compatibilidade retroativa (campo `difficulty` ausente → "normal").

## 5. Riscos abertos e dívida (o próximo dono desta branch precisa disto)

1. **Executar no Godot 4.2+ e validar no F5**: escalas/facing dos modelos
   (`MODEL_FACING_OFFSET` em `model_factory.gd`), ordem de autoloads,
   AnimationPlayer dos GLBs (encontrados por `find_child`), performance em
   `gl_compatibility`. Corrigir o que estiver torto — é barato.
2. **Volume mestre**: expor no menu de pausa (slider) — o backend já existe.
3. **Hit-stop agressivo** pode cansar em combos longos: reduzir para 60 ms se o
   dono achar demais (1 constante).
4. **Dificuldade** afeta inimigos já vivos apenas via dano; HP extra aplica-se a
   spawns seguintes (intencional, documentado no tooltip futuramente).
5. **Save v1** sem migração: ao mudar schema, bump `"version"` e migrar em
   `load_game()`.
6. **Áudio** continua sintetizado; trilha dinâmica (P6) precisa de composer ou
   fonte CC0 verificada.
7. **Teste com jogadores reais** continua por fazer (ambiente sem engine).

---

# 6. Addendum v1.0 — Qualidade, acessibilidade e lançamento (2026-11-06)

Extensão da auditoria v0.2 cobrindo o trabalho de v0.5→v1.0 e as correções
feitas sobre ela. Método igual: validação estrutural real (gdparse 23
scripts, varredura de `res://`), nada foi «testado no Godot» — o binário
continua indisponível nos hosts permitidos.

## 6.1 O que foi verificado mecanicamente (verde)

- `python3 tools/validate.py` → **OK** após todos os incrementos
  (v0.5 mundo aberto, v0.6 facções, v0.7 finais políticos, v1.0).
- 23 scripts gdparse limpos, incluindo os novos `src/core/balance.gd` e
  `tools/l10n_extract.py`.
- Todos os `res://` novos (música sintetizada, `balance.json`) existem no disco.

## 6.2 Implementado em v1.0

1. **Balanceamento data-driven** (`src/core/balance.gd` +
   `src/balance/balance.json`): dificuldade (casual/normal/pesadelo — dano
   recebido, vida inimiga, multiplicador de XP), fórmula de XP por nível,
   coeficientes por atributo (HP, dano, fôlego, velocidade, janela de parry,
   postura, lock-on, ruptura) e cura da poção. `GameState` usa o ficheiro com
   fallback para as constantes — jogo nunca arranca vazio por JSON em falta.
2. **Música dinâmica** (`tools/synth_music.py` →
   `assets/audio/music/{exploration,combat,system}.wav`): três temas 11025 Hz
   mono sintetizados por numpy (loops de 38–40 s), tocados pelo autoload
   `Audio` (`play_music`, volume por modo, `LOOP_FORWARD`). Exploração/combate
   transicionam por proximidade de inimigos (<14 m, sondagem a cada 2 s em
   `main.gd` e `region.gd`); Sala Branca usa `system` (exploratório-inquietante)
   e `combat` durante a simulação. Interruptor «Música» no menu de pausa
   (persistido). Nota de honestidade: é música sintetizada funcional, não
   arranjos de compositor.
3. **Remapeamento de controlos** (`input_setup.gd` reescrito): fonte única
   `ACTIONS` (18 ações, teclado+rato+gamepad), `apply_custom_bindings()`
   aplica overrides do jogador (uma tecla substitui o default por ação),
   `binding_summary()` mostra o bind ativo. Painel CONTROLOS refeito com
   `ScrollContainer` + botão por ação que entra em modo «prime a nova
   tecla/botão» (Esc cancela); respeita keys, botões de rato e botões de
   gamepad; botão «Repor predefinições». Persistido no save v2
   (`custom_bindings`), aplicado no arranque, no `load_game()` e no
   `reset_for_new_game()`.
4. **Acessibilidade**: legendas com escala 80/100/125/150 %
   (`Dialogue.set_subtitle_scale`, botões de diálogo incluídos);
   daltonismo Okabe-Ito (protanopia/deuteranopia/tritanopia) aplicado às
   barras de vida/fôlego/Ruptura via cópia do stylebox `fill`; tudo
   persistido no save (`colorblind_mode`, `subtitle_scale`).
5. **Integridade do save** reforçada: sha256, escrita atómica (`.tmp`),
   restauro `.bak` (já existia); `load_game()` passa a reaplicar os bindings
   do jogador depois de carregar.
6. **Localização — andaime**: `tools/l10n_extract.py` extrai 405 strings com
   contexto (371 no commit v1.0; `docs/l10n/strings_pt.csv`); `docs/LOCALIZATION.md` documenta o
   caminho para EN/ES (runtime switching ainda **não** existe — a língua de
   origem continua a ser o português europeu, embebido).

## 6.3 Dívida aberta (não fingir o contrário)

1. **Nada foi executado no Godot** — escalas de modelos, loops de música,
   limites de importación de WAV e o rebind em runtime são suposições
   baseadas na documentação; o primeiro F5 é o teste real.
2. **Tradução runtime inexistente** (EN/ES) — só andaime; `tr()` e
   `.translation` por fazer.
3. **Assistência de mira e narração de menus** (screen reader) — não feitos.
4. **Testes com jogadores reais** — impossível neste ambiente.
5. **Performance não medida** (LOD, streaming, draw calls) e
   **meta-quests globais** (Ferida, golpes de Estado) incompletas.
6. `get_theme_stylebox("fill")` recolore as barras funcionando em Godot 4;
   se o estilo for alterado no futuro, o recolorido tem de acompanhar.

---

# 7. Addendum v0.8 — Continuação do jogo completo (2026-11-06)

Pedido do dono: «vamos fazer o jogo completo». Neste incremento, por ordem de
risco/valor:

1. **Economia + fabrico (v0.6)**: a forja de Garr (Garr, o Ferreiro — nó de
   diálogo `garr_shop`) passa a incluir fabrico: poção (2 Fibras de Ruína +
   10 marcos), Bálsamo de Salvação forjado (3 Fibras + 20 marcos; trata
   lesões e restaura corpo), têmpera da lâmina (150 marcos, +12% dano
   permanente, `weapon_tempered` persistido). Fibras de Ruína são a moeda de
   herva recolhida no mundo — agora têm três usos reais.
2. **Assistência de mira (v1.0)**: em `_do_attack`, com `aim_assist` ativo, o
   corpo do Kael vira 65% para o alvo mais próximo ao alcance antes do cálculo
   dos acertos — desligável no menu de pausa. Só corpo a corpo.
3. **Narração de menus (v1.0, parcial)**: com `menu_narration`, todas as
   notificações são lidas pela primeira voz TTS disponível no sistema
   (`DisplayServer.tts_speak`). Sem escolha de voz, sem narração por botão.
4. **Técnicas de Kael (v0.2)**: `Passo Vazio` (tecla V — blink de 8 m + 0,6 s
   de invulnerabilidade, recarga 14 s; desbloqueada na 1.ª Ruptura),
   `Corrida do Predador` (C — dash de 11 m, +35% velocidade por 4 s, próximo
   golpe +50%, recarga 16 s; desbloqueada no Nv 8), `Queda do Colosso` (Z —
   AoE de 4,5 m / 55 dano + 80 postura, consome 50% de Ruptura, recarga
   20 s; desbloqueada na 3.ª ativação de Ruptura). Recargas no dicionário
   `technique_cooldowns` (exposto ao HUD), slots próprios no HUD, contador
   `rupture_activations` persistido, anúncio de desbloqueio único por
   técnica (`techniques_seen`).
5. **Lock-on (v0.2)**: Tab cicla para o próximo inimigo vivo mais próximo
   dentro do alcance de lock; duplo toque (<400 ms) larga o alvo. Esc nunca
   largou alvos; continuar a usar Tab.

## 7.1 Dívida e limitações conhecidas (não maquilhar)

- **Passo Vazio atravessa paredes**: é um deslocamento direto sem raycast —
  paredes finas não param o blink. Corrigir com raycast de obstrução no
  próximo incremento de robustez.
- **Queda do Colosso** consome Ruptura fora do fluxo normal
  (`rupture_time_left` intocado) — comportamento intencional, documentado.
- **Aim assist** só afeta ataques corpo a corpo; não há assistência para
  projéteis (inimigos) nem para tiros à distância do jogador (não existe).
- **TTS depende do sistema operativo** — sem vozes no dispositivo, o botão
  existe mas não fala (o toggle persiste na mesma).
- Nada disto foi **executado no Godot**; `validate.py` ✓, gdparse ✓, 405
  strings extraídas.

---

# 8. Addendum v0.9 — Vida no mundo e confirmações de combate (2026-11-06)

1. **NPCs com rotinas (v0.5)**: `npc.gd` ganhou `_update_routine()` — os
   aldeões (e outros ids não-enraizados) vagueiam entre 3 waypoints num anel
   à volta do posto de origem, com pausas aleatórias de 2–6 s, ficam parados
   quando o jogador está a menos de 2,1 m e olham-no de frente. Ids de
   quest/comércio (elen, garr, dario, voss, companheiros) ficam enraizados.
   Limitação documentada: **sem pathfinding** — podem trespassar props
   baixos; vias horizontais apenas (sem variação de Y).
2. **Cancelamento de movimento por ataque (v0.2)**: atacar durante a esquiva
   (`_dodge_timer > 0`) termina-a imediatamente e executa o golpe — o flow
   que os jogadores esperam de ARPG/Souls.
3. **Clima dinâmico confirmado (v0.5)**: o `_storm` por região já existia
   (30% por viagem; névoa ×1.55, sol e ambiente atenuados). Sem chuva
   visível nem raios — continua [ ] em efeito.
4. **Strings de l10n**: 405 (nenhuma nova neste incremento).

## 8.1 Não feito de caso pensado

- **Streaming por grid cells**: exigiria reestruturar `region.gd`/cenas sem
  poder medir draw calls — risco cego inaceitável sem engine; fica para
  quando o primeiro F5 permitir profiling.
- **Chuva/raios visuais**: precisa de partículas/shader — junto com a
  primeira sessão de polish gráfico.
- Nada disto foi executado no Godot; `validate.py` ✓ (405 strings OK).

---

# 9. Addendum v1.0.1 — A engine correu (2026-11-06)

Godot **4.7.2-stable** compilado neste ambiente a partir do código-fonte
(`docs/BUILD.md` para o procedimento completo e o porquê). Resultado:
**SMOKE OK nas 5 cenas** + **13/13 asserções de jogabilidade** + **5/5 asserções de fluxo completo** (Sala Branca → painel de avaliação; Prova de Duelo → Bram companion).

A engine encontrou em minutos bugs que a validação estática e as revisões
humanas não apanharam — o pior: o **save/load nunca funcionou** (o checksum
sha256 comparava strings que o roundtrip float do JSON do Godot garantia
diferentes). Corrigido com serialização canónica; saves antigos são
inválidos (e já o eram, silenciosamente). Ver §BUILD.md para a tabela
completa.

Nota de honestidade: correr headless prova compilação, boot, autoloads e
**lógica** — não prova correção visual nem de jogabilidade real (mouselook,
câmara, hit reactions, animações, GL Compatibility em GPU real, Android
build). O primeiro F5 num editor com display continua a ser o teste real.

---

# 10. Addendum v0.6 — Lesões persistentes e treino com mestres (2026-11-06)

Pedido do dono: «continua com o projeto». Incremento: a última fatia de
sec. 8 do GDD que faltava implementar.

**Implementado:**
1. **Lesões graduadas 0–2** (era binário): 1 = magoado (−10% dano, −15%
   velocidade, −15% recuperação de fôlego) · 2 = grave (−22% dano, −32%
   velocidade, −30% recuperação). Golpe ≥ 25% da vida máxima escalona o nível.
   Penalizações via `injury_speed_mult` / `injury_damage_mult` /
   `injury_stamina_mult` aplicadas em `move_speed`, `damage_mult` e
   `stamina_regen`. Persiste no save (`injury`, clamp 0..2 — saves antigos
   continuam válidos).
2. **Treino com mestres e fadiga de treino** (travão anti-grind do GDD
   «Kael não pode treinar infinitamente»): o balcão do Mestre Dario gasta
   120 marcos → +1 ponto de atributo e **+1 fadiga**; a fadiga no MÁX (3)
   bloqueia novas sessões; **só o repouso** a repõe. Lógica partilhada entre
   UI e testes em `GameState.try_train_attribute()`.
3. **Repouso alivia 1 nível de lesão** (não cura tudo) e repõe a fadiga;
   Bálsamo de Salvação (loja 60 marcos / forjado 20) continua a curar
   lesões por completo. Rest aponta já diziam «trata lesões» — texto e
   prompt agora descrevem o efeito real.
4. **UI**: o painel de Atributos mostra Estado (Saudável/Magoado/Grave) +
   lesão e fadiga (0–2 / 0–3).

**Verificação (contagem fresca, neste incremento):**
- `tools/smoke_test.tscn` → **19/19 PASS** (6 novas: dano escalonado,
  escalonação 0→2, repouso −1 nível, fadiga bloqueia treino, save/load de
  lesão+fadiga, treino gasta marcos e soma fadiga).
- `tools/smoke_flows.tscn` → **5/5 PASS**.
- `tools/headless_check.sh` → 5 cenas, **zero erros de script** — e a
  partir de agora **erros de script falham o gate** (ver incidente abaixo).
- l10n: 405 → **408 strings** (`tools/l10n_extract.py`).

**Incidente honesto deste incremento:** a minha primeira versão de ui.gd
tinha um erro de parse (`var estado := ["A","B"][i]` — o GDScript não infere
o tipo a partir de um literal de Array indexado). O autoload UI **não
carregou** e o Sala Branca rebentou em cadeia (`UI` == Nil); a falha só
apareceu na contagem agregada porque o `headless_check` original só olhava
ao código de saída. Duas correções: tipagem explícita (`var estado:
String = ...`) e **gate reforçado** — `SCRIPT ERROR`/`Parse Error`/falha de
autoload em qualquer cena marcam o SMOKE como FALHA. A engine apanhou o meu
erro outra vez; o gate agora também apanha.

**Não feito de caso pensado:** medicamentos e curandeiros dedicados (só
repouso + Bálsamo); romances com memória de ações; streaming/chuva/NPC
pathfinding (v0.5); EN/ES runtime, narração incremental por botão,
performance medida (v1.0); teste com humanos e F5 com display continuam
geradores de valor reais que este ambiente não pode produzir.

---

# 11. Addendum — Auditoria completa e retoma de trabalho em voo (2026-11-07)

Pedido do dono: «faça uma auditoria para ver o que falta e continua fazendo
e retificando sem parar». A auditoria começou com a **working tree suja**:
uma implementação em voo (v0.5 tempestade + v1.0 narração/perf + v0.6
curandeiro) não verificada — nada dela foi escrito nesta sessão; tudo foi
revisto, verificado e integrado antes de commitar.

**O que a auditoria encontrou e fez:**
1. **Tempestade visível (v0.5)**: chuva GPUParticles3D (900 gotas) que
   acompanha o jogador + relâmpagos (flash de sol/ambiente, flicker) +
   trovoada sintetizada (`thunder.wav`, pré-carrega via `Audio` com
   fallback silencioso). O gatilho **já existia** (`_storm = randf() < 0.3`
   por visita) — o diff enganava; não "corrigi" o que não estava quebrado.
2. **NPC — desvio de obstáculos (sec. 9)**: leque de raios a ±40°/±80°/±120°
   a partir de 1.5 m à frente (máscara 1, exclui o próprio corpo). **Não é
   A\*/navmesh** — um NPC preso entre dois obstáculos pode ficar sem dir
   (sem regressão: antes atravessava props às cegas).
3. **Narração incremental por botão (v1.0)**: `GameState.tts_say` partilhado;
   foco/hover lê o botão (menus, pausa, diálogos, viagem rápida). Gate por
   `menu_narration` — silenciosa se desligado ou sem vozes no sistema.
4. **Remendo do curandeiro (sec. 8, v0.6)**: −1 nível de lesão por 45 marcos
   na loja do Garr (`try_spend_marcos`/`heal_injury` em GameState — guarda
   testada). Cura total continua a ser o Bálsamo.
5. **Sonda de performance** (`tools/perf_probe.tscn`): CPU-side headless —
   ms de frame/física, memória estática, objetos/nós/órfãos (este commit:
   0.34 ms proc / 0.50 ms fis / 118.6 MB / 4250 obj / 1122 nós / **0
   órfãos**). **Números headless não predizem GPU/Android** — exigem F5 em
   hardware real.
6. **smoke_test alargado**: 22/22 PASS (guarda de marcos ×2, remendo).
7. **Gate reforçado** (v0.6): `headless_check.sh` falha em SCRIPT ERROR —
   adotado depois de o parse error de ui.gd ter matado o autoload UI sem
   falhar o build.
8. **Docs alinhados**: BUILD (13→22, bug #9), ROADMAP (chuva/trovoada,
   curandeiro, narração por botão, sonda), LOCALIZATION 405/408→**411**.

**Não feito (explícito):** streaming por grid cells (v0.5 — a peça maior);
meta-quests globais Ferida/Custódia; romances com memória de ações; EN/ES
runtime; escolha de voz TTS; teste com humanos; F5/GPU/Android; perfil
real de performance.


---

# 12. Addendum — v0.5 Streaming: decisão medida, não fé (2026-11-07)

O ROADMAP pedia «streaming de mundo (grid cells)». Antes de escrever
células, medi: o mundo principal tem ~91 instâncias de decoração
(26+42+14 relvas, 6 arbustos, 3 escarpas) + ~30 edifícios/árvores. Um
sistema de streaming (grid + ResourceLoader assíncrono + gestão de
ciclo de vida) seria complexidade e risco **sem ganho mensurável** para
este mundo — o frustum culler nativo já descarta o que não está à vista;
a física nunca foi afetada por distância de render.

**Implementado:** `spawn_env(..., far_cull)` — `visibility_range_end` de
55 m (+4 m de margem, fade desactivado) em toda a geometria de
decoração (relvas no mundo principal e nas regiões). Edifícios,
estácuas e npcs mantêm alcance total (landmarks). Física e lógica
intactas — é culling de render, não descarregamento de nós.

**O que isto NÃO é:** grid cells de verdade (descarregar colliders e
nodos lógica/física à distância). Adiado honestamente — reabrir quando o
mundo crescer ≥5× ou quando profiling em hardware mostrar pressão real de
draw calls. Benefício medido aqui: nenhum (headless não desenha; o
culling nativo poupa GPU, não CPU — 0.367 ms proc vs 0.337 ms antes,
ruído). Também removida uma linha duplicada em world_builder.gd
(`directional_shadow_max_distance` repetida).

**Verificado:** 5 cenas headless sem erros de script · smoke 22/22 ·
flows 5/5 · validate.py OK.

---

# 13. Addendum — Escolha de voz TTS (v1.0, 2026-11-07)

Fecha a última lacuna da narração: `tts_voice` (id da voz; `""` = automática,
1.ª voz do sistema). `cycle_tts_voice()` percorre Auto → todas as vozes do
sistema; botão «Narração — voz (⟳)» no menu de pausa; persistida no save
(com roundtrip testado). `tts_say` usa a voz escolhida (silencioso e sem
rebentar se não houver vozes — o headless não tem nenhuma).

**Verificado:** smoke **24/24** (2 asserções novas: save/load da voz, ciclo
sem vozes) · flows 5/5 · headless limpo · l10n 415 strings.

**Honestidade:** o headless não tem vozes TTS — a escolha de voz é validada
em persistência e resiliência, **não** em qualidade vocal humana (F5 na
máquina do dono). Flake no teste de salto (frame≥75 disparava em corridas
lentas) alargado para frame≥120 e re-verificado 3× consecutivas verdes.

**Ainda em aberto (v1.0):** EN/ES runtime (a peça maior — exige varrer
`tr()` por todo o código; decisão deliberada de não entregar i18n a meio),
testes com humanos, profiling em hardware real, meta-quests globais
(Ferida/Custódia), romances com memória de ações (exige conteúdo de
escolha novo — sem isso seria maquilhagem).

---

# 14. Addendum — CI no GitHub Actions (2026-11-07)

**O que foi pesquisado no GitHub e usado:** (1) releases oficiais de
`godotengine/godot` — confirmado o asset `Godot_v4.7.2-stable_linux.x86_64.zip`
(o sandbox não o alcança; os runners GitHub alcançam); (2) PR #1 — sem checks
(nenhuma CI existia); (3) `gdtoolkit` no PyPI (fornece `gdparse`, usado por
`validate.py` — ausente nos runners).

**Entregue:** `.github/workflows/headless-smoke.yml` (checkout → libs
`libfontconfig1/libx11-6/libgl1/...` → binário oficial 4.7.2-stable →
`requirements-dev.txt` → `validate.py` → `headless_check.sh` → smoke_test →
smoke_flows; `ubuntu-latest`, timeout 20 min, `concurrency` cancela runs
obsoletos). Badge no README; `requirements-dev.txt` novo.

**Falhou 1× e foi corrigido de forma visível:** o primeiro run morreu no
`validate.py` (`gdparse` não existe nos runners — o binário vive em
`/usr/local`, que NÃO persiste entre sessões neste sandbox). Correção:
`gdtoolkit` instalado no CI + erro claro em `validate.py` se faltar +
`checkout@v5`. Segundo run: **verde em 58 s** — e o PR #1 passou a mostrar
`Import + smoke (headless) — pass — 1m3s`.

**O que o CI prova:** compilação/parse de scripts (gdparse + engine),
import de recursos, boot das 5 cenas sem erros, 24 asserções de jogabilidade,
5 fluxos completos — fora do meu sandbox, por commit. **O que não prova**
(o limite natural): correção visual, GPU/GL Compatibility, Android,
testes com humanos, performance real. Continuam a exigir F5 na máquina do
dono do projeto.

---

# 15. Addendum — i18n runtime PT/EN/ES (2026-11-07)

**O que era dívida:** toda a UI/diálogos/finais estavam embutidos em PT;
`tr()` não existia; existia só andaime (`strings_pt.csv` + extractor).

**Entregue:** troca de idioma em runtime entre Português, English e Español.
~110 sítios `.text`/`notify(...)` envolvidos em `tr()`; `notify()` traduz no
choke point (todas as notificações, incl. as pré-existentes); os helpers
`_*_text()`/`objective_text()`/`_build_credits_text()` passam a devolver
strings compostas já traduzíveis; o **typewriter** do diálogo fatia o texto
JÁ traduzido (nunca `tr()` por substring). Chaves = literais PT → se uma
chave faltar, `tr()` devolve a chave: o jogo continua íntegro no original.

- Seletor **Português/English/Español** no ecrã de título (canto inf. dto.),
  com `reload_current_scene()` — troca imediata e uniforme (a UI é construída
  uma vez por cena; recarregar é a única troca garantidamente coerente).
- `locale` persistido no save (campo aditivo; saves v2 antigos carregam PT);
  `TranslationServer.set_locale` no boot (autoload `GameState._ready`) e no
  `_apply_save_dict`.
- `l10n/game.csv` — 421 chaves, EN+ES completas (registo literário do
  original preservado; nomes próprios ficam PT de propósito).
- `tools/l10n_build.py` — re-extrai e atualiza mantendo traduções; `--check`
  falha em falta/TODO/chaves obsoletas. `validate.py` ganhou passo `[5/5]` →
  **o CI passa a falhar se uma string nova entrar sem EN/ES**.
- `[internationalization]` em `project.godot`: `locale/translations`=
  `game.en.translation`+`game.es.translation` (geradas por `--import`),
  `locale/fallback=pt`. Os binários não são commitados (derivados do CSV);
  `validate.py` trata refs a `*.translation` como artefactos de import.
- `tools/i18n_runtime_check.gd` + passo **i18n runtime check** no workflow:
  depois do `--import`, valida PT/EN/ES e format strings no próprio engine
  (`tr()` real, não mock). PT pass-through continua intacto sem import.

**Falhou 1× e foi corrigido no CI:** `tr()` dentro de `static func`
(`model_factory.gd:spawn_damage_number`) — `tr()` é método de `Object`, não
existe em contexto estático; `headless_check` falhou no primeiro push.
Corrigido (o número de dano nunca precisou de tr) — pipe ausente de classes
lint estáticas; lição registada: `tr()` só em context de instância e nunca
por substring. `8a7fd8a` — **verde no CI** (validate 5/5 com gate i18n,
headless_check, smoke 24/24, flows 5/5) e PR #1 com check `pass`.

**Honestidade — o que ainda NÃO é verdade nesta peça:**
1. QA por falante nativo não existe (traduções são do autor; ES neutro).
2. Revisão visual em F5 não existe — EN corre 1.3× mais largo; caixas de
   texto apertadas podem rebentar.
3. `.translation` binários não são commitados de propósito (binários
   derivados do CSV, gerados por `--import`). O E2E de runtime corre no CI
   depois do import — `tools/i18n_runtime_check.gd` (PT/EN/ES, formatos
   posicionais) — e é o gate permanente; ambiente local sem engine pode
   validar tudo exceto esse passo.
4. Sem namespaces nas chaves (decisivo para 421 strings); migrar só se a
   tabela explodir.
5. Granularidade: `±`/`⟳`/`%` embutidos em chaves de formatos — tradutores
   devem mantê-los.
6. Romances com memória de ações continuam fora de escopo (v1.1+).

Supersedes: dívida «Tradução runtime inexistente» (§6.3 #2) e o fecho de
scope no addendum v1.0.

---

# 16. Addendum — Recuperação de desastre + finais persistidos (2026-11-07)

**Recuperação após wipe do `/tmp`:** a sessão foi reiniciada (timeout) e o
ambiente perdeu `/tmp` por completo — incluindo a árvore de fonte do Godot
4.7.2 (~612 MB, ~5 h de build com duas sessões a comandar-a) e o `.bin` da
média memória. O repositório em `/home/user` não perdeu UM byte (verificado
com clone fresco do `origin/arena/...` — diff vazio exceto as alterações por
commitar) e os refs do git tinham recuado para `9b6a63a Initial commit`;
restaurado com `git reset --hard origin/arena/498f65a7-the-giselle-project`
(d89248a). O **CI passou a ser o verificador de engine** (binário oficial
4.7.2-stable do GitHub): validate 5/5 + import + 5 cenas + i18n runtime
(PT/EN/ES) + smoke_test 24/24 + smoke_flows 5/5. Nenhuma tarefa ficou por
causa do wipe.

**Gap encontrado e corrigido (auditoria ao save/load):** os «finais anteriores»
da decisão v0.7 eram **letra morta**: `GameState.ending` era escrito na
decisão e persistido no save, mas
1. saves só existem de forma manual (menu de pausa) → o final NUNCA era
   gravado na decisão;
2. nada, em parte nenhuma, lia `ending`/`endings_seen` entre runs;
3. o `version` do save era escrito e nunca verificado → um save de um build
   futuro seria carregado em silêncio pelo build anterior.

**Entregue:**
- `endings_seen: Array[String]` no save (aditivo, backward compatible; saves
  antigos carregam com `[]`); sobrevive a `reset_for_new_game()` de propósito
  (metadados entre runs). Duplicados impossíveis; ~50 B por final.
- `register_ending()` é chamado na decisão final (`ui.gd::_choose_ending`) e
  **o save acontece automaticamente nesse momento** (posição/vida/fôlego do
  jogador, como no guardar manual) — sem esta peça, «finais anteriores» nunca
  persistia na prática.
- Créditos passam a mostrar `Finais vividos: N` (string PT/EN/ES).
- `load_game()` **recusa saves de versão mais recente** que `SAVE_VERSION`
  (2) com notificação honesta — saves antigos continuam a carregar (defaults
  são a migração).
- `validate.py` [2/5] passou a tratar `res://…*.translation` como artefactos
  gerados por `--import` (não commitados); `.translation` binários continuam
  fora do git por desenho; o gate de runtime corre no CI depois do import.

**Ainda em aberto (sem mudança):** meta-quests globais Ferida/Custódia
(consequência world-state entre regiões) continuam adiadas para pós-v1.0 no
ROADMAP — não têm design nem conteúdo no GDD; inventá-las aqui seria scope
creep. Romances com memória de ações, QA por falante nativo, F5 e profiling
em hardware real: em aberto.

---

# 17. Addendum — v1.0: cel nativo, meta-quests e memória de romance (2026-11-07)

Fecha o bloco pedido pelo comandante: inspiração em Genshin Impact (técnica,
nuncam conteúdo), as duas meta-quests antes adiadas e romances com memória —
sem scope creep escondido.

**1. Look cel nativo** (`model_factory.gd::apply_cel_look`, docs/VISUALS.md):
todo `MeshInstance3D` dos modelos (env+personagens) recebe
`DIFFUSE_TOON` + `SPECULAR_TOON` + rim (0.45/0.5) — recursos nativos do
Godot 4, zero código de terceiros. Toggle **Pausa → Cel-shading** (persistido
no save, aditivo). Saves antigos abrem com Ligada. Consequência conhecida:
troca não repinta instâncias ativas — o botão avisa («requer recarregar a
cena»). **Não feito e porquê:** inverted-hull (artefactos garantidos em
GLES3/Compatibility), ILM/SDF face shadows (exigem mapas por personagem —
KayKit não os tem; seria arte bespoke, não código). Falta a métrica real de
frame-time com GPU (F5) — só o dono consegue medir.

**2. A Ferida** (docs/GDD.md cap. 38): rumor via Voss (estágio≥5) → nó
`voss_ferida` → 3 resoluções permanentes, cada uma com reputação+recompensa
próprias; `world_flags["ferida"]` persiste no save; HUD objetivo; créditos
ack. Zero cenas/geometria novas: o desenlace é escolha+consequência —
exatamente o que as secs. 23–25 pediam.

**3. O Golpe da Custódia** (cap. 39): rumor via Bram (estágio≥5 & ≥2 provas)
→ nó `bram_golpe` → **Denunciar** (Imperial+15/Academia+10/+120XP/+80 marcos)
ou **Ficar calado** (Academia−25 → **o fim «O Reformado» fica bloqueado** no
menu da Decisão, com a razão escrita no botão bloqueado). Bloqueio testado
no código do menu (botão disabled + texto razão). Créditos distinguem os
dois desenlaces.

**4. Romances com memória** (cap. 40): `ROMANCE_EPILOGUES_WARM` por
companheiro quando a lealdade ≥60 no momento da decisão de fim (prova
superada juntos ⇒ ≥60 pelo `_complete_exam`; romance ⇒ +30). Tiers
negativos NÃO implementados (não existe verbo de promessa quebrável —
cap. 40, limite honesto).

**5. Documentação nova:** `docs/INSPIRATION.md` (11 repos estudados — 7 de
fis/APIs/dados como referência de engenharia, 4 mortos/404 — e a fronteira
legal: zero assets/dados HoYoverse no produto); `docs/VISUALS.md`;
`docs/PLAYTEST.md` (checklist F5/Android/QA nativo EN/ES); GDD 38–40;
ROADMAP riscado nas duas meta-quests e romances; LOCALIZATION 460/460.

**Verificado:** gdparse 5/5 · validate.py · i18n 460/460 EN+ES · CI verde no
push do cel (`322f1b6`; smoke 24/24 + flows verdes); CI do push das
meta-quests (`8c73ae5`) a monitorizar no check do PR. **Bloqueado
honestamente (falta ao dono):** F5 + GPU (rim/toon/clipping), Android
(touch/fps/thermal), QA nativo EN/ES, testes com humanos — ver
`docs/PLAYTEST.md`.

---

# 18. Addendum — Composição v1.0 dos mapas (2026-11-07)

**Pedido explícito do dono:** «todos os mapas com alta qualidade floresta,
tudo mesmo» → escopo total: Vale + Academia + 6 expedições; qualidade =
densidade/atmosfera **+ POIs**; orçamento = densidade máxima aceite.

**Entregue (código, zero assets novos — tudo KayKit/gobkit CC0):**
`src/world/map_kit.gd` (composição partilhada, seeds fixas, ring-scatter com
raio de exclusão, colisores só no essencial); `region.gd::_compose_biome`
(composição por bioma); `world_builder.gd` (Vale: 96 árvores + saplings +
22 rochas + 14 arbustos + 8 marcos de pedra + POIs: acampamento abandonado,
ruínas dos Engenheiros, posto colapsado); `academy.gd::_build_gardens_extra`
(sebes, 9 árvores, braseiros da linhagem); composições únicas por região —
Ruun (dupla copa 66+34 + templo engolido), Sahr (oásis de pedra + obelisco
solar + caravana), Khar (para-raios runado + posto de vigia), Lume (anel de
escarpas + farol de fósforo azul + doca), Aer (ilhas flutuantes + arco
partido), Orun (altar de 7 colunas + fenda incandescente de 30 m, zero
vegetação). Ver tabela completa e limites em `docs/WORLD.md`.

**Verificado:** gdparse 6/6 · validate.py · i18n 460/460 · CI (boot das cenas
region/main/academia) no push. **Não verificável aqui (F5 do dono):** FPS
com a densidade máxima no Android, clipping de colisores, ordenação
cel/materiais na profundidade, sombras de 200+ instâncias. Se o Android
ressentir, cortar 30–40% dos `*_scatter` por bioma — um parâmetro cada
(ver WORLD.md).

**Fora do escopo de caso pensado (registado):** HeightMap/relevo real, água
real, fluxo de jogo novo nos POIs.

---

# 19. Addendum — Ambiente vivo: vento, vida e detalhes (2026-11-07)

**Pedido explícito:** «Capricha nos mapas, terrenos, vilas, castelos,
academias etc, coloca cada detalhe mesmo o balançar das árvores, tudo mesmo».

**Entregue (nodes/materiais nativos — nenhum shader novo):**
`src/world/ambience.gd`: grupos `sway/bob/spin` (uma única travessia por
frame, sem acumulação de rotação), bandos de pássaros em V, partículas
nativas por bioma (folhas/brasas/vaga-lumes/pó/neve/nuvens/motes/pétalas).
Vento automático via `spawn_env` (relva > arbusto > árvore em amplitude).
Detalhes: lagoa do Vale + doca + nenúfares, corda de roupa, placa da taverna,
festões, fachos de luz do dossel (Ruun+Vale), orbe meio-soterrado (Sahr),
cristais de Khar, feixe rotativo do farol (Lume), ilhas flutuantes levitando
(Aer/Orun), braseiros/leitos/mastro/círculo dos novatos (Veyra), pétalas
(Veyra), neve (Khar). Ver docs/WORLD.md (secção Ambiente vivo v1.1).

**Correção de fundo:** `spawn_env` tinha perdido a chamada `apply_cel_look`
no incidente de rollback do `.git` — restaurada; vegetação agora é cel +
vento. (Aprender duas vezes: verificar sempre com `grep` após edits.)

**Verificado:** gdparse 7/7 · validate.py · i18n 460/460. **Bloqueado
honestamente (F5/GPU do dono):** custo de 400+ nós em senóides/frame,
partículas em GLES3 (o rain já prova o caminho; quantidades são modestas),
aditivo das lâminas, e o lago a 90% opaco (se o driver não gostar, descer
para 0.82). Atenção ao Android: o vento é CPU — barato; as partículas são
GPU-bound — cortar quantidades se necessário.

---

# 20. Addendum — Retratos do elenco (v1.2, 2026-11-07)

**Pedido explícito:** «Agora vamos aos personagens vamos detalhar de uma forma
absurda e com alta qualidade, o personagem principal é esse (na foto), e os
secundários vc pode criar usando a mesma referência trocando gênero roupa
formato de rosto».

**Entregue:** 10 folhas de personagem geradas por IA a partir de
`assets/art/kael_reference.jpg` (Kael neutral/determined/pained/soft/battle,
Elen, Tomás, Garr, Liora, Dario), recortes «bust» por recorte via PIL para o
jogo, integração no diálogo (retrato no painel), na decisão final (Kael em
combate) e no ecrã de fim (romanceado ou Kael decidido).

**Bloqueado honestamente:** 6 folhas (Bram, Sena, Iven, Voss, Cadena,
Vladimir) não geradas — o assistente atingiu o limite de geração de imagens
da sessão (10 por turno). `src/ui/portraits.gd` já as resolve por nome assim
que os ficheiros existirem (fallback invisível até lá; nunca um rosto errado).

**Verificado:** gdparse nos alterados · validate.py · i18n 460/460 ·
retratos gerados confirmados visualmente (Kael 5/5 e secundários 5/5 fiéis
ao estilo da referência) · CI do push `42373668333` 12/12 ✓ e CI do PR
`42373672722` ✓ (ambos via `gh`, 2026-11-07 ~17:5x UTC — aliás, o
`smoke_test` do PR anterior que falhara às 51s era mesmo flake: a mesma
asserção passou no push seguinte com o mesmo código).
**Resolvido (2026-11-07, mesmo dia):** as 6 folhas em falta (Bram, Sena,
Iven, Voss, Cadena, Vladimir) foram geradas; recortes bust a partir do painel
de close-up da própria folha (moldura fina de inset — uniforme entre os
cinco) para Bram/Sena/Iven/Voss/Cadena e bust da figura principal para
Vladimir. 16/16 retratos integrados (`src/ui/portraits.gd`); validate.py ✓
· i18n 461/461.

---

# 21. Addendum — Movimento e poderes (v1.3, 2026-11-07)

**Pedido explícito:** «Movimento dos personagens, poderes, tudo bem feito
passo por passo» (âmbito escolhido pelo dono: tudo — Kael, inimigos,
companheiros/técnicas, feedback visual e equilíbrio).

**Entregue:** coyote time + jump buffer (data-driven, com fallbacks),
Aterragem pesada com impacto cinematográfico, FOV dinâmica da câmara
(corrida/Predador/Ruptura), micro hit-stop no parry, afterimages nas técnicas
de Kael, burst escalável em `spawn_hit_burst`, arremesso telegrafado e
readable do Lobo de Cinza, glows de canalização/disparo do Mago de Cinza,
fúria do Guardião a 50% de vida (rugido + sacode + tintura rubra).

**Verificado:** gdparse nos alterados · validate.py ✓ · i18n 461/461
(`O Guardião RUGE…` adicionado ao CSV) · smoke/boot via CI do push (ver
execução do workflow na branch). **Limitações honestas:** o *game feel*
final exige F5/GPU do dono; o foguete `_hit_stop` continua a usar a
técnica `Engine.time_scale` (pré-existente); a Corrida do Predador usa FOV
e não partículas (decisão: legível sem poluir o ecrã em GLES3).

---

# 22. Addendum — Jogabilidade ao máximo (v1.4, 2026-11-07)

**Pedido explícito:** «Vamos melhorar a jogabilidade ao máximo.»

**Entregue:** esquiva perfeita (timing → Ruptura/fôlego/hit-stop), sprint
attack (+25% dano/alcance/arrancada), sinal `damaged` no jogador, flinch em
golpes pesados nos inimigos (imune: Guardião), HP do alvo fixado no HUD,
marcador de impacto ✕, contador de combo, prompt «GOLPEIA AGORA» no alvo
atordoado, banner cinematográfico do Guardião (fade duplo), vinheta de dano
radial (ImageTexture nativa — sem shaders) + pulso sub-30% de vida.

**Verificado:** gdparse nos alterados · validate.py ✓ · i18n 465/465 ·
vínculos de sinais idempotentes (ligados uma vez) · vinheta criada com
EXPAND_IGNORE_SIZE (evita o erro «textura 256px presa»). **Pendente:** CI do
push (a correr no momento da escrita — ver execução na branch); feel em F5
do dono (janela da esquiva perfeita, intensidade do flinch).

---

# 23. Addendum — Qualidade de tudo (v1.5, 2026-11-07)

**Pedido explícito:** «Vamos atacar a qualidade de tudo.»

**Entregue:** smoke de jogabilidade expandido de 24 → 33 asserções
(9 novas, todas determinísticas, a correr no CI em cada push/PR — mecânicas
v1.3/v1.4 deixam de poder partir em silêncio); inventário gdlint completo
(563 → 2 correções reais + 561 convenções da casa documentadas); academy.gd
(PORTAL→portal) e map_kit.gd (whitespace) limpos.

**Verificado:** gdparse nos alterados · validate.py · i18n 465/465 ·
gdlint (baseline conhecido). **Pendente:** evidência do CI com as 33
asserções a correr (ver o run do push desta branch); cobertura de bosses por
asserts é futura e deliberada (não se simula feel com assert).

---

# 24. Addendum — Arsenal e a noite na floresta (v1.6, 2026-11-07)

**Pedido explícito:** «Vamos ao arsenal dos inimigos, a noite deve ter
inimigos nas florestas em áreas (específicas), vamos criar todos inimigos
depois vamos passar para outra fase.»

**Entregue:** 6 tipos novos de inimigo (alfa, umbra, espectro,
guarda_espinho, brasa, veterano) sobre modelos já existentes — nada de
placeholder, nada de assets externos; família lobo estendida (arremesso
telegrafado + clipes `Walk/Attack/Idle_HitReact1/Death`, dano = dmg+4);
família conjurador `cinza`→`cinza`/`brasa` (cor de clarão, projétil e flash
por tipo); os novos universais (brasa/veterano) entram nas pools das 6
regiões de expedição (contagem inalterada: 6 por pool);
ciclo dia/noite **novo no mundo principal** (`day_night.gd` — antes
inexistente; só as regiões tinham ciclo) com relógio partilhado
(`GameState.world_day_t`), notificação trilingue de anoitecer/amanhecer e
relógio ☀/☾ no HUD; **Ecos da Noite** (`night_spawns.gd`): inimigos
noturnos (umbra/espectro/alfa/guarda_espinho/brasa, sorteio por peso)
apenas na zona da floresta do Vale (círculo centro (0, −17), raio 21 m),
máx. 4 vivos, nascimento ≥ 12 m do jogador, desalojados ao amanhecer.

**Causa-raiz do vermelho (bisect guiado pelo CI, 20+ runs):** o boot
headless falhava desde o primeiro push do v1.6. Eliminação metódica
(csv, region.gd, UI, arsenal, world_builder inteiro, ficheiros novos
— cada um testado isolado e consistentemente validado pelo validate.py
local) convergiu para `src/world/world_builder.gd` e, dentro dele,
para `var _env: Environment`: **a classe já tinha `func _env(path,…)`
(usada por toda a composição do Vale) e o analyzer do GDScript rejeita
a redeclaração de `_env` como variável de instância** — erro que só o
engine apanha (gdparse é só sintaxe; os artefactos intermédios do bisect
passavam todos no gdparse). Corrigido com rename `_env → _env_ref`
(3 sítios) — commit `4fb8e34`. Lição registada: nunca introduzir
membros com o mesmo nome de funções existentes da mesma classe.

**Verificado:** gdparse nos alterados · validate.py ✓ · i18n 475/475 ·
**CI duplo verde em `4fb8e34`** — push run `42412702718` (12/12 ✓,
inclui boot das 5 cenas, i18n runtime, smoke 33/33, flows 5/5) + PR
synchronize `42412707485` (success). **Pendente:** F5 do dono (ver GDD
cap. 47, «Estado honesto»). A aurora desaloja Ecos mesmo a meio de um
combate — escolha emética deliberada («banidos pela luz»), não um bug.

**Limitações honestas:** a lua não tem disco (a noite é névoa e
silhuetas); o relógio partilhado corre nas cenas de jogo mas academia/sala
branca não o exibem (o HUD mostra apenas se a cena usa o ui.gd); spawns da
noite não dão prémio se dissolvidos pela aurora; o cycle no Vale usa a
mesma matemática de 240s das regiões — julgado lento/rápido no F5,
ajusta-se num número.

## 25. v1.7 — Qualidade & Performance (fundação mensurável) — 2026-11-07

Resposta direta ao dono: «na parte profunda fazemos performance pelos
profilers e testes em aparelhos fracos». O que era automatizável para
esta stack (Godot 4.2+/GLES3, Android) foi colocado em código e em CI;
o que exige GPU ou aparelho real ficou documentado como fluxo de medição
(docs/PERF.md), não como promessa.

**Entregas:**
- `tools/stress_test.tscn/runner.gd` (novo): mundo principal + equipa de
  **10 inimigos de todos os tipos** (wolf…alfa) à volta do jogador —
  pior caso real do combate; ~14 s de física; asserts de instância da
  equipa, identidade do pool (mesma Area3D reutilizada), stash do pool e
  contagem de inimigos; imprime monitores CPU-side (FPS, físico, memória
  estática, nós, órfãos). Passo novo no CI (push + PR synchronize).
- `src/enemies/projectile_pool.gd` (novo) + `projectile.gd` reutilizável:
  malha/colisor/materiais cacheados; timeout/impacto **estacionam o nó
  fora da cena** em vez de o destruir. Antes: "instanciar+destruir" por
  disparo — o maior churn de nós do combate.
- IA com degradação por distância em `enemy.gd`: acima de
  `combat.remote_ai_distance_m` (34.0, balance.json) salta a separação
  O(n²) entre inimigos, a query de coordenação e a animação por frame;
  movimento/cooldowns continuam a 60 Hz.
- Janelas de combate para dados (`balance.json` → `combat`):
  `parry_window_base` (era literal 0.2 em game_state.gd — agora
  `Balance.combat_cfg()`) e `dash_iframes` (era literal 0.36 em
  player.gd). Contrato igual ao `jump` (995a1b6): afinar sem recompilar.
- `smoke_test_runner.gd`: +3 asserções de save→load (posição, hp,
  fôlego) — a cobertura de save era só de marcos/voz.
- `docs/PERF.md` (novo): o que o CI prova vs o que só o aparelho proba;
  como medir no Android (Editor/Monitors, `adb dumpsys gfxinfo framestats`,
  RenderDoc em GLES3); checklist de entrada de asset (marcadores
  provisórios); frame budget provisório — a confirmar no aparelho.

**Verificação:** gdparse ✓ (8 ficheiros) · validate.py ✓ (a incluir o
.tscn novo) · i18n inalterado (475/475 — v1.7 sem strings novas de UI)
· **CI duplo verde em `cf68298`** — push `42414206666` (13/13 ✓, passo
stress incluído) + PR synchronize `42414212054` (success).

**Limites honestos:** o CI não tem GPU — frame times, 1% low e fluidez
no Android precisam de F5 do dono (fluxo em PERF.md); «relatório semanal
automático» não existe (exigiria runner Android persistente, não é
realista neste repositório); os SMOKE|PERF impressos não foram
extraídos do sandbox (logs do CI bloqueados) — o gate é o exit code do
runner (0 = todos os asserts PASS); streaming de chunks, LOD de meshes
e impostores continuam **não implementados** (prematuros); o tuning dos
34 m e o tempo de física do stress calibram-se com a primeira medição
no aparelho.
