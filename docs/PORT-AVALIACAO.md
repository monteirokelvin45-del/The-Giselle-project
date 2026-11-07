# Avaliação de motores — Godot vs Unity vs Unreal para «A Academia do Zero»

Triagem honesta pedida pelo dono. Nenhum binário de motor foi instalado ou
pode ser instalado neste ambiente (ver §6). Objetivo: decidir com os factos
à mesa, não com entusiasmo de engine.

## 1. Contexto concreto deste projeto (o que está na mesa)

| Facto do repositório | Implicação no processo de escolha |
|---|---|
| Jogo single-player **offline**, GLES3, APK Android como alvo | Fora do baralho as tecnologias online/serviços obrigatórios — todas as três servem offline; diferenças são de peso |
| **1 pessoa**, tempo parcial, passo a passo com gates (gdparse/validate/CI/F5) | Custo fixo de aprendizagem e pipeline manda mais do que features de render |
| ZERO assets externos que não sejam CC0/CC-BY (KayKit 3D/animações) | Assets movem-se; a lógica não — a reescrita é o preço |
| Godot 4.2+ (Standard), autoloads (`Balance/GameState/Audio/UI/...`), 475 chaves i18n, save com checksum, CI headless verde (13/13) | Port = re-autorar tudo isso e re-provar tudo; ~6 semanas-pessoa realistas, não um «export» |
| Estilo gráfico: low-poly stylized, ZERO fotorrealismo | O renderer pesado do Unreal não acrescenta nada aqui |

## 2. Tabela comparativa (para ESTE jogo, não em abstrato)

| | **Godot 4.2+ (atual)** | **Unity 6 LTS** | **Unreal Engine 5** |
|---|---|---|---|
| Licença | MIT — €0 sempre, sem royalties, sem limites de receita | Personal grátis com limites de receita (limiar público; rever em unity.com), planos pagos acima; histórico 2023 «Runtime Fee» revertido em 2024 — fricção de confiança real | Grátis a €0 até ~US$1M de receita/produto, depois royalty (~5%, com exceções via Epic Games Store — rever EULA); precisa conta Epic sempre |
| Build Android/GLES | Suporte nativo, APK pequeno (~30–50 MB), CI headless em GitHub Actions **já verde** (`headless_check`, i18n, asserts, stress) | Nativo; Universal RP para GLES3; CI requer licença ativada no runner (`game-ci`, segredos `UNITY_LICENSE`) — mais fricção, mais minutos | Export Android suportado mas é caminho secundari; engine pensada para PC/consola; APK pesado; aparelhos Android fracos-alvo mal servidos |
| Linguagem | GDScript (dinâmico, rápido iterar) + C# opcional + GDExtension (C++/Rust) | C# (.NET) + Unity Burst/Jobs opcional | C++ + Blueprints (visual) |
| Peso para desenvolver neste estilo | Leve: projeto abre em segundos; `.tscn` diffáveis; cabem no Git | Médio: cena/yaml funciona no Git, mas Library/Cache megas e importadores pesados | Pesado: 20–60 GB de instalação + SSD/NVMe, 32 GB+ RAM confortáveis, tempos de shader/build |
| Qualidade de render neste estilo | Suficiente e bonita (baked lighting, SDFGI opcional) com GLES3 | URP/Lit: bom para estilizado | O melhor dos três — inutilizável de graça para o nosso scope (Lumen/Nanite exigem hardware) |
| Exportar e testar | APK único; jogou em aparelho modesto | Idem, mais pesado | Do APK ao telemóvel: o processo existe, mas o alvo Android não é onde a UE brilha |
| Código aberto / auto-hospedável | **Sim** (fonte + binários) — CI completo ao teu controlo | Não (UnityCsReference público é espelho parcial, não o editor) | Fonte acessível a contas aprovadas (link Epic), binário grande |
| Console | Via terceiras partes (W4 Games) — **pontos fracos conhecidos** | Suporte oficial via processo com Unity | Suporte oficial first-class |
| Comunidade para dev solo estético low-poly | Grande e ativa (Godot) | Enorme | Enorme — mas orientada a AAAs/PC |

## 3. O que um port custaria, item a item (honestidade, não marketing)

| Artefacto no Giselle hoje | Portável como está? | Custo real de port |
|---|---|---|
| Modelos/animações GLB KayKit (CC0) | **Sim** — glTF é glTF em qualquer motor | Importar e re-configurar; minutos por modelo |
| `l10n/game.csv` (475 chaves, PT/EN/ES) | **Formatos sim, tooling não** | Manter CSV + reescrever importer (validate.py é Python próprio → re-autorar para pipeline Unity/Unreal) |
| `src/` — 9.502 linhas GDScript (src/ + tools/, contado em 2026-11-07) — combat, IA, Sistema/Ruptura, UI, mundo, dia/noite, spawns | **Não** — reescrever em C#/C++ ou Blueprints | Semanas–meses; bugs de regressão garantidos; toda a lógica de jogo muda de língua |
| `.tscn` (11 cenas — 5 detetadas pelo boot + 6 de composição/instância) | **Não** — re-autorar cenas (UI Canvas, prefabs) | Dias |
| Autoloads e `Balance/GameState` (singletons + JSON) | **Não**, mas é fácil de recriar (JSON parsing nativo) | Dias |
| Save com checksum + migrações versionadas | Padrão replicável | Dias |
| `tools/` (gdparse, validate, headless smoke, stress) | **Perdidos** — o gate CI tal qual não existe | Re-construir: Unity CI com licença, ou Unreal CI com binários grandes; meses de pipeline |
| Áudio sintetizado (`synth_*.py`), SFX | Neutro (ficheiros OGG/WAV exportam) | Horas |
| Docs (GDD, AUDIT, PERF) | Sim (Markdown é Markdown) | Nulo |

Conclusão prática: **um port é um re-build com dívida zero no dia 1 e dívida
toda no dia 2.** Nada no Giselle depende de uma limitação do Godot; o
jogo inteiro foi desenhado dentro dele.

## 4. O que o Giselle ganharia em Unity/Unreal — e o que perderia

**Ganhando (Unity):** ecossistema de Asset Store para protótipos,
menos atrito para merch/console mais tarde, C# com mais biblioteca
estática, equipas com experiência Unity são as mais comuns no mercado.
**Ganhando (Unreal):** renderer/cinemáticas inigualáveis, Blueprints
para prototipar lógica visual, suporte console oficial de primeira.

**Perdendo (qualquer dos dois):** custo zero, CI atual verde, APK leve,
MIT/licença sem royalties nem limites, tempos de iteração em segundos,
pipeline de texto puro que vive no Git, e a certeza de que nada aqui
pode deixar de funcionar por decisão comercial de terceiros. O
«gratuito para sempre» do Godot não é uma vantagem romântica — é um
arquiteto de risco: este jogo vai lançar num telemóvel Android, offline,
de um rapazo sem equipa.

## 5. Recomendação

**Continuar em Godot 4.2+ (Standard, GLES3) para o Giselle, v1.x e v2.x.**
Só reevaliar se aparecer um gatilho real:

- Alvo de **consola** oficial ou publicadora que o exija → Unity (ou
  W4/GDExtension no Godot, se houver verba para o pipeline);
- **Equipa ≥ 3** ou necessidade de genéricos .NET para o gameplay → Unity;
- Barra visual a subir para fotorrealista/cinemático → esse port é o
  projeto **novo**, assume-se como tal, não se faz «migração» em cima do
  v1.7;
- Qualquer outro motivo não listado → não compensa.

Se quiseres experimentar os dois na tua máquina por curiosidade (sem tocar
no projeto), os passos oficiais são: Unity Hub em unity.com/download
(Unity 6 LTS) e Epic Games Launcher em unrealengine.com/download (conta
Epic obrigatória; ~30–60 GB; recomendado SSD + 32 GB de RAM) — ambos
instalam-se localmente, nada passa por este repositório.

## 6. Factos sobre este ambiente (por que nada foi descarregado aqui)

- Rede limitada a `github.com`, `api.github.com`, `codeload.github.com`,
  `registry.npmjs.org`, `pypi.org`, `files.pythonhosted.org`; os hosts
  `unity.com`/`epicgames.com`/`download.unity3d.com` devolvem `000`
  (inalcançáveis), verificado em 2026-11-07.
- O Unreal no GitHub não é público (repo privado de contas ligadas ao
  Epic) — `gh api repos/EpicGames/UnrealEngine` devolve HTTP 404.
- O sandbox tem ~20 GB de disco, 3.9 GB de RAM e 2 vCPUs — demasiado
  pequeno para o Unreal; desproporcionado para o Unity; e instalar nada
  aqui mexe com onde TU vais jogar/desenvolver (a tua máquina).
- O único artefacto Unity alcançável de forma legítima é o
  `Unity-Technologies/UnityCsReference` (espelho C# de referência; ~13k★
  no GitHub) — útil para leitura atenta, não é o editor nem é o jogo.

## 7. Veredito numa linha

O Giselle não tem dívida de motor — tem roadmap (Elementos), gates verdes
e um dono com F5. Mudar agora de motor seria resposta a um problema que
não existe. Volte a esta triagem apenas se/quando um dos gatilhos do §5
acontecer.
