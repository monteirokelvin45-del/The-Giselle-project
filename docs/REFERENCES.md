# Referências e fontes — inventário e veredictos

Catálogo de todos os repositórios indicados pelo dono do projeto, com o veredicto
de uso **neste projeto**. Regra geral: **código de engines/codebases não pode ser
usado** (Godot continua a ser o motor; referências de Unity/UE são só design);
assets só entram com licença CC0/CC-BY compatível; curadorias são mapas, não assets.

Legenda: ✅ usado · 🎨 referência de design · 🗺️ curadoria (mapa de links) · ⚠️ risco/condições · ❌ não usar

## Assets integrados (✅)

| Repositório | Licença | O que levámos | Onde |
|---|---|---|---|
| `KayKit-Game-Assets` (org) — `KayKit-Character-Pack-Adventures-1.0` | CC0-1.0 | 5 personagens GLB (Barbarian, Knight, Mage, Rogue, Rogue_Hooded) com 76 clipes | `assets/models/characters/` |
| `KayKit-Game-Assets` — `KayKit-Medieval-Hexagon-Pack-1.0` | CC0-1.0 | 36 modelos (edifícios, muralha/gate, árvores, rochas, montanhas, props) | `assets/models/env/` |
| `Papyszoo/CC0-Public-Domain-Models` — `packs/quaternius-ultimateanimatedanimals` | CC0-1.0 (pack: "license":"CC0") | `wolf.glb` — **Lobo esquelético** (Atk/Idle/Walk/Gallop/Death/HitReact…) | `assets/models/creatures/wolf.glb` |
| `Ariescar/gobkit-free-assets` | CC0-1.0 (LICENSE no repo) | Nature kit estático: uso de Grass×3, Bush×2, Cliff×3 | `assets/models/nature/` |

Notas: dono original do lobo é **Quaternius** (Ultimate Animated Animal Pack);
o Papyszoo é um mirror CC0 curado (4,1 GB — só subpastas individuais foram lidas,
nunca o repo inteiro). O wolf.glb traz 12 clipes (153 canais cada) e materiais
untextured (baseColorFactor) — não precisa de atlas externo.

## Inspecionados e preteridos (com motivo)

| Repositório | Veredicto | Motivo |
|---|---|---|
| `SkywolfGameStudios/CC0Tree` | ❌ | 61 modelos só em **FBX** — Godot 4 não importa FBX nativamente; 3 árvores não justificam pipeline de conversão |
| `GeorgeQLe/assets-kaykit-3d-characters` | ❌ | Sem campo de licença no repo; é re-host do KayKit — redundante com a fonte oficial |
| `3dassets-dev/3dassets` | ❌ | 89 KB — registry/skill de agente, não contém modelos utilizáveis |
| `Ariescar/gobkit-free-assets` — minions/animals | ⚠️ não agora | Animações num único track "movement"/"clip" (12–48 canais, sem clipes separados por nome) + estilo cartoon destoante; natureza serviu. Pode voltar se quisermos inimigos chibi |
| `Papyszoo/CC0-Public-Domain-Models` (resto) | 🗺️ reserva | 100+ packs CC0 (Kenney, Quaternius, KayKit, Poly Haven, The Base Mesh). Úteis para futuros alvos (ex.: `the-base-mesh` como base do Kael à medida no Blender) |
| `Hybridherbst/awesome-3d-assets` | ❌ não existe | **404 verificado na API** — o dono indicou que seria a correção; o nome correto verificado é `glbkit-tools/awesome-3d-assets` (em "Curadorias") |
| `glbkit-tools/awesome-3d-assets` | 🗺️ mantido | O dono incluiu-o explicitamente na "lista limpa e verificada"; é apenas uma lista de links (24 KB), sem código executável. Os repos `glbkit-labs/*`, `glbkit-dev/*`, `glbkit/*`, `glbkit-com/*` foram **explicitamente excluídos pelo dono** e não são usados |

## Referências de design/engine (🎨 — código não é portável/licenciável para este projeto)

| Repositório | O que aproveitar |
|---|---|
| `godotengine/godot-demo-projects`, `godotengine/tps-demo` | Padrões oficiais: CharacterBody3D TPS, nav/camadas, cena principal, input map |
| `gdquest-demos/godot-open-rpg`, `Loten-Labs/godot-open-rpg` | Estrutura de RPG aberto (eventos, mundo por código, ciclo de jogo) — ambos Godot 4 |
| `Ali0600/rpg-template` | Template leve de RPG Godot 4 (inventário/atributos/menus) |
| `SummerEngine/template-3d-open-world-explore-tps` | Estrutura de cena TPS de mundo aberto (quest markers, exploração) |
| `SlashScreen/skelerealms` | Sistema de mundo procedural/história emergente (C++/Godot híbrido) — inspirar camadas de simulação |
| `unfa/liblast`, `belzecue/liblast-framework` | Last Bastion: arquitetura de open-world C++/Godot, streaming simples |
| `Quaint-Studios/Reia` | RPG narrativo em Godot — diálogos, eventos do mundo |
| `openfw-game/OpenLiberty` | Open world Godot — ferramentas de cidade/tráfego (layout, não assets) |
| `v-sekai/v-sekai-game`, `v-sekai/godot-vrm` | **VRM em Godot**: caminho concreto para Kael à medida via VRoid Studio (que o dono tem na lista de arte) → godot-vrm importa o .vrm no projeto sem Blender. Alternativa ao plano Blender em `docs/CHARACTER.md` |
| `veloren/veloren` | Mundo aberto RPG voxel — **assets CC-BY-SA 3.0 / código GPL: não copiar nada**; só padrões de design (progressão, npcs, facções) |
| `0ad/0ad` | RTS open source — padrões de campanha/IA; fora do nosso género |

Notas: o user marcou os repos glbkit/* não-listados como não confiáveis — respeitado.
O link huggingface anterior continua **excluído** por instrução do dono.

## Curadorias (🗺️ — mapas de links, não conteúdo)

| Repositório | Utilidade |
|---|---|
| `madjin/awesome-cc0` | Melhor ponto de partida para CC0 (inclui Kenney, Quaternius, KayKit…) |
| `glbkit-tools/awesome-3d-assets` | Lista de modelos/texturas/HDRIs gratuitos (verificado que existe; sem código) |
| `veldenbg/Gamedev-Free-Resources`, `teamgravitydev/gamedev-free-resources`, `TMHSDigital/Free-Game-Dev-Assets`, `devanshutak25/3d-resources` | Listas gerais de assets gratuitos; cruzar licenças caso a caso |
| `michelpereira/awesome-open-source-games`, `kavex/gamedev-resources` | Jogos open source completos para estudar estrutura |
| `juliettef/awesome-gamedev`, `calinou/awesome-gamedev`, `Calinou/awesome-godot` | Meta-listas Godot/engine; Calinou tem a secção Godot mais cuidada |

## Notas de ambiente (rede)

- Hosts permitidos: `github.com`, `api.github.com`, `codeload.github.com`,
  `pypi.org`, `files.pythonhosted.org`, `registry.npmjs.org`.
- **`raw.githubusercontent.com` não funciona** (respostas vazias). Para ficheiros
  >1 MB: `curl -H "Accept: application/vnd.github.raw" https://api.github.com/repos/<o>/<r>/contents/<path>`
  funciona e devolve o binário (foi como o `wolf.glb` de 1,9 MB foi obtido).
- Tarballs `codeload` funcionam para repos pequenos (KayKit, gobkit).

## O que NÃO entra neste projeto (e porquê)

- **Unity/UE code** (MooaToon, shaders de `Delt06`, `AnyRPGCore`, `Skybound`,
  `OpenMMORPG`) — engines externas; só design.
- **KayKit Dungeon Remastered** — estava na lista inicial mas saiu na lista limpa;
  não foi utilizado.
- **Veloren assets** — CC-BY-SA "share-alike" contamina a licença do nosso conteúdo.
- **FBX-only packs** (CC0Tree) — Godot 4 sem importador FBX.
- Qualquer modelo sem licença explícita (GeorgeQLe) ou com pipeline de agente
  acoplado (3dassets-dev).
