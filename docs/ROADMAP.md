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
      Academia, montanhas, árvores e props.
- [x] Correções de robustez (identificadores não declarados → script de inimigos não
      compilava; reset do estado de morte do jogador).
- [ ] Cancelamento de movimento por ataque, hit-stop, câmara com spring-arm real.
- [ ] Combos aéreos, `Queda do Colosso`, `Corrida do Predador`, `Passo Vazio` como
      técnicas desbloqueáveis (cap 11, sec. 10 do GDD).
- [ ] IA com coordenação básica (conjurador + tanque protegem-se; assassino flanqueia).
- [ ] Lock-on com troca suave de alvo e câmara dinâmica.
- [ ] Música dinâmica por intensidade (exploração → perigo → combate).

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
Streaming de mundo (grid cells), clima dinâmico, ciclo dia/noite, NPCs com
rotinas, viagem rápida por faróis.

## v0.6 — Sistemas de RPG profundos (sec. 17, 18, 26–29)
- Facções com reputação, missões e traições (Conselho Imperial, Irmandade do
  Vácuo, Ordem da Cinza, Arquivistas...).
- Relações e romances com memória de ações (mentir, proteger, quebrar promessas).
- Economia + fabrico (poções, pregos de ruptura, planadores, peças de barco).
- Lesões persistentes e recuperação; treino com mestres (sec. 8).

## v0.7 — Política e finais (sec. 23–25)
Os grandes objetivos (rei, governador, comandante, diretor, líder, explorador,
conquistador, herói, caminho secreto) como **meta-quests reais** com
consequências acumuladas — nunca como opções de menu. Finais diferenciados
por reputação, decisões e estado do mundo.

## v1.0 — Qualidade, acessibilidade e lançamento (sec. 32–34)
- Acessibilidade completa: remapeamento, legendas, daltonismo, assistência de
  mira, dificuldades, narração de menus.
- Testes com jogadores reais (algo que este repositório ainda não pode fazer).
- Performance (streaming, LOD, draw calls), save corruption-proofing,
  localização (PT/EN/ES).
