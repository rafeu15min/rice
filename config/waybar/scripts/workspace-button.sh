#!/bin/sh
# workspace-button.sh <N> — estado JSON de UM botão de workspace pro Waybar
# (custom/ws1..9, dentro de group/workspaces). Existe porque o módulo
# nativo "hyprland/workspaces" manda "hyprctl dispatch workspace N"
# (sintaxe clássica) no clique, que essa build Lua do Hyprland rejeita
# (")' expected near 'N'") -- confirmado ao vivo 2026-08-29, issues abertas
# Alexays/Waybar#5008 e #3599, sem override de on-click no módulo nativo.
#
# Só imprime saída quando a workspace N EXISTE de verdade (o Hyprland
# destrói workspace vazia e não-focada sozinho) -- sem saída nenhuma, o
# Waybar esconde o módulo, reproduzindo o comportamento original de só
# mostrar as abertas (era isso que o módulo nativo já fazia).

set -eu
n="$1"

exists=$(hyprctl workspaces -j | python3 -c "
import json,sys
ws = json.load(sys.stdin)
print('1' if any(w['id'] == $n for w in ws) else '')
")

if [ -z "$exists" ]; then
    # Sempre imprime JSON válido (nunca saída vazia) -- output realmente
    # vazio quebrava o "group/workspaces" inteiro no Waybar (testado ao
    # vivo: os 3 módulos com JSON válido também sumiam). Texto vazio
    # ("") ainda esconde visualmente, sem quebrar o grupo.
    printf '{"text":"","class":"hidden","tooltip":""}\n'
    exit 0
fi

active=$(hyprctl activeworkspace -j | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")

if [ "$active" = "$n" ]; then
    # nf-fa-dot-circle-o (U+F192) -- círculo com anel, workspace ativa.
    # Via \u explícito (não o glyph colado direto) -- já vi esse byte
    # sumir silenciosamente no editor nesta sessão (virou "text":"").
    icon=$(printf '')
    class="active"
else
    # nf-fa-circle (U+F111) -- círculo preenchido, workspace ocupada.
    icon=$(printf '')
    class="occupied"
fi

printf '{"text":"%s","class":"%s","tooltip":"Workspace %s"}\n' "$icon" "$class" "$n"
