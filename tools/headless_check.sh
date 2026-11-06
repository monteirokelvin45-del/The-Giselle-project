#!/usr/bin/env bash
## Smoke test headless pós-build (Linux, sem X11):
##   1) importa todos os artefactos (detecta erros de import/recursos)
##   2) executa cenas principais durante alguns frames (detecta erros de runtime,
##      autoloads, .tscn inválidos, scripts que não compilam no load)
## Uso: tools/headless_check.sh [caminho/para/o/binário/godot]
set -uo pipefail
PROJ="$(cd "$(dirname "$0")/.." && pwd)"
if [ $# -ge 1 ]; then
	GODOT_BIN="$1"
elif [ -x "$PROJ/tools/.bin/godot" ]; then
	GODOT_BIN="$PROJ/tools/.bin/godot"
else
	GODOT_BIN="godot"
fi
cd "$PROJ"

echo "== versão ($GODOT_BIN)"
"$GODOT_BIN" --headless --version || exit 1

echo "== import de artefactos"
"$GODOT_BIN" --headless --path "$PROJ" --import 2>&1 | tail -25

fail=0
run_scene () {
	local scene="$1" frames="${2:-120}"
	echo "== smoke: $scene ($frames frames)"
	local log="/tmp/smoke_$(basename "$scene" .tscn).log"
	"$GODOT_BIN" --headless --path "$PROJ" "$scene" --quit-after "$frames" > "$log" 2>&1
	local code=$?
	if grep -iE "SCRIPT ERROR|Parse Error|Failed to|Nonexistent|ERROR" "$log" | head -10; then
		echo "   ^  avisos/erros em $log"
	fi
	[ $code -ne 0 ] && { echo "   ! código de saída $code"; fail=1; }
}
run_scene res://scenes/title.tscn 120
run_scene res://scenes/main.tscn 240
run_scene res://scenes/academia.tscn 240
run_scene res://scenes/region.tscn 240
run_scene res://scenes/sala_branca.tscn 240
[ $fail -ne 0 ] && echo "SMOKE: FALHAS (ver /tmp/smoke_*.log)" || echo "SMOKE OK"
exit $fail
