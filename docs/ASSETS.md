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
| Kael Noro (jogador) | `Rogue_Hooded.glb` | tintura branca (original) |
| Salteador de Ruína | `Barbarian.glb` | tintura avermelhada, escala 1.05 |
| Mago de Cinza | `Mage.glb` | tintura violeta |
| Guardião da Prova | `Barbarian.glb` | tintura de pedra, escala 2.3 |
| Elen Noro (mãe) | `Mage.glb` | tintura esverdeada, escala 0.95 |
| Garr (ferreiro) | `Barbarian.glb` | tintura quente |
| Tomás (aldeão) | `Rogue.glb` | tintura esverdeada |
| Liora Venn | `Mage.glb` | tintura dourada/branca |
| Mestre Dario Vale | `Knight.glb` | tintura azul-aço, escala 1.1 |
| Lobo de Cinza | *(procedural)* | não há lobo CC0 adequado nos packs; mantém-se primitivos |

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

## Áudio

`assets/audio/*.wav` — efeitos sintetizados no próprio repositório
(`tools/synth_audio.py`). Sem dependência externa, sem licença de terceiros.

## Key art

`assets/art/key_art.jpg` — imagem gerada por IA para o ecrã de título.

## Créditos

- **Kay Lousberg** — [KayKit Game Assets](https://kaylousberg.itch.io/)
  (personagens e mundo medieval, CC0).
- Motor: **Godot Engine** (MIT) — https://godotengine.org
