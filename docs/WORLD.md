# WORLD — composição de mapas v1.0 (2026-11-07)

**Regra do dono (2026-11-07):** «todos os mapas com alta qualidade floresta,
tudo mesmo» → escopo = **tudo** (Vale, Academia, as 6 expedições);
qualidade = densidade/atmosfera **+ POIs jogáveis**; orçamento = densidade
máxima aceite (ciente do risco em Android/GPU).

## Arquitetura
`src/world/map_kit.gd` (novo, original) — compostos partilhados:
anéis de montanha, scatter de rochas/flora/árvores (aros deterministas
`sqrt(r²)`, raio de exclusão do spawn/portal em `(0, 8)`, seeds fixas),
e POIs originais (`engineer_ruins`, `obelisk`, `tent_camp`, `watchtower`,
`lighthouse`, `abyss_altar`, `crack_glow`, `floating_islands`, `sky_arch`,
`dock`, `milestone`, `post`). Vale usa via `world_builder.gd` (`_mk`),
expedições via `region.gd::_compose_biome()` (dispatch por `region_id`),
Academia via `academy.gd::_build_gardens_extra()`.

Colisores só onde importam (árvores grandes, rochas médias/grandes,
paredes/torres/POIs); vegetação baixa e saplings sem colisão (porte felino
do original). Física intacta; é composição visual + geometria de jogo.

## Composição por mapa
| Mapa | Densidade (altura/largura) | POIs | Notas |
|---|---|---|---|
| Vale de Noro | 96 árvores + 38 saplings + 22 rochas + 14 arbustos + 8 marcos de pedra | acampamento abandonado (-17.5, -26) · ruínas dos Engenheiros (15.5, -24) · posto colapsado (6.2, -38) | estrada com marcos; floresta é a vitrine |
| Academia de Veyra | 42 relvas + 12 arbustos + 9 árvores + 6 sebes + 2 braseiros | braseiros da linhagem na porta do castelo | centro do mapa livre (gameplay) |
| **Floresta de Ruun** | **dupla copa (66+34) + 72 relvas + 44 arbustos + 26 rochas + 15 montanhas** | acampamento de salteadores (-19, -13) · templo engolido dos Engenheiros (17, -21) | máxima densidade — a peça pedida |
| Deserto de Sahr | 15 montanhas-dunas + 48 rochas + 16 relvas + 26 arbustos | ruínas-túmulo (16, -17) · obelisco solar (-19, -12, 7 m) · caravana (-9, 15) | |
| Montanhas de Khar | 19 picos de 6–10 m + 52 rochas + 4 escarpas + 22 relvas | posto de vigia (-23, 12) · haste para-raios runada (18, -15, azul) | vale fechado |
| Arquipélago de Lume | 11 silhuetas + 44 rochas + anel de 16 escarpas brancas + 34 relvas | **farol de fósforo azul** (23, -16, alcance 22 m) · doca de pescadores (-14, 14) | «Ilhas de pedra clara e faróis de fósforo azul» (GDD) |
| Ilhas de Aer | 9 ilhas flutuantes invertidas + 30 rochas + 22 relvas | arco do céu partido (17, -14) · mirante (-19, -12) · obelisco espectral (12, -19) | névoa densa + ilhas acima do horizonte |
| Fim do Abismo (Orun) | 38 rochas + 6 ilhas suspensas + 2 obeliscos | **altar do Abismo** (anel de 7 colunas, núcleo de luz ferida) · **fenda incandescente** (30 m) | zero vegetação — mundo morto |

Contagens = estimativas de código (spawns por chamada); medição real
exige F5 no PC/Android do dono (`docs/PLAYTEST.md` §D).

## Limites honestos
- **Sem relevo (HeightMap)**: o chão continua plano em jogo — hills só como
  montanhas/escarpas de perímetro (o jogador nunca caminha em cima). Relevo
  real exige decisão de física (inclinações/gravidade) — fora do escopo.
- **Sem água real**: Lume usa anel de escarpas + farol + neblina turquesa —
  o kit CC0 não tem shader de água; uma água de mentira seria pior.
- **GPUs/Android**: densidade máxima foi a escolha do dono com risco
  conhecido; perfilar com sonda + registar (PLAYTEST §D).
- Look cel v1.0 aplica-se automaticamente a tudo isto (`apply_cel_look`).
- Assets novos: **zero**; tudo KayKit/gobkit CC0 (ver docs/ASSETS.md).

## Ambiente vivo v1.1 (2026-11-07)
Pedido do dono: «coloca cada detalhe mesmo o balançar das árvores, tudo
mesmo». **Tudo com nodes/materiais nativos — zero shaders custom** (GLES3 às
cegas seria irresponsável).

**Vento automático** (`model_factory.spawn_env → _tag_ambience`): relva
balança 3,2°, arbustos 2,2°, árvores/saplings 1,0°; rotação base guardada em
meta e aplicada por frame — nunca acumula. Cada instância tem fase/velocidade
próprias (hash da posição, determinístico).

**`src/world/ambience.gd`** (novo): grupos `sway/bob/spin` processados num
único `_process` (~400+ nós — barato); **bandos de pássaros** em V (3 silhuetas,
órbita + bob vertical); **partículas nativas** por bioma: folhas (Vale/Ruun),
brasa (forja/taverna), vaga-lumes (Ruun), pó (Sahr/Lume), neve (Khar),
nuvens/motes (Aer), motes-violeta (Orun), pétalas (Veyra).

**Detalhes por mapa:**
- Vale: lagoa (água baixa + caniço + nenúfares + doca), corda de roupa com
  4 lençóis, placa da taverna em âmbar, festões da festa do mercado (cones
  coloridos), 2 alvos norte + 1 forja, fachos de luz na mata, bando circular.
- Veyra: 2 mastro de bandeira no castelo, 5 leitos de ervas de Sena
  (nascente), círculo dos novatos (3 alvos), pétalas no pátio e nos jardins,
  bando.
- Ruun: 2 fachos de luz do dossel (aditivos), vaga-lumes, folhas.
- Sahr: **orbe meio-soterrado dos Engenheiros** (metálico, olho turquesa).
- Khar: **cristais energizados** (5 estilhaços emisivos + luz azul) junto à
  haste para-raios + **neve**.
- Lume: **feixe do farol a varrer o horizonte** (lâmina aditiva rotativa).
- Aer: ilhas flutuantes **levitam** (bob 0,7 m, 0,38 rad/s) + nuvem de
  micropartículas.
- Orun: motes-violeta ascendentes; altar estático (o silêncio pesa).

**Verificado:** gdparse 7/7 · validate.py · i18n 460/460 · CI no push
(boot + smoke + flows). **Por medir (F5 do dono):** custo real do vento com
400+ nós animados, partículas em GLES3, e opacidade das lâminas aditivas
(impostura se o blend estiver desligado no driver).
