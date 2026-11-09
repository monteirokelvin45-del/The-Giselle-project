#!/bin/sh
## Ponte para o binário Godot persistido no repositório (tools/.bin/godot.gz).
## /tmp é apagado entre sessões — o binário é extraído para /tmp/giselle_godot
## na primeira utilização (ou quando o .gz for mais recente) e executado a partir daí.
set -eu
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
GZ="$PROJ/tools/.bin/godot.gz"
X="${GISELLE_GODOT:-/tmp/giselle_godot}"
if [ ! -f "$GZ" ] && [ ! -x "$X" ]; then
	echo "tools/.bin/godot.gz não existe — corre tools/setup_env.sh (ver docs/BUILD.md)" >&2
	exit 1
fi
if [ -f "$GZ" ] && { [ ! -x "$X" ] || [ "$X" -ot "$GZ" ]; }; then
	gz -dc "$GZ" > "$X"
	chmod +x "$X"
fi
exec "$X" "$@"
