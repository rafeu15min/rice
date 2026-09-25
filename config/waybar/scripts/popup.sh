#!/usr/bin/env bash
#
# popup.sh — abre (toggle) uma janela flutuante ancorada logo acima do
# botão da Waybar que disparou o clique, entrando com animação de baixo
# pra cima (como se saísse do próprio botão).
#
# A posição é definida ANTES da janela existir, via "hyprctl eval" (que
# roda uma declaração Lua completa, diferente de "hyprctl dispatch" que só
# aceita uma expressão de dispatcher). Isso injeta uma window rule com a
# coordenada já calculada -- se a gente só movesse a janela DEPOIS que ela
# abre, a animação de entrada tocaria no lugar errado (centro da tela) e
# ela "teleportaria" pro lugar certo em seguida, em vez de parecer que
# saiu do botão.
#
# Uso: popup.sh <classe> <largura> <altura> <comando...>
#   ex: popup.sh sys-cpu 850 550 alacritty -e htop --sort-key PERCENT_CPU

set -euo pipefail

CLASS="$1"; shift
W="$1"; shift
H="$1"; shift

ALL_CLASSES="sys-cpu|sys-mem|sys-vol|sys-net|sys-bt"
BAR_HEIGHT=40
GAP=8
EDGE_MARGIN=8

# Fecha qualquer popup já aberto entre os conhecidos (toggle)
open=$(hyprctl clients -j | jq -r --arg re "^($ALL_CLASSES)\$" '.[] | select(.class | test($re)) | .class')
for w in $open; do
    hyprctl dispatch "hl.dsp.window.close({window='class:$w'})" >/dev/null
done

# Se o alvo já estava aberto, o toggle acima já fechou -- não reabre
[[ "$open" == *"$CLASS"* ]] && exit 0

# Posição do cursor AGORA, ainda em cima do botão clicado
cursor=$(hyprctl cursorpos -j)
CX=$(jq -r '.x' <<< "$cursor")
CY=$(jq -r '.y' <<< "$cursor")

monitor=$(hyprctl monitors -j | jq '[.[] | select(.focused == true)] | first')
MX=$(jq -r '.x' <<< "$monitor")
MY=$(jq -r '.y' <<< "$monitor")
MW=$(jq -r '.width' <<< "$monitor")
MH=$(jq -r '.height' <<< "$monitor")

# Centraliza no cursor, espremido dentro dos limites do monitor
X=$(( CX - W / 2 ))
(( X < MX + EDGE_MARGIN )) && X=$(( MX + EDGE_MARGIN ))
(( X + W > MX + MW - EDGE_MARGIN )) && X=$(( MX + MW - W - EDGE_MARGIN ))

# Logo acima da barra (que fica colada embaixo)
Y=$(( MY + MH - BAR_HEIGHT - H - GAP ))
(( Y < MY + EDGE_MARGIN )) && Y=$(( MY + EDGE_MARGIN ))

hyprctl eval "hl.window_rule({ match = { class = '$CLASS' }, float = true, size = '$W $H', pin = true, move = '$X $Y', animation = 'slide bottom' })" >/dev/null

# --class precisa vir ANTES do "-e" (senão o Alacritty entende como
# argumento do programa interno, não como flag dele mesmo)
term="$1"; shift
"$term" --class "$CLASS" "$@" &
disown
