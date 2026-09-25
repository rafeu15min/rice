#!/usr/bin/env bash
#
# screenshot-window.sh — captura só a janela ativa (não a tela toda/região),
# copia pra área de transferência.

set -euo pipefail

geo=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
grim -g "$geo" - | wl-copy
notify-send "Captura Concluída" "Janela copiada para a área de transferência."
