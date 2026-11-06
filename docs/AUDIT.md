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
