# Visuals — pipeline cel/toon e o porquê

**Estado (2026-11-07):** look cel ativo por omissão, toggle em
**Pausa → Cel-shading** (persistido no save). Implementado com recursos
nativos do Godot; ver `docs/INSPIRATION.md` para a atribuição do estudo.

## O que o Genshin faz (e o que não podemos/queremos replicar)
Characters no Genshin usam um shader **unlit** com:
1. **Shadow Ramp** por bandas (a luz "cai" em 2–3 degraus, não em gradiente).
2. **ILM map** — Intensidade/Luz/Metallic por canal, pintado por personagem,
   que dita onde o ramp é aplicado (pele, tecido, cabelo, metal).
3. **SDF face shadows** — sombra do rosto decide por distância de um SDF
   pintado (o cabelo não "corta" o rosto de forma errada em contraluz).
4. **Rim light** forte (silhueta lê-se contra qualquer fundo).
5. **Outline** por inverted hull (contorno por normals infladas).

Os KenKay trazem **UVs e texturas padrão**, não ILM/SDF por personagem —
pintá-las seria um projeto de arte novo por modelo, fora do escopo.

## O que A Academia do Zero usa (original, nativo do Godot 4)
Em `model_factory.gd::apply_cel_look`, todo MeshInstance3D dos modelos
passa de `StandardMaterial3D` duplicado para:

| Propriedade | Valor | Efeito |
|---|---|---|
| `diffuse_mode` | `DIFFUSE_TOON` | luz por bandas (o "degrau" cel) |
| `specular_mode` | `SPECULAR_TOON` | highlight estilo anime, não PBR |
| `rim_enabled` / `rim` / `rim_tint` | `true / 0.45 / 0.5` | silhueta como no GI |

**Não** implementado e porquê:
- **Inverted hull outline** — em GLES3/Compatibility, hulls infladas por
  normals normais produzem z-fighting e contornos "duplos" em silhuetas
  finas (espadas, dedos). Quando o jogo migrar para Forward+/Vulkan, o
  outline por post-process (FXAA + edge detect) é o caminho — não antes.
- **ILM/SDF** — exigem arte bespoke por personagem; KayKit não traz os
  mapas. Se o dono quiser este salto de fidelidade, é uma tarefa de
  textura/UV por modelo (ver ROADMAP), não de código.
- **Face SDF** — idem.

## Toggle
- Pausa → **Cel-shading** (Ligada/Desligada), persistido no save
  (`cel_toon`, aditivo; saves antigos carregam Ligada).
- Trocar a quente não repinta instâncias já no mundo — **requer recarregar
  a cena** (o botão avisa). Em prática: liga/desliga e volta ao Vale.
- Desligado = `StandardMaterial3D` padrão (o look original do v0.2).

## Como validar (F5, na máquina do dono)
1. F5 → reparar em cabelo e rosto dos NPCs (KayKit): o ramp tem de ler como
   2–3 planos, sem banding esquisito.
2. Rim visível na contraluz (sol atrás do personagem).
3. Se algo arder/brilhar demais, ajustar `rim` (0.3–0.6) e `rim_tint`
   (0.3–0.7) em `apply_cel_look`.
4. Performance GLES3: o modo TOON é mais barato que PBR completo — sem custo
   esperado; medir na sonda (`tools/perf_probe.tscn`) e registar em §17.

## Créditos/atribuições
Zero código de terceiros em `src/visuals/`. As referências de técnica estão
em `docs/INSPIRATION.md` (GenshinCelShaderURP, urp-toon-shader — leitura de
README e ficheiros públicos para compreender as fórmulas; nada copiado).
