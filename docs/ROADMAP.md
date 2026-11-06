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
- [ ] Combos aéreos e as restantes técnicas do sec. 10 (cap 11).
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
Streaming de mundo (grid cells) [ ] por fazer; clima dinâmico [x] (tempestade
por região — névoa/luz/ambente; ainda sem chuva visível); ciclo dia/noite
[x]; NPCs com rotinas [x] (vagueio simples em anel de 3 pontos; sem
pathfinding — podem roçar props; quest-givers enraizados); viagem rápida [x]
por faróis.

## v0.6 — Sistemas de RPG profundos (sec. 17, 18, 26–29)
- Facções com reputação, missões e traições (Conselho Imperial, Irmandade do
  Vácuo, Ordem da Cinza, Arquivistas...).
- ✅ Forja do Garr (2026-11-06): poções e Bálsamo de Salvação por Fibras de
  Ruína + marcos; têmpera da lâmina (150 marcos, +12% dano permanente).
- Relações e romances com memória de ações (mentir, proteger, quebrar promessas).
- Economia + fabrico (poções, pregos de ruptura, planadores, peças de barco).
- Lesões persistentes e recuperação; treino com mestres (sec. 8).

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
- [x] **Localização — andaime**: `tools/l10n_extract.py` +
      `docs/l10n/strings_pt.csv` (405 strings) + `docs/LOCALIZATION.md`.
- [x] Assistência de mira suave nos ataques corpo a corpo (o corpo vira
      para o alvo mais próximo ao alcance — desligável na pausa).
- [~] Narração de menus: as notificações são lidas por TTS do sistema
      (desligável na pausa); ainda não há narração incremental por botão
      nem escolha de voz.
- [ ] Testes com jogadores reais (algo que este repositório ainda não pode
      fazer).
- [ ] Traduções EN/ES (o runtime ainda não troca de idioma — ver
      docs/LOCALIZATION.md).
- [ ] Performance medida (LOD, draw calls, profiling em hardware real).
- [ ] Meta-quests globais completas (ver v0.7).
