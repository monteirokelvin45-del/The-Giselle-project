# Kael Noro — referência visual e identidade

A referência de personagem entregue pelo dono do projeto está em
**`assets/art/kael_reference.jpg`** (folha de personagem com vista frente/costas
e painéis de detalhe). Este documento fixa o que a referência descreve e como
isso se traduz no jogo.

## O que a referência mostra

- **Silhueta**: jovem adulto, magro e atlético, de estatura média-alta; postura
  relaxada mas com peso de quem luta (mãos nos bolsos, mas dedos armados).
- **Capa com capuz** preto/cinza-carvão, bainha comprida e esfarrapada atrás,
  presa por broches com correntes e **borlas/pingentes**.
- **Traje monocromático total**: túnica preta, mangas com bandas, braços
  enrolados (faixas), calça cargo larga preta com bolsos cargo e **fitas de
  "tape" cinza-esverdeado** à volta do bolso da coxa e na barra das pernas.
- **Correaria**: cinto grosso com fivela e padrão floral gravado, faixa de
  cordas (sash) na frente, correia transversal, fitas e nós.
- **Botas** pretas de bico largo, sola serrilhada com tarraxes.
- **Paleta** (aprox., lida da folha): quase-preto dos tecidos `#1b1b1e`–`#232326`,
  cinza-carvão da capa `#2e2e33`, cinza médio dos detalhes `#45454d`–`#55555c`,
  cordame/fivela `#6e6a5e`, fita clara da perna `#8f8b7d`.
- **Expressão**: serena, atenta, ligeiramente austera — o "rapaz calmo que
  ouve mais do que fala".

## Como está no jogo hoje

| Camada | Estado |
|---|---|
| Modelo 3D | KayKit **Rogue_Hooded** (CC0), esquelético, ~1.75 m |
| Tintura | carvão escuro (`Color(0.36, 0.35, 0.37)`) para ler como monocromático preto — ver `src/player/player.gd` (`_build_visual`) |
| Capuz | presente no modelo (o design de referência pede capa com capuz; é a peça-chave) |
| Animações | Idle/Walk/Run, combos de combate, bloco/parry, esquiva, hit, morte |

Limitações honestas: a tintura é uniforme — não reproduz a **cinta de tape
cinza-esverdeada**, o padrão floral do cinto, nem as borlas da capa. Um modelo
à medida (retopologia do design, rig, 76+ clipes mapeados) é trabalho de uma
pessoa-semana+ em Blender e está fora do escopo atual; ver ROADMAP.

## Caminho para fidelidade total (futuro)

1. Modelar Kael no Blender a partir da folha de referência.
2. Rigify ou skeleton manual (22–30 ossos) + skin weights.
3. Retargetizar os clipes KayKit (o pack usa esqueleto humanoide padrão) ou
   animar 12–15 clipes-chave.
4. Exportar `Kael.glb` (texturas 2K, atlas único) → substituir o Rogue_Hooded
   em `src/player/player.gd`.
5. Atualizar este ficheiro e `docs/ASSETS.md`.

## Outros usos da referência

- Direção de arte para key art futura (o fundo/vale já aponta para a mesma faixa escura).
- Base para o retrato de perfil no ecrã de decisão final e na página itch.io da demo.

## Elenco — retratos (v1.2, 2026-11-07)

Retratos gerados por IA a partir da folha de referência do Kael (ver acima) —
mesmo estilo (dark fantasy character sheet, line art sobre cel-shading, paleta
carvão/umber), trocando género, roupa, penteado e formato de rosto por
personagem. As folhas completas ficam em `assets/art/portraits/<id>.jpg`; os
recortes «bust» usados no jogo estão em `assets/art/portraits/<id>_face.jpg`.
Fallback em runtime: se o ficheiro não existir, o UI segue sem retrato —
nunca um rosto errado no lugar (`src/ui/portraits.gd`, com verificação de
existência para todos os retratos).

| Personagem (como fala no jogo) | Ficheiro (`_face.jpg`) | Estado |
|---|---|---|
| Kael — neutro / determinado / ferido / suave / combate | `kael_{neutral,determined,pained,soft,battle}_face.jpg` | ✓ gerado |
| Elen Noro | `elen_face.jpg` | ✓ gerado |
| Tomás, o Aldeão | `tomas_face.jpg` | ✓ gerado |
| Garr, o Ferreiro | `garr_face.jpg` | ✓ gerado |
| Liora Venn | `liora_face.jpg` | ✓ gerado |
| Mestre Dario Vale | `dario_face.jpg` | ✓ gerado |
| Bram Ferro | `bram_face.jpg` | por gerar (limite de imagem da sessão) |
| Sena Raiz | `sena_face.jpg` | por gerar (idem) |
| Iven Lago | `iven_face.jpg` | por gerar (idem) |
| Arquivista Voss | `voss_face.jpg` | por gerar (idem) |
| Marechal Cadena | `cadena_face.jpg` | por gerar (idem) |
| Vladimir, Guardião da Prova | `vladimir_face.jpg` | por gerar (idem) |

Integração: o diálogo de fala mostra o retrato no painel (`src/ui/dialogue.gd`,
128 px de largura, `KEEP_ASPECT_COVERED`); A DECISÃO mostra `kael_battle` junto
ao texto; o ecrã de fim mostra o retrato do romanceado (`GameState.romance_id`)
ou `kael_determined` como fallback.
