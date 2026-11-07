# Compilar e validar o Godot neste ambiente (2026-11-06)

> **Nota sobre persistência**: `/tmp` neste ambiente é apagado entre sessões —
> o binário compilado e a árvore de fonte do Godot **não sobrevivem**.
> O procedimento abaixo é reproduzível (~40-50 min). O binário (158 MB) está
> guardado comprimido em `tools/.bin/godot.gz` (ignorado pelo git, persiste no
> workspace) — `tools/headless_check.sh` extrai-o automaticamente para /tmp
> na primeira utilização de cada sessão. Para o usar manualmente:
> `gzip -dc tools/.bin/godot.gz > /tmp/giselle_godot && chmod +x /tmp/giselle_godot`.

O ambiente de trabalho **não consegue descarregar binários oficiais do Godot**
(`downloads.tuxfamily.org`/`godotengine.org` estão fora da lista de hosts; os
artefactos da release no GitHub redireccionam para S3 fora da lista; o `apt`
não tem rede). A saída encontrada: **compilar o Godot 4.7.2 a partir do
código-fonte** (codeload.github.com funciona).

## Ambiente persistente (instalado 2026-11-06)

Apenas `$HOME` persiste entre sessões (e `$HOME/.local` **não** persiste).
Por isso as ferramentas pip vão parar a `${GISELLE_ENV:-$HOME/.giselle-env}`:

```bash
tools/setup_env.sh           # instala tudo (idempotente)
tools/setup_env.sh --check   # só verifica
export PATH="$HOME/.giselle-env/bin:$PATH"
tools/godot.sh --version     # extrai tools/.bin/godot.gz para /tmp e executa
```

`pip3 install -r requirements-dev.txt` instala `gdtoolkit` (fornece
`gdparse`/`gdlint`, usados pelo `tools/validate.py`) — no CI isto corre
automaticamente. Instalado e verificado: `scons` 4.11.1, `cmake` 4.4.4, `shellcheck` 0.11.0,
`ffmpeg` (imageio-ffmpeg n9.0.2), `numpy` 2.4.6 (necessária a
`tools/synth_music.py`). Já existiam na base: `gcc`/`g++` 12.2, `make`,
`python3` 3.11, `node` 22, `npm` 10, `git` 2.39, `gh` 2.23, ImageMagick 6.

**Não instalável neste sandbox:**
- Android SDK/JDK/keytool — `dl.google.com`, Adoptium/BellSoft e
  `deb.debian.org` estão bloqueados (só github, npm e pypi). O export de APK
  tem de correr numa máquina com Android Studio + JDK; o preset
  (`export_presets.cfg`) já está preparado e avisos do import foram eliminados
  (`export_filter` na secção `[preset.N]`).
- Templates de export com gráficos (linuxbsd/x11, Wayland, Windows) — faltam os
  headers de desenvolvimento (`/usr/include/X11`, `GL`, `vulkan`, `EGL`
  inexistentes; apenas `libX11.so.6` runtime). Só seria compilável um template
  x11=no (headless), cujo output não renderiza — não vale o tempo de build.
- xvfb / Mesa GL — não há apt; sem GL por software, não há validação visual
  local. A primeira validação visual é sempre na máquina do utilizador (F5).

Os scripts shell do repositório passam `shellcheck -S style` limpos.

## Como foi feito

```bash
curl -L -o godot-src.tar.gz https://codeload.github.com/godotengine/godot/tar.gz/refs/tags/4.7.2-stable
tar xzf godot-src.tar.gz && cd godot-4.7.2-stable
pip3 install --break-system-packages scons
# pkg-config não existe no ambiente; um stub vazio em PATH basta porque
# CADA dependência de sistema está desligada (use_sowrap ou builtin/*):
mkdir -p /tmp/bin && printf '#!/bin/sh\nexit 0\n' > /tmp/bin/pkg-config && chmod +x /tmp/bin/pkg-config
PATH=/tmp/bin:$PATH scons platform=linuxbsd target=editor \
    x11=no wayland=no dbus=no speechd=no fontconfig=no \
    alsa=no pulseaudio=no udev=no touch=no use_llvm=no \
    debug_symbols=no -j2
# → bin/godot.linuxbsd.editor.x86_64 · ~51 min · ~2 GB (gcc 12, 2 cores, 4 GB RAM)
```

O binário corre apenas headless (sem X11) — suficiente para importar, carregar
cenas e executar scripts de teste:

```bash
godot --headless --path . --import                       # importa artefactos
tools/headless_check.sh                       # usa tools/.bin/godot se existir
godot --headless --path . res://tools/smoke_test.tscn    # 13 asserções; exit 0 = tudo verde
res://tools/smoke_flows.tscn  # 5 asserções de fluxo; exit 0 = tudo verde
```

## O que a engine encontrou e que a validação estática nunca viu

| # | Bug | Correção |
|---|---|---|
| 1 | `GameState.notify` era um **signal** chamado como função em ~15 ficheiros — nada compilava | `signal notify_requested` + `func notify()`; `ui.gd` liga ao novo sinal |
| 2 | `JOY_BUTTON_SHOULDER_LEFT/RIGHT` não existe | `JOY_BUTTON_LEFT_SHOULDER` / `JOY_BUTTON_RIGHT_SHOULDER` |
| 3 | `PointLight3D` não existe no Godot 4 | `OmniLight3D` |
| 4 | `shadow_map_size` removido do `DirectionalLight3D` | `directional_shadow_max_distance = 90.0` + `rendering/lights_and_shadows/directional_shadow/size=2048` no project.godot |
| 5 | `tts_is_speaking_available()` não existe | removido; `tts_get_voices()` vazio ⇒ silêncio |
| 6 | Inferência `:=` a partir de valores Variant (warnings tratados como erros) | anotações explícitas em ~15 locais |
| 8 | (harness) smoke_flows ficava **eternamente sem output**: a Sala Branca pausa a árvore na avaliação e o runner processava em modo INHERIT | runner em `PROCESS_MODE_ALWAYS` + despausar ao trocar de cena |
| 9 | **Ui.gd não compilava** (`var x := ["A","B"][i]` — GDScript não infere tipo de literal indexado) — o autoload UI morreu e a Sala Branca rebentou em cadeia | tipo explícito (`var x: String = ...`); `headless_check.sh` passou a falhar em SCRIPT ERROR/autoload morto |
| 7 | **Checksum do save impossível de validar**: o JSON do Godot devolve sempre floats (`1`→`1.0`) — saves **nunca** carregavam | serialização canónica (`_canonical_save`) partilhada entre save e load; **todos os saves anteriores são inválidos** (mas já o eram — o load devolvia sempre «adulterada») |

## Estado de validação após a correção

- 5 cenas (`title`, `main`, `academia`, `region`, `sala_branca`) carregam e
  correm 120–240 frames headless **sem SCRIPT ERROR**.
- `tools/smoke_test.tscn`: **24/24** — boot do mundo, subir de nível por XP,
  desbloqueio de técnicas (Passo Vazio/Queda do Colosso), curva de XP e
  cura da poção via `balance.json`, **save/load roundtrip**, dano real a um
  inimigo instanciado em runtime, **salto + ataques aéreos + slam de queda**
  (dano de área real), lesões graduadas 0–2, fadiga de treino (bloqueio no
  MÁX), guarda de marcos, remendo do curandeiro, persistência da voz TTS e ciclo sem vozes no sistema.
- `tools/perf_probe.tscn`: sonda de performance CPU-side (headless) —
  fps de processo, ms de frame/física, memória estática, contagem de
  objetos/nós/órfãos. Não substitui profiling em hardware real (F5).
- `tools/headless_check.sh`: o gate falha se qualquer cena emite
  SCRIPT ERROR/Parse Error/autoload falhado (desde v0.6).
- `tools/smoke_flows.tscn`: **5/5** — fluxos completos: Sala Branca (simulação
  até à avaliação; a árvore pausa como deve → o runner processa em ALWAYS),
  Academia (Prova de Duelo vencida → `exams_done["duelo"]`, lealdade de Bram
  ≥ 60).
- **Nunca validado**: correção visual (orgientação de modelos, animações,
  materiais em GL Compatibility), jogabilidade real com um humano, Android.
  Headless só prova compilação + boot + lógica.
