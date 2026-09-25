#!/bin/sh
# workspace-watch.sh -- escuta o socket2 de eventos do Hyprland e manda
# SIGRTMIN+8 pro Waybar assim que uma workspace muda, pra custom/ws1..9
# (workspace-button.sh) reagirem na hora em vez de esperar o "interval"
# do polling (era isso que causava duas bolinhas azuis por até 1s depois
# do clique/atalho -- cada módulo só se atualizava sozinho, sem
# sincronia, no próximo tick do polling). O "interval" continua existindo
# como rede de segurança (evento perdido), só bem mais espaçado agora.

set -eu

nc -U "$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | \
while IFS= read -r line; do
    case "$line" in
        workspace\>\>*|focusedmon\>\>*|createworkspace\>\>*|destroyworkspace\>\>*)
            pkill -RTMIN+8 waybar 2>/dev/null || true
            ;;
    esac
done
