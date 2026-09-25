#!/usr/bin/env bash
#
# minimize.sh — "Dimensão Paralela"
# Minimiza a janela ativa: guarda seus metadados em memória (arquivo de
# cache) ANTES de escondê-la, para que a lista de minimizados do Waybar
# saiba o que existe lá dentro e consiga restaurar depois.
#
# Ligar ao bind do Hyprland no lugar de "movetoworkspace, special:magic".

set -euo pipefail

CACHE_DIR="$HOME/.cache/waybar"
LIST_FILE="$CACHE_DIR/minimized.json"

mkdir -p "$CACHE_DIR"
[[ -s "$LIST_FILE" ]] || echo "[]" > "$LIST_FILE"

active=$(hyprctl activewindow -j)
address=$(jq -r '.address // empty' <<< "$active")

# Nada em foco (ex: workspace vazio) -> não há o que minimizar
[[ -z "$address" ]] && exit 0

title=$(jq -r '.title' <<< "$active")
class=$(jq -r '.class' <<< "$active")

# Evita duplicar a entrada se por algum motivo já estiver na lista
already=$(jq --arg addr "$address" '[.[] | select(.address == $addr)] | length' "$LIST_FILE")
if [[ "$already" -eq 0 ]]; then
    tmp=$(mktemp)
    jq --arg addr "$address" --arg title "$title" --arg class "$class" \
        '. += [{"address": $addr, "title": $title, "class": $class}]' \
        "$LIST_FILE" > "$tmp" && mv "$tmp" "$LIST_FILE"
fi

# Move a janela ativa para a special:magic. Na API Lua atual (0.56.2) isso
# SEMPRE revela o overlay do workspace especial na tela -- não existe mais
# um "movetoworkspacesilent" de fato silencioso (testado e confirmado; nem
# passar/omitir seletor de janela muda esse comportamento). Por isso,
# fechamos o overlay de volta explicitamente logo em seguida, checando o
# estado real em vez de simplesmente "togglar" (toggle_special inverte o
# estado atual -- togglar às cegas poderia ABRIR o overlay se ele já
# estivesse fechado por outro motivo).
hyprctl dispatch "hl.dsp.window.move({workspace='special:magic'})" >/dev/null

revealed=$(hyprctl monitors -j | jq -r '.[0].specialWorkspace.name // empty')
if [[ "$revealed" == "special:magic" ]]; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special('magic')" >/dev/null
fi
