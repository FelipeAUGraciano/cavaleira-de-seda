#!/usr/bin/env bash
# Carrega todos os scripts com os avisos do GDScript virando erro e lista os que sobrarem.
# Uso: tools/checar_avisos.sh [caminho-do-godot]
set -u
cd "$(dirname "$0")/.."
G="${1:-godot}"
cp tools/avisos_override.cfg override.cfg
trap 'rm -f override.cfg' EXIT
out=$("$G" --headless --path . res://tests/avisos_test.tscn 2>&1 | grep -A1 "Warning treated as error\|Parse Error\|Compile Error" | grep -v "^--" | paste - - | sed 's/SCRIPT ERROR: Parse Error: //; s/(Warning treated as error.)//; s/ *at: GDScript::reload (//' | sort -u)
if [ -z "$out" ]; then echo "Sem avisos."; else echo "$out"; exit 1; fi
