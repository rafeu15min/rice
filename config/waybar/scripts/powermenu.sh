#!/usr/bin/env bash

escolha=$(echo -e "Desligar\nReiniciar\nSuspender\nSair" | rofi -dmenu -i -p "Sistema")

case "$escolha" in
    "Desligar") systemctl poweroff ;;
    "Reiniciar") systemctl reboot ;;
    "Suspender") systemctl suspend ;;
    "Sair") hyprctl dispatch "hl.dsp.exit()" ;;
esac
