# Trilho B — «Arkanor em detalhe» (High-poly / PBR verdadeiro)

**Decisão do dono (2026-11-09):** «B» — o caminho flagship: escultura de
personagens e props, texturas PBR completas (ORM), entrega para aparelhos
Vulkan de gama média-alta. **Este é um trilho com equipa de arte e tempo,
não uma sessão de código.** Este documento é a ordem de execução honesta.

## 1. O que existe hoje (v1.14, inegociáveis para a nova base)

- Pipeline de look **cel** nativo do Godot 4 (`docs/VISUALS.md`) — é o look
  atual e provado; o Trilho B **não** o descarta, transforma-o
  (cel-sobre-PBR-hormonal: ramp por banda + ILM/ORM map).
- **50 modelos** (`assets/`, 31 MB) — KayKit CC0 (characters/medieval) +
  Quaternius (lobo); rigs padrão KayKit com ~76 clipes cada; UVs e
  texturas embutidas genéricas.
- **Zero** `QualityManager` implementado (autoloader do PROMPT MASTER) —
  o B exige-o para manter o Trilho A (KayKit) vivo em Y62 enquanto B constrói.
- `docs/ASSETS.md` + `docs/licenses/` — fluxo de crédito/licença pronto.
- i18n 518 chaves · CI verde · APK assinado por cima-sem-desinstalar
  (em reparo separado, ver AUDIT §36–§37).

## 2. O que B significa, dito sem maquiagem

B não é «mais detalhes». B é **um produto diferente**:

| Item | Hoje (Trilho A) | Trilho B (flagship) |
|---|---|---|
| Geometria | KayKit low-poly (6–8 mil tris Kael) | escultura → retopo **20–28 mil tris** (LOD0) |
| Material | albedo chapado + tintas 0.2–0.5 cinza + `DIFFUSE_TOON` | set **ORM** (AO/rough/met) + ILM-lite por papel; PBR estilo «stylized AAA» |
| Texturas | embutidas KayKit (512) | mapas 1–2K por material; 2–4K heróis; atlas/trim sheets |
| Rig | KayKit padrão (~76 anims) | re-retarget completo para novo rig (~60 ossos Kael) |
| APK | ~53 MB | **≈400–800 MB** → Android App Bundle (split APK) + sideload livre |
| PCs-alvo | Nova Y62 (EMUI 12, GLES3, 4 GB) — piso | Vulkan 1.1+ / 6 GB+ (SD845-class 2018+); **Y62 sai do piso** — decisão do dono em §7 |
| Memória | ≤300 MB | ≤900 MB |
| FPS | 30 estável (Y62) | 60 alvo (gama média-alta); estabilidade > pico |

**Verdade operacional:** eu (agente) **não esculpo malhas** e não pinto
texturas de set PBR — não gero malhas 3D. B só avança com:
1. **artista(s) humano(s)** por contrato (ou
2. **pacotes de assets pré-fabricados pais** (Fab.com/Sketchfab lic. audit) —
   qualidade/estética incerta, quase sem «família coesa», ou
3. **conjunto fechado de packs CC0/CC-BY pagos ou gratuitos** — a
   espinha costumada de B passa a ser curadoria de engenharia de arte.

O que eu executo dentro de B: specs, integração CodeMeta/iluminação/LOD/
pós/sharding, pipelines de build, licence audit, gates de APK, balanceamento
técnico, i18n, prompts de direção para o teu artista — **tudo depois de
os assets existirem em disco**. Antes disso, B é documentação + enablers.

## 3. Enablers técnicos que o B exige (a ordem certa)

1. `QualityManager` autoloader (`LOW`/`MED`/`HIGH` por capacidade real ou
   override manual): reads `safe_margin`, teto de tris/texturas, culling,
   detalhe de sombras. **Não existe hoje** — é B0/B1 de engenharia.
2. Vulkan renderer (`project.godot`: `gl_compatibility` → Vulkan quando
   HIGH), mantendo GLES3 path como Trilho A. Shaders ILM-lite: só HIGH.
3. LOD3 prático para B: LOD1 50%, LOD2 25%, LOD3 10% (Orçamento do PROMPT
   MASTER) — `VisibilityRange` + `GeometryInstance3D`.
4. Streaming de chunks (128 m) — pré-requisito de Orun/Veyra aberta. Só
   depois de Noro/Veyra B7 chegarem em LOD0.
5. Build Android App Bundle + signing split (base + assets.np / past SEW).

## 4. Fases B (milestones com gates de aceite no aparelho)

| Fase | Entrega | Gate | Estimativa com artista |
|---|---|---|---|
| B0 | Art bible + direção de arte final (este doc × as tuas 3 páginas) | tua assinatura na direção | 1 semana (doc) |
| B1 | **Kael** LOD0/1/2, bake ILM/ORM, re-rig, retarget de 76 clipes | F5 playground + APK instala por cima | 4–6 sem. (artista) |
| B2 | **Noro**: 6 hero builds novas (casa Elen, forja, taverna, mercado, poço, celeiro), set ORM | visita a Noro em B1 | 4–6 sem. |
| B3 | Kits de Ruun + Sahr (terreno/props) | Riun/Sahr em B1 | 6–8 sem. |
| B4 | Materiais PDR: ambientCG/Poly Haven ORM + trims + envmaps | comparação cega A/B | contínuo |
| B5 | Iluminação IBL/probes por bioma + pós mínimo (não Bloom de demo) | screenshot vs reference | 2–3 sem. |
| B6 | LOD/Streaming/vis Range em todo o jogo | 60 FPS estável no MEDIUM device | 2 sem. |
| B7 | Perfil Y62-compromisso ligado (Trilho A stubs por flag) — Y62 volta como «rural» | APK instala+abre no Y62 | 1 sem. |

**Regra de aceite de cada fase:** APK instala por cima da build anterior
(mesma assinatura, `version/code` maior) **e abre sem crash** no aparelho
de teste. Sem isso, a fase não fecha.

## 5. Licenças — o que pode e não pode

- **Pode (CC0/CC-BY/MIT/Apache/BSD), com crédito em `docs/licenses/`:**
  ambientCG + Poly Haven (materiais PBR), Quaternius/KayKit/Kenney,
  Sketchfab **verificado** CC0/CC-BY, ambientCG para HDR-esque equirect.
- **Pode (pago):** packs comerciais com licença de distribuição binária
  (ver SKU) — ficam **dentro do APK**, não são raspados nem redistribuídos
  (o repo fica com os recursos só onde possuímos licença).
- **Nunca:** extrações de jogos (Genshin incluído — anotado no README do
  repo), assets MIUI/EMUI, rip de mapas. Cada asset novo terá linha em
  `docs/ASSETS.md` + licença em `docs/licenses/`.
- Imagens de referência (as tuas páginas de direção) definem **mood**, não
  estrutura de outros estúdios: identidade, proporção e cor são do Arkanor.

## 6. Riscos e mitigação

| Risco | Impacto | Mitigação |
|---|---|---|
| Re-rig quebrando animações | Kael fica parado / sem movimento | B1 começa por retarget «Kael placa», gate de playground antes de tudo |
| APK > 400 MB no sideload | Miliáo do teu aparelho recusa; Play exige AAB | Android App Bundle; download de expPacks; regra 10+ GB Y62 continua Trilho A |
| Style drift entre artistas | Mundo de dois jogos | B0 bible com ILM/ramp/paletas por bioma + mantém.Base curto |
| Y62 não corre B | Aparelho do dono não abre o jogo | Trilho A stubs ligados (B7); Y62 = modo rural, 30 FPS |
| Licenças mal auditadas | Build retirada / processo | `docs/licenses/` de cada asset; revisão humana do dono antes de cada publicação |
| Estimativa de tempo deslizar | Projeto vivo para sempre | B1 como prova pública primeiro; não iniciar B2–B7 antes do Kael fechado |

## 7. O que fica por decidir (dono)

1. **O Nova Y62 deixa de ser o piso** — confirmas, ou queres B7 (Y62 como
   «modo rural») obrigatório antes de B1?
2. **Equipa:** contratas artista(s) (humano) — e qual? (escultor/texturing/
   rigger) — ou vamos de curadoria de packs licenciados?
3. **Budget:** qual? (a) 0 € / só meu tempo + assets pagos (~100–1.000 €),
   (b) 1.000–4.000 € por fase, (c) 5.000 €+ projeto inteiro?
4. **`version/code` 1→20 + `package/signed=true` permanência** — confirmas
   aplicar no commit que ligar o B0/B1?
5. **Ordem doc × implementação:** P1 (mapa textual) + este Trilho B como
   guia — ou implementar `QualityManager` em branch primeiro?
6. Imagens das tuas 3 páginas de direção — arquivar no repo (`docs/world/`)
   ou ficam só no teu disco?

## 8. Próxima ação

Com as tuas respostas aos 6 pontos (pode ser uma por mensagem): eu escrevo
o **B0 completo** (norma de arte final: paleta/ILM/ramp/palavras por bioma +
page spec exata do Kael) e anexo-o ao `docs/TRILHO-B.md` — **só texto**.
A primeira linha de implementação do B só nasce com o Kael em disco.
