#!/usr/bin/env bash
#
# healthcheck.sh — confere se os processos essenciais da sessão Hyprland
# estão de pé (swaybg, hyprpolkitagent, portal, waybar, swaync, cliphist).
# Tenta resubir sozinho o que estiver caído; só notifica se achou algo
# errado (silencioso quando está tudo certo, pra não virar spam a cada
# hyprctl reload).

set -uo pipefail

WALLPAPER="/home/rafeu/Imagens/1Corintios(sombra).png"

restarted=()
failed=()

check() {
    local name="$1" test_cmd="$2" fix_cmd="$3"
    if eval "$test_cmd" >/dev/null 2>&1; then
        return
    fi
    eval "$fix_cmd" >/dev/null 2>&1 &
    disown
    sleep 1
    if eval "$test_cmd" >/dev/null 2>&1; then
        restarted+=("$name")
    else
        failed+=("$name")
    fi
}

check "swaybg (wallpaper)" \
    "pgrep -x swaybg" \
    "swaybg -i '$WALLPAPER' -m fill"

check "hyprpolkitagent" \
    "pgrep -f hyprpolkitagent" \
    "/usr/lib/hyprpolkitagent/hyprpolkitagent"

check "waybar" \
    "pgrep -x waybar" \
    "waybar"

check "swaync" \
    "pgrep -x swaync" \
    "swaync"

check "cliphist (texto)" \
    "pgrep -f 'wl-paste --type text --watch cliphist'" \
    "wl-paste --type text --watch cliphist store"

check "cliphist (imagem)" \
    "pgrep -f 'wl-paste --type image --watch cliphist'" \
    "wl-paste --type image --watch cliphist store"

check "portal Hyprland" \
    "systemctl --user is-active --quiet xdg-desktop-portal-hyprland.service" \
    "dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP; systemctl --user reset-failed xdg-desktop-portal-hyprland.service; systemctl --user restart xdg-desktop-portal-hyprland.service"

if [ ${#restarted[@]} -eq 0 ] && [ ${#failed[@]} -eq 0 ]; then
    exit 0
fi

body=""
if [ ${#restarted[@]} -gt 0 ]; then
    body+="Resubiu sozinho: $(IFS=', '; echo "${restarted[*]}")"$'\n'
fi
if [ ${#failed[@]} -gt 0 ]; then
    body+="AINDA CAÍDO (precisa olhar): $(IFS=', '; echo "${failed[*]}")"
fi

urgency="normal"
[ ${#failed[@]} -gt 0 ] && urgency="critical"

notify-send -u "$urgency" "Healthcheck Hyprland" "$body"
