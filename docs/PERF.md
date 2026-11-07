# Qualidade & Performance — como medimos, o que o CI prova

Documento vivo do v1.7 «Qualidade & Performance». Regra de ouro: **o CI
prova estrutura e consistência; só o teu aparelho prova fluidez.** Nunca
declara-se «performático» sem um dos dois.

## O que o CI prova a cada push (e o que não prova)

| Gate | Prova | NÃO prova |
|---|---|---|
| `validate.py` | nós, caminhos res://, l10n, project.godot | runtime |
| `headless_check.sh` (5 cenas) | scripts compilam no engine; boot sem SCRIPT ERROR | frame time, memória real |
| i18n runtime (PT/EN/ES) | traduções resolvem no engine | — |
| `smoke_test.tscn` | jogabilidade: XP, atributos, save→load (posição/hp/fôlego/marcos/voz/lesões) | — |
| `smoke_flows.tscn` | fluxos Sala Branca + Academia sem crash | — |
| `stress_test.tscn` (**novo no v1.7**) | equipa de **10 inimigos, todos os tipos**, mundo principal, ~14 s de física; asserts de instância, de reutilização do pool e de contagens; imprime monitores CPU-side | FPS de ecrã, 1% low, jank de GPU |

O que o CI **não** tem: GPU, ecrã, Android runner. Frame times só medimos
no aparelho (secção seguinte). Por isso a build «não piorou» no CI = os
**gates estruturais** passam; «não piorou no Android» continua a ser F5 teu.

## v1.7 — o que mudou (e porquê)

1. **`src/enemies/projectile_pool.gd`** (novo) + `projectile.gd`
   reutilizável: timeout ou impacto **devolvem o nó à pool** em vez de o
   destruir (a malha, o colisor e os 2 materiais ficam cacheados no pool).
   Elimina churn de alocação no pior caso — todos os conjuradores a disparar.
   O pool estaciona os nós **fora da cena** e reutiliza-os (asserção de
   identidade da própria instância no `stress_test`).
2. **IA com degradação por distância** (`enemy.gd`): acima de
   `combat.remote_ai_distance_m` (34 m), o inimigo salta as consultas de
   grupo da separação O(n²), a query de coordenação e o update de animação;
   movimento e cooldowns continuam a 60 Hz — hostilidade idêntica de perto,
   custo longe ~nulo.
3. **Janelas de combate nos dados** (`balance.json` → `combat`):
   `parry_window_base` (era literal `0.2`) e `dash_iframes` (era `0.36`).
   Afinar sem recompilar — mesmo contrato do `jump` e do `attr`.
4. **Asserções novas de save→load** no `smoke_test` (posição, hp, fôlego).
5. **`stress_test.tscn`** integrado ao CI — e este documento.

## Medir no teu Android (o fluxo honesto)

1. **Editor + dispositivo (F5):** telemóvel em modo depuração USB,
   `adb devices`; F5 no editor. Em **Debug → Monitors** vês FPS, físico,
   memória estática, nós e draw calls em direto.
2. **Frame time de verdade (sem PC):** `adb shell dumpsys gfxinfo
   pt.giselle.zero framestats` antes/depois de uma luta (6+ inimigos) —
   devolve os frame times do compositor do aparelho.
3. **RenderDoc** (grátis, funciona em GLES3 Android): captura um frame do
   Vale em combate — mostra draw calls, overdraw e texturas por pass.
   Útil para decidir se algum efeito de magia está caro de mais.
4. **Não medir na máquina do programador** — o aparelho do dono manda.
5. Reporta no grupo/commit qualquer regressão; o CI apanha estrutura,
   o F5 apanha fluidez.

## Checklist de entrada de asset (ápice da regra «nada entra sem passar»)

- Calibre: modelo estático ≤ ~5k tris; animado ≤ ~15k;
  texturas ≤ 1024px (mipmaps automáticos no import GLES3);
  ≤ 2 materiais por mesh; colisor invisível próprio (regra do repo).
- Zero assets sem licença explícita (CC0/CC-BY) registada em `docs/licenses/`.
- **Provisório:** estes limites só se apertam/alargam depois da primeira
  medição real no teu aparelho-alvo (ver «Frame budget»).

## Frame budget (provisório — confirmar no aparelho)

| Métrica | Alvo provisório | Como medir |
|---|---|---|
| FPS médio (Vale em combate) | ≥ 30 sustentados | Debug → Monitors / gfxinfo |
| 1% low | ≥ 18 | gfxinfo framestats / RenderDoc |
| Memória estática | < 350 MB | Monitors (static) |
| Boot → menu | < 4 s no aparelho-alvo | F5 + cronómetro |
| Load Vale → Academia/Região | < 2 s | F5 portal |

Nenhum destes valores foi medido ainda num Android real — são intenção,
não promessa. A primeira sessão F5 define os números definitivos.

## Limites honestos

- Não existe gate de frame time automático por commit (sem GPU no CI) —
  e por isso ainda não existe «relatório semanal»: exigiria um runner
  Android persistente (ou um dono a medir no aparelho, que é o que fazemos).
- Streaming de chunks / LOD de meshes / impostores: **não implementados** —
  prematuros no volume atual; só pesam depois de medidos.
- O `stress_test` mede saneamento (não crasha, não vaza, pool reutiliza);
  não mede renderização.
