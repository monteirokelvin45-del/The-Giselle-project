# Localização (l10n) — The Giselle Project

**Estado (honesto, 2026-11-07):** o jogo troca de idioma em runtime —
PT (origem), EN e ES — com 421/421 strings traduzidas nas duas línguas e um
gate de CI que impede regressões. O que falta verificar é só a importação
baked dos `.translation` no primeiro import frio num ambiente fresco (engine
local em falta nesta sessão; o CI histórico corre só o smoke PT).

## Arquitetura

- **Chaves = os próprios literais PT** no código (`tr("Jogo guardado.")`).
  Vantagem: se uma tradução faltar, `tr()` devolve a chave, ou seja o texto
  original — o jogo nunca mostra vazio nem rebenta.
- `l10n/game.csv` — tabela única `keys,pt,en,es` com as 421 strings
  (UI, diálogos, notificações, finais, nomes PT mantidos como own names).
- `tools/l10n_build.py` — re-extrai as chaves dos `.gd` atuais e escreve o
  CSV preservando traduções antigas. `--check` falha se:
  (a) faltar a chave no CSV; (b) `en`/`es` estiverem vazios ou TODO;
  (c) existirem chaves antigas fora do código.
- `tools/validate.py` corre `--check` no passo `[5/5]` → **o CI falha
  automaticamente se uma string nova entrar sem EN/ES**.
- `tools/l10n_extract.py` — inventário PT para docs
  (`docs/l10n/strings_pt.csv`, 421 entradas), independente do CSV de runtime.

## Idioma no jogo

- Preferência `locale` em `GameState` ("pt" por omissão), persistida no save
  (campo aditivo; saves antigos carregam como PT).
- Aplicada no boot (autoload `GameState._ready`) e no carregar de save.
- Seletor no **ecrã de título** (canto inferior direito, `Português / English /
  Español ⟳`): `GameState.cycle_locale()` + `reload_current_scene()` — a troca
  é imediata e uniforme (todas as labels são recriadas com o novo locale).
- Não há seletor no menu de pausa de propósito: a UI do jogo é construída uma
  só vez por cena; trocar a meio deixaria parte do HUD no idioma anterior.
- `TranslationServer.set_locale(locale)` é o mecanismo; sem nenhuma tradução
  registada, `tr()` é identidade (pass-through) — o comportamento PT original
  não muda.

## Regras para strings novas

- Uma frase completa por string; nada de montar «a» + nome + «foi».
  (Formatos `%s`/`%d`/`%.0f`/`%02d` são posicionais — manter a ordem.)
- Manter espaços e pontuação **dentro** da string.
- Nunca chamar `tr()` dentro de `static func` (é método de Object — não existe
  em contexto estático; o CI apanhou 1 ocorrência e foi corrigida).
- Nunca `tr()` por substring/slice: o efeito de máquina de escrever do diálogo
  fatia o texto **já traduzido** (ver `src/ui/dialogue.gd`).
- Strings dinâmica-span (`"%s — %s" % [a, b]`) só se tornam traduzíveis se os
  **literais** passarem por `tr()` individualmente. Ver helpers `_*_text()`
  e `objective_text()` como padrão.
- Correr `python3 tools/l10n_build.py` (nunca à mão) e comitá-lo junto.

## Workflow

```bash
python3 tools/l10n_build.py          # regenerar após adicionar strings
python3 tools/validate.py            # falha se EN/ES em falta (procura no [5/5])
```

1. Editar código; correr `l10n_build.py`; traduzir as linhas `__TODO_*` no CSV.
2. `python3 tools/l10n_extract.py` para manter o inventário dos docs.
3. Commit junto: `.gd` + `l10n/game.csv`.

## Verificação em runtime (pendente/imediata)

O primeiro `godot --headless --import` gera os `.translation` a partir de
`l10n/game.csv`; estes artefactos são **commitados** para o jogo funcionar
sem re-import. Eu registo-os em `project.godot`
(`internationalization/locale/translations`) com fallback PT. Enquanto isso,
`tr()` funciona como pass-through PT (nada parte).

## Limites conhecidos

- A engine não renderiza fora da própria cena: o QA visual por falante
  nativo (diálogos 1.3× mais longos em EN) continua por fazer —
  ver `docs/TESTING.md`.
- Nomes próprios (regiões, facções, companheiros, técnicas épicas) ficam em
  PT por desenho; as traduções contextualizam-nos, não os renomeiam.
- `TEMPESTADE À MEDIDA` (banner da tempestade custom) foi traduzido à letra
  ("CUSTOM STORM" / "TORMENTA A MEDIDA"); se for uma piada interna, rever.
- Romances com memória de ações continuam sem implementação (ver AUDIT §13).
