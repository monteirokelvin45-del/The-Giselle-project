#!/bin/sh
## Prepara o ambiente de desenvolvimento persistente do The Giselle Project.
##
## O workspace persiste apenas ~/home do utilizador (/home/$USER) e exclui
## ~/.local, /tmp e outras pastas — por isso as ferramentas instaladas via pip
## são guardadas em "$GISELLE_ENV" (por omissão: $HOME/.giselle-env) e o
## binário Godot fica comprimido em tools/.bin/godot.gz (ignorado pelo git).
##
## Uso:
##   tools/setup_env.sh                 # instala/atualiza tudo
##   tools/setup_env.sh --check         # apenas verifica o que existe
##
## Hosts usados (lista do ambiente): pypi.org / files.pythonhosted.org.
## Android SDK/JDK NÃO é instalável aqui (dl.google.com, Adoptium, deb.debian.org
## estão bloqueados) — o export para Android tem de correr numa máquina com
## Android Studio + JDK. O preset já está preparado (export_presets.cfg).
set -eu

PROJ="$(cd "$(dirname "$0")/.." && pwd)"
GISELLE_ENV="${GISELLE_ENV:-$HOME/.giselle-env}"
PYLIBS="$GISELLE_ENV/pylibs"
BIN="$GISELLE_ENV/bin"

echo "== GISELLE_ENV: $GISELLE_ENV"

if [ "${1:-}" = "--check" ]; then
	rc=0
	for t in gcc g++ make python3 pip3 node npm git gh curl convert; do
		if command -v "$t" >/dev/null; then printf '  OK   %s\n' "$t"; else printf '  FALTA %s\n' "$t"; rc=1; fi
	done
	for t in scons cmake shellcheck ffmpeg; do
		if [ -x "$BIN/$t" ]; then printf '  OK   %s (%s)\n' "$t" "$BIN/$t"; else printf '  FALTA %s — corre tools/setup_env.sh\n' "$t"; rc=1; fi
	done
	if PYTHONPATH="$PYLIBS" python3 -c "import numpy" 2>/dev/null; then echo "  OK   numpy ($PYLIBS)"; else echo "  FALTA numpy"; rc=1; fi
	if [ -f "$PROJ/tools/.bin/godot.gz" ]; then echo "  OK   tools/.bin/godot.gz ($(du -h "$PROJ/tools/.bin/godot.gz" | cut -f1))"; else echo "  FALTA tools/.bin/godot.gz — ver docs/BUILD.md"; rc=1; fi
	exit $rc
fi

mkdir -p "$BIN" "$PYLIBS"

echo "== pip install (alvo: $PYLIBS)"
python3 -m pip install --quiet --target "$PYLIBS" \
	scons cmake shellcheck-py imageio-ffmpeg numpy

echo "== wrappers em $BIN"
# shellcheck disable=SC2016
for t in ccmake cmake cpack ctest scons scons-configure-cache sconsign shellcheck; do
	printf '#!/bin/sh\nexport PYTHONPATH="%s${PYTHONPATH:+:$PYTHONPATH}"\nexec "%s/bin/%s" "$@"\n' \
		"$PYLIBS" "$PYLIBS" "$t" > "$BIN/$t"
	chmod +x "$BIN/$t"
done
# shellcheck disable=SC2016
printf '#!/bin/sh\nexport PYTHONPATH="%s${PYTHONPATH:+:$PYTHONPATH}"\nexec python3 -c "import os,sys,imageio_ffmpeg; os.execv(imageio_ffmpeg.get_ffmpeg_exe(), [sys.argv[0]]+sys.argv[1:])" ffmpeg "$@"\n' \
	"$PYLIBS" > "$BIN/ffmpeg"
chmod +x "$BIN/ffmpeg"
chmod +x "$PROJ/tools/godot.sh"

echo "== concluído. Para usar:"
echo "   export PATH=\"$BIN:\$PATH\""
echo "   tools/godot.sh --version     # extrai tools/.bin/godot.gz para /tmp se preciso"
echo
echo "Nota: Android SDK/JDK não é instalável neste ambiente (hosts bloqueados)."
echo "O export de APK exige uma máquina com Android Studio + JDK (preset pronto)."
