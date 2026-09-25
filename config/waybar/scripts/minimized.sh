#!/usr/bin/env bash
#
# minimized.sh — "Dimensão Paralela"
# Módulo custom do Waybar para a lista de janelas minimizadas.
#
#   minimized.sh            -> imprime o JSON que o Waybar renderiza
#   minimized.sh --restore  -> abre o rofi para escolher e restaurar
#                               uma janela no workspace ATUAL (não
#                               importa de onde ela foi minimizada)

set -euo pipefail

CACHE_DIR="$HOME/.cache/waybar"
LIST_FILE="$CACHE_DIR/minimized.json"
ICON="" # nf-fa-window_restore

mkdir -p "$CACHE_DIR"
[[ -s "$LIST_FILE" ]] || echo "[]" > "$LIST_FILE"

# Remove da lista qualquer janela Que tenha sido fechada enquanto
# minimizada (senão a lista "engorda" com fantasmas).
prune() {
    local clients tmp
    clients=$(hyprctl clients -j)
    tmp=$(mktemp)
    jq --argjson clients "$clients" \
        'map(select(.address as $a | $clients | any(.address == $a)))' \
        "$LIST_FILE" > "$tmp" && mv "$tmp" "$LIST_FILE"
}
prune

if [[ "${1:-}" == "--restore" ]]; then
    count=$(jq 'length' "$LIST_FILE")
    if [[ "$count" -eq 0 ]]; then
        notify-send "Minimizados" "Nenhuma janela minimizada."
        exit 0
    fi

    escolha=$(jq -r '.[] | "\(.title)  [\(.class)]"' "$LIST_FILE" | rofi -dmenu -p "Restaurar")
    [[ -z "$escolha" ]] && exit 0

    idx=$(jq -r --arg escolha "$escolha" \
        'to_entries[] | select("\(.value.title)  [\(.value.class)]" == $escolha) | .key' \
        "$LIST_FILE" | head -n1)
    [[ -z "$idx" ]] && exit 0

    address=$(jq -r ".[$idx].address" "$LIST_FILE")
    current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

    # Traz para o workspace que está ativo AGORA, não o de origem
    hyprctl dispatch "hl.dsp.window.move({workspace=$current_ws, window='address:$address', silent=true})"
    hyprctl dispatch "hl.dsp.focus({window='address:$address'})"

    tmp=$(mktemp)
    jq "del(.[$idx])" "$LIST_FILE" > "$tmp" && mv "$tmp" "$LIST_FILE"
    exit 0
fi

# Modo padrão: saída JSON para o Waybar (compacta -- em -c, senão o Waybar
# lê linha a linha e quebra no meio de um JSON multilinha)
count=$(jq 'length' "$LIST_FILE")
if [[ "$count" -eq 0 ]]; then
    jq -n -c '{text: "", tooltip: "Nenhuma janela minimizada", class: "empty"}'
else
    jq -c --arg icon "$ICON" '{
        text: ($icon + " " + (length | tostring)),
        tooltip: ([.[] | "\(.title) [\(.class)]"] | join("\n")),
        class: "has-items"
    }' "$LIST_FILE"
fi
