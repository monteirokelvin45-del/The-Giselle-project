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
