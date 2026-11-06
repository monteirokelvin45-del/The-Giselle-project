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
