# Roadmap — A Academia do Zero

Do vertical slice ao jogo completo, em fases jogáveis. Cada fase fecha com uma
versão testável (sideloading / itch.io) antes da seguinte começar.

## v0.1 — Vertical Slice ✅ (esta entrega)
Vila de Noro, Floresta Baixa, Estrada Imperial, Portão da Academia e Arena.
Missão principal completa + 2 secundárias, combate com parry/postura/Ruptura,
8 atributos, Sistema v0.1 (Sala Branca + avaliação), save/load, 3 finais.

## v0.2 — Fundamentos de combate e sensação ("game feel") — parcial ✅
- [x] **Animações esqueléticas**: personagens e humanoides por modelos KayKit (CC0) —
      KayKit Adventures (Kael = Rogue Hooded, Salteador/Mago/Guardião = Barbarian/Mage
      tintados) com Idle/Walking/Running, ataques, block, dodge, hit e morte; NPCs
      animados; canal de conjuração interruptível do Mago de Cinza.
- [x] **Game feel básico**: screen shake, partículas de impacto, números de dano
      flutuantes, *hit-flash* branco, hit-stop ainda por fazer.
- [x] **Mundo com modelos**: KayKit Medieval Hexagon (CC0) — edifícios, muralha da
      Academia, montanhas, árvores e props + vegetação baixa gobkit (CC0).
- [x] **Lobo esquelético** (Quaternius Ultimate Animated Animals, CC0).
- [x] Correções de robustez (identificadores não declarados → script de inimigos não
      compilava; reset do estado de morte do jogador).
- [x] Hit-stop em acertos (~90–130 ms) e câmara com spring-arm real (raycast
      com colisão + proximidade suavizada) — verificado no código.
- [x] Cancelamento de movimento por ataque: atacar durante a esquiva
      encurta-a e entra já em golpe (game cancel).
- [x] Técnicas desbloqueáveis iniciais: `Passo Vazio` (1.ª Ruptura),
      `Queda do Colosso` (3.ª Ruptura), `Corrida do Predador` (Nv 8) —
      teclas V/C/Z, recargas, slots próprios no HUD, notificação de
      desbloqueio. (cap 11 do sec. 10 ainda longe)
- [x] **Combos aéreos**: salto (X / D-pad cima), ataques no ar com +25% dano
      e +50% postura; ataque pesado no ar prepara a *Queda* (slam de queda):
      explosão AoE à aterragem (3.1 m, 24 de dano + 42 de postura) — tudo
      ajustável em `balance.json` (secção `jump`). Botão SALTO no Android.
- [ ] Restantes técnicas do sec. 10 (cap 11): Impacto de Quebra, Respiração
      de Ferro, Reflexo Instintivo, Sequência de Ruptura.
- [x] IA com coordenação básica — guarda-costas (Salteador↔Mago) e flanqueamento em lados
      opostos (v0.2, após auditoria — ver docs/AUDIT.md).
- [x] Gamepad completo + dificuldade Casual/Normal/Pesadelo persistida no save.
- [x] **Android**: controlos táteis (joystick + câmara por arrasto + botões), landscape,
      export preset — alvo: gama alta (escolha do dono). iOS fica para quando houver Mac/Xcode.
- [x] Hit-stop em acertos (~90–130 ms).
- [x] Lock-on com troca suave: Tab cicla para o próximo inimigo mais
      próximo; duplo toque larga o alvo; alvo morto/distante é largado
      automaticamente. (Câmara dinâmica fica por fazer.)
- [x] Música dinâmica por intensidade (exploração → perigo → combate) — v1.0: modos exploração/combate/Sistema, transição por proximidade de inimigos.

## v0.3 — O Sistema completo (sec. 11 do GDD)
- Ambientes: Floresta, Deserto, Montanha, Vulcão, Oceano, Cidade, Abismo, Arena
  (geração procedural por arena).
- Configuração de simulação: tipo de inimigo, nível, quantidade, regras,
  tempo limite, presença de cura.
- Níveis de ameaça (Básico → Impossível) e avaliação completa
  (reação, precisão, parries, erros repetidos, estilo dominante).
- Personalidade emergente do Sistema (perguntas, recusas, memórias).

## v0.4 — A Academia Real de Veyra (sec. 12–14 do GDD)
- Mapa completo da academia: pátio, biblioteca, dormitórios, arena, laboratórios,
  jardim mágico, torre dos professores, Arquivo Proibido, túneis.
- As quatro faculdades (Forja, Véu, Raiz, Horizonte) + divisão especial.
- Aulas e provas (Prova da Floresta, Prova de Duelo, Prova de Equipas,
  Labirinto Arcano) como fases jogáveis completas.
- Elenco principal: Liora, Bram, Sena, Iven (companions com habilidades reais).

## v0.5 — Mundo aberto: as 6 regiões restantes (sec. 14–16)
Vale de Noro (polido) → Floresta de Ruun → Deserto de Sahr → Montanhas de Khar
→ Arquipélago de Lume → Ilhas de Aer → Abismo de Orun.
Streaming [~] — medição: ~91 instâncias de decoração no mundo principal;
culling por distância **nativo** (`visibility_range_end = 55 m`) na flora —
não desenha o que está longe, física intacta; **grid cells completos
adiados** (custo≫benefício a este tamanho; reabrir se o mundo crescer
≥5×); clima dinâmico [x] (tempestade
sorteada à chegada — 30% — com **chuva visível** (GPUParticles3D de 900 gotas
que acompanham o jogador), **relâmpagos com trovoada** (flash de sol/ambiente
+ wav sintetizado) e névoa reforçada); ciclo dia/noite [x]; NPCs com rotinas
[x] (vagueio em anel de 3 pontos; **desvio de obstáculos por leque de raios**
±40°/±80°/±120° — não é A*/navmesh, mas não atravessam props/muros;
quest-givers enraizados); viagem rápida [x] por faróis.

## v0.6 — Sistemas de RPG profundos (sec. 17, 18, 26–29)
- Facções com reputação, missões e traições (Conselho Imperial, Irmandade do
  Vácuo, Ordem da Cinza, Arquivistas...).
- ✅ Forja do Garr (2026-11-06): poções e Bálsamo de Salvação por Fibras de
  Ruína + marcos; têmpera da lâmina (150 marcos, +12% dano permanente).
- Relações e romances com memória de ações (mentir, proteger, quebrar promessas).
- Economia + fabrico (poções, pregos de ruptura, planadores, peças de barco).
- [x] **Lesões persistentes** (2026-11-06): 0–2 níveis por golpe grave (≥25% da vida);
      penalizações escalonadas (dano/velocidade/recuperação de fôlego); repouso
      alivia 1 nível; Bálsamo de Salvação cura tudo; persistido no save.
- [x] **Treino com mestres** (sec. 8, 2026-11-06): Mestre Dario — 120 marcos → +1
      ponto de atributo e +1 fadiga (máx 3); fadiga bloqueia o treino até descansar
      (travão anti-grind do GDD). Verificado headless (19/19).
- [x] **Medicamentos/curandeiro** (sec. 8, 2026-11-06): Remendo do curandeiro —
      45 marcos, −1 nível de lesão (loja do Garr; guarda de marcos
      `try_spend_marcos`). Cura total continua a ser o Bálsamo de Salvação.
- [ ] Romances com memória de ações (mentir/proteger/quebrar promessas).

## v0.7 — Política e finais (sec. 23–25) ✅
Os grandes objetivos (rei, governador, comandante, diretor, líder, explorador,
conquistador, herói, caminho secreto) como **meta-quests reais** com
consequências acumuladas — nunca como opções de menu. Finais diferenciados
por reputação, decisões e estado do mundo.

- [x] 6 finais: 3 base (Academia / Vagabundo / Revolta) + 3 por reputação
      (O Regente do Norte — Imperial 40+, O Guardião do Arquivo — Arquivistas
      40+, O Lugar-Vazio — Irmandade 40+).
- [x] Finais bloqueados mostram requisito e progresso; decisão com consequências
      acumuladas ao longo do jogo (reputação, avaliações, finais anteriores).
- [x] Epílogos de romance por companheiro (Liora, Bram, Sena, Iven) anexados ao
      final, persistidos save-side.
- [ ] Meta-quests com estado de mundo persistido entre regiões (dragão da
      Ferida, golpe da Custódia) — consequência global completa adiada para
      pós-v1.0 (sec. 23).

## v1.0 — Qualidade, acessibilidade e lançamento (sec. 32–34) — parcial ✅
- [x] **Remapeamento de controlos** completo: menu de CONTROLOS com captura
      de tecla/rato/gamepad por ação, Esc cancela, «Repor predefinições»,
      persistido no save (v2) e aplicado no arranque/carregar/reiniciar.
- [x] **Legendas** com escala 80/100/125/150 % (diálogos + prompts).
- [x] **Daltonismo**: Okabe-Ito para protanopia / deuteranopia / tritanopia;
      recolore as barras de vida/fôlego/Ruptura; persistido no save.
- [x] **Dificuldades** Casual/Normal/Pesadelo a partir de
      `src/balance/balance.json` (dano recebido, vida inimiga, mult. XP).
- [x] **Balanceamento data-driven**: XP por nível, dano/vida/fôlego por
      atributo, poção — `Balance` autoload com fallback seguro.
- [x] **Música dinâmica** (3 temas sintetizados: exploração / combate /
      Sistema) + interruptor no menu de pausa; save corruption-proofing
      já existia (sha256 + .tmp atómico + .bak).
- [x] **Localização — andaime** (2026-11-06): `tools/l10n_extract.py` +
      `docs/l10n/strings_pt.csv` + `docs/LOCALIZATION.md`.
- [x] **Localização em runtime PT/EN/ES** (2026-11-07): `tr()` em ~110 sítios,
      troca no arranque + no ecrã de título (PT→EN→ES, persistida no save),
      421 chaves EN+ES completas (`l10n/game.csv`), gate `validate.py` [5/5]
      no CI, seleção de idioma no título com reload uniforme.
      Ver `docs/LOCALIZATION.md` e `docs/AUDIT.md` §15.
- [x] **Engine executada neste ambiente**: Godot 4.7.2 compilado do
      código-fonte (headless linuxbsd); 5 cenas em smoke boot limpas; 11
      24 asserções de jogabilidade verdes (save/load, XP, técnicas, combate
      real, salto/ataques aéreos/slam de queda) + fluxos completos (Sala
      Branca → avaliação; Prova de Duelo → Bram). Ver `docs/BUILD.md` e
      `docs/AUDIT.md` §9.
- [x] Assistência de mira suave nos ataques corpo a corpo (o corpo vira
      para o alvo mais próximo ao alcance — desligável na pausa).
- [x] **Narração de menus** (2026-11-06): TTS do sistema ligável na pausa,
      **por botão** (foco/hover em menus, diálogos e viagem rápida, partilhado
      por `GameState.tts_say`) e **com escolha de voz** — botão
      «Narração — voz (⟳)» na pausa percorre Auto → vozes do sistema
      (`cycle_tts_voice`), escolhida via `tts_voice` no save.
- [ ] Testes com jogadores reais (algo que este repositório ainda não pode
      fazer).
- [x] Traduções EN/ES e troca de idioma em runtime (2026-11-07, 421/421;
      QA por falante nativo e revisão visual em F5 continuam por fazer).
- [~] **Sonda de performance** criada (`tools/perf_probe.tscn`, headless,
      CPU-side: ms de frame/física, memória estática, objetos/nós/órfãos).
      Medição em hardware real (GPU/LOD/draw calls) continua em aberto —
      exige F5 numa máquina com os drivers do alvo (Android).
- [ ] Meta-quests globais completas (ver v0.7).
