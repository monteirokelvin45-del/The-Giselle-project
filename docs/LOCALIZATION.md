# Localização (l10n) — The Giselle Project

**Estado honesto:** o jogo ainda **não** troca de idioma em runtime. A língua de
origem é o português europeu, escrito directamente nos scripts. Este documento
descreve o andaime que prepara a extração e aponta o que falta para uma
versão traduzida de verdade.

## O que existe hoje

- `tools/l10n_extract.py` — varre `src/**/*.gd`, recolhe as strings de texto
  (UI, diálogo, notificações, falas) e escreve `docs/l10n/strings_pt.csv`
  (`key, context_file, line, text`, 371 entradas na última extração).
- `docs/l10n/strings_pt.csv` — tabela de strings em português europeu,
  deduplicada, com referência de ficheiro e linha de cada ocorrência.
- Convenções já fixas no código: placeholders no estilo `%s` / `%d` são
  preservados nas strings e o jogo nenhuma vez constrói frases por
  concatenação solta de fragmentos (o que facilitaria a tradução).

## Como extrair

```bash
python3 tools/l10n_extract.py
```

Gera (ou actualiza) `docs/l10n/strings_pt.csv`. Correr sempre que novas
strings forem adicionadas.

## Workflow para uma segunda língua (quando for para produção)

1. Copiar `docs/l10n/strings_pt.csv` para `docs/l10n/strings_<locale>.csv`
   (por exemplo `strings_en.csv`) e traduzir a coluna `text` mantendo `key`.
2. Substituir os literais em `src/**/*.gd` por chamadas `tr("PT-0001")` (ou
   por uma chave semântica, ex.: `tr("UI_POTION_USED")`) — feita por script,
   acompanhada de revisão manual dos casos com `%s`/`%d`.
3. Importar os CSVs como recursos `.translation` no Godot (Project Settings →
   Localization) — o servidor de localização do engine faz a troca em runtime.
4. Adicionar ao menu de pausa um selector de idioma e persistir
   `locale` em `GameState` (save v3).
5. QA por falante nativo + screenshots de todos os ecrãs (HUD, menus,
   diálogos, finais) — strings 1.3× mais longas em inglês rebentam caixas
   de texto apertadas.

## Regras para strings novas

- Uma frase completa por string; nada de montar «a» + nome de item + «foi».
- Manter espaços e pontuação **dentro** da string.
- Não aninhar markup dentro de strings traduzíveis.
- Correr `tools/l10n_extract.py` e comitá-lo junto com a mudança.

## Limites conhecidos

- O extrator não entende contexto semântico; chaves são posicionais
  (PT-0001…) e podem mudar de número se ficheiros forem reordenados. Uma
  migração para chaves semânticas (`UI_…`, `DIALOG_…`) está prevista antes
  do primeiro release público traduzido.
- Strings construídas dinamicamente (`"%s — %s" % [a, b]`) aparecem na tabela
  já com os placeholders — os tradutores não devem mexer neles.
