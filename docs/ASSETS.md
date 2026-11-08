# Assets — fontes, licenças e notas de integração

Inventário de tudo o que vem de fora do projeto, com licenças e onde está usado.
**Tudo o que está aqui é CC0 (Creative Commons Zero) — uso livre, comercial ou
não, sem atribuição obrigatória.** Ainda assim, creditamos os autores na
secção [Créditos](#créditos).

## Modelos 3D — KayKit (Kay Lousberg)

| Pacote | Conteúdo no repositório | Licença | Autor |
|---|---|---|---|
| [KayKit Character Pack: Adventures 1.0](https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0) | `assets/models/characters/*.glb` — Barbarian, Knight, Mage, Rogue, Rogue_Hooded (76 clipes de animação cada, texturas embutidas) | CC0 — ver `docs/licenses/kaykit-characters-LICENSE.txt` | Kay Lousberg |
| [KayKit Medieval Hexagon Pack 1.0](https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0) (seleção) | `assets/models/env/` — 36 modelos glTF (edifícios red/yellow/green/blue/neutral, natureza e props) | CC0 — ver `docs/licenses/kaykit-medieval-LICENSE.txt` | Kay Lousberg |

### Mapeamento de modelos para o jogo

| Jogo | Modelo | Notas |
|---|---|---|
| Kael Noro (jogador) | `Rogue_Hooded.glb` | tintura carvão `Color(0.36, 0.35, 0.37)` — a referência de personagem do dono do projeto é monocromática (ver `docs/CHARACTER.md` e `assets/art/kael_reference.jpg`) |
| Salteador de Ruína | `Barbarian.glb` | tintura avermelhada, escala 1.05 |
| Mago de Cinza | `Mage.glb` | tintura violeta |
| Guardião da Prova | `Barbarian.glb` | tintura de pedra, escala 2.3 |
| Elen Noro (mãe) | `Mage.glb` | tintura esverdeada, escala 0.95 |
| Garr (ferreiro) | `Barbarian.glb` | tintura quente |
| Tomás (aldeão) | `Rogue.glb` | tintura esverdeada |
| Liora Venn | `Mage.glb` | tintura dourada/branca |
| Mestre Dario Vale | `Knight.glb` | tintura azul-aço, escala 1.1 |
| Lobo de Cinza | `creatures/wolf.glb` (Quaternius) | escala à medida do corpo (~1.0); clipes Attack/Walk/Death mapeados |

### Animações usadas (de 76 clipes embutidos em cada GLB)

Idle, Walking_A, Running_A, Blocking, Dodge_Forward, Unarmed_Melee_Attack_Punch_A/B,
Unarmed_Melee_Attack_Kick, Hit_A, Death_A, Spellcast_Raise, Spellcast_Shoot.

Lobos procedural mantém o comportamento v0.1 (sem animação esquelética).

### Notas de integração

- `src/visuals/model_factory.gd` concentra: instanciar modelos, sombras,
  tintura de materiais (duplicados por instância — nunca altera o asset
  partilhado), `play_anim` com duração-alvo, *hit-flash*, explosão de
  partículas e números de dano flutuantes.
- **Eixo de frente**: o código assume modelos a olhar para **+Z**
  (coerente com `atan2(x, z)` usado em todo o código de orientação).
  Se algum modelo vier virado ao contrário, ajustar `MODEL_FACING_OFFSET`
  em `model_factory.gd` (constante de 0.0 rad).
- **Escala/medida dos edifícios e props** são estimativas à partida —
  os modelos KayKit não trazem medidas de jogo. Afina no editor se
  alguma porta/casa ficar desproporcional; os **colisores de jogo são
  invisíveis e independentes dos modelos**, por isso o combate não é
  afetado.
- glTF do Medieval Hexagon referencia a textura atlas `hexagons_medieval.png`
  (uma por pasta) e `.bin` ao lado de cada `.gltf`; toda a árvore foi
  copiada preservando caminhos relativos — não mover ficheiros entre pastas.
- O pack completo de natureza (árvores FBX) foi **descartado de propósito**:
  usaram-se as árvores/montanhas do Medieval Hexagon (consistência de estilo,
  ~2 MB vs. centenas de MB).

## Lobo — Quaternius (via mirror Papyszoo/CC0-Public-Domain-Models)

| Item | Detalhe |
|---|---|
| Ficheiro | `assets/models/creatures/wolf.glb` (1,9 MB, glTF 2.0) |
| Fonte | Quaternius — *Ultimate Animated Animal Pack*, mirror CC0 `Papyszoo/CC0-Public-Domain-Models` (`packs/quaternius-ultimateanimatedanimals/models/wolf/`) |
| Licença | CC0-1.0 — ver `docs/licenses/quaternius-animated-animals-LICENSE.txt` |
| Clipes (12, 153 canais) | Attack, Death, Eating, Gallop, Gallop_Jump, Idle, Idle_2, Idle_2_HeadLow, Idle_HitReact1/2, Jump_ToIdle, Walk |
| Materiais | 4 materiais untextured (baseColorFactor) — sem atlas externo |
| Integração | substitui o lobo procedural; clipes mapeados em `enemy.gd` (lobo: Attack/Idle/Walk/Death/Idle_HitReact1) |

## Vegetação baixa — gobkit (CC0)

| Item | Detalhe |
|---|---|
| Ficheiros | `assets/models/nature/{Grass001..003, Bush001..002, Cliff001..003}.glb` (~15 KB cada) |
| Fonte | `Ariescar/gobkit-free-assets` (Nature Kit, CC0, ver `docs/licenses/gobkit-LICENSE.txt`) |
| Integração | relva ao longo da estrada/floresta/acesso à Academia, arbustos nos remates e 3 escarpas nas bordas (só visual, sem colisores) |
| Não usado | minions/animals do mesmo pack (clipes únicos "movement"/"clip", estilo destoante) |
| Estilo | low-poly minimalista — coexiste com KayKit como camada de detalhe ao nível do solo |

## Áudio

`assets/audio/*.wav` — efeitos sintetizados no próprio repositório
(`tools/synth_audio.py`). Sem dependência externa, sem licença de terceiros.

## Key art e referência de personagem

- `assets/art/key_art.jpg` — imagem gerada por IA para o ecrã de título.
- `assets/art/kael_reference.jpg` — folha de personagem do Kael, **fornecida pelo
  dono do projeto** (uso exclusivo deste repositório; não redistribuir).
  Ver `docs/CHARACTER.md` para a leitura visual e o plano de fidelidade total.
- `assets/art/portraits/*.jpg` + `*_face.jpg` — folhas de personagem e recortes
  «bust» do elenco, **gerados por IA** (v1.2) a partir da mesma referência e
  dos mesmos prompts próprios (estilo: dark fantasy character sheet, line art
  sobre cel-shading, paleta carvão/umber). Mesmos termos do Kael reference —
  uso exclusivo deste repositório; não redistribuir. Registo e estado:
  `docs/CHARACTER.md` («Elenco — retratos»).

## Créditos

- **Kay Lousberg** — [KayKit Game Assets](https://kaylousberg.itch.io/)
  (personagens e mundo medieval, CC0).
- **Quaternius** — Ultimate Animated Animal Pack (o lobo), CC0 — https://quaternius.com
- **Gobkit / Alsomind Tech** — Nature Kit de vegetação, CC0 — https://gobkit.com
  (mirror: `Ariescar/gobkit-free-assets`)
- Motor: **Godot Engine** (MIT) — https://godotengine.org

## Medidas medidas (v1.10) — extents em unidades GLTF (pré-escala)

Medidas por análise do accessor (min/max) dos glTFs envolvidos;
1 unidade GLTF = 1 u. In-game = medida × escala de cena.

| Modelo | x × z (footprint) | altura | escala pre-v1.10 | escala v1.10 |
|---|---|---|---|---|
| building_home_A | 0.79 × 0.93 | 0.85 | 0.62 (≈0.53 m) | 2.95 (≈2.5 m) |
| building_home_B | 0.87 × 1.28 | 1.10 | 0.62 (≈0.68 m) | 2.40 (≈2.6 m) |
| building_tavern_red | 1.17 × 1.40 | 1.33 | 0.62 (≈0.82 m) | 2.10 (≈2.8 m) |
| building_blacksmith_red | 1.29 × 0.99 | 1.25 | 0.62 (≈0.78 m) | 2.15 (≈2.7 m) |
| building_church_yellow | 1.03 × 1.65 | 1.16 | 0.66–0.72 (≈0.8 m) | 2.30 (≈2.7 m) |
| building_market_yellow | 1.80 × 0.98 | 1.32 | 0.62 (≈0.82 m) | 2.15 (≈2.8 m) |
| building_well_yellow | 0.65 × 0.83 | 0.75 | 0.5–0.7 (≈0.4 m) | 2.30 (≈1.7 m) |
| building_tower_A_yellow | 0.99 × 2.19 | 1.15 | 1.2–0.95 (≈1.1–1.4 m) | 2.60 (≈3.0 m) |
| building_castle_yellow | 1.98 × 3.98 | 2.26 | 1.55 (≈3.5 m) | 3.00 (≈6.8 m) |
| wall_straight | 2.00 × 0.80 | 1.10 | 2.8 (≈3.1 m) | (intacto) |
| wall_straight_gate | 2.00 × 0.90 | 1.41 | 2.6 (≈3.7 m) | (intacto) |
| fence_wood_straight | 0.10 × 1.15 | 0.55 | 0.85 (≈0.47 m) | (intacto) |
| tent | 0.52 × 0.52 | 0.52 | 0.95 (≈0.49 m) | (intacto) |

Notas: os colisores invisíveis nunca mudaram (eram a âncora correta); as
escalas antigas eram artefactos do «0.6 de partida». `anvil.gltf` **não
existe** e deixou de ser referenciado (bigorna procedural no lugar).
