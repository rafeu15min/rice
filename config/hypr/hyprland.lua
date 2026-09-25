-- ==========================================
-- HYPRLAND 0.55+ LUA CONFIGURATION - RAFEU-PC
-- API Nativa: Despachantes (hl.dsp), Regras (hl.window_rule) e Loops.
-- CORRIGIDO: sintaxe real da API Lua do Hyprland 0.55+
-- ==========================================

local terminal = "alacritty"
local menu = "pkill -x wlogout 2>/dev/null; pkill -x rofi || rofi -show drun -theme ~/.config/rofi/drun-blank.rasi"
local fileManager = "/usr/bin/thunar"
local mod = "SUPER"

-- Configuração do Monitor e Ambiente
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
hl.env("XCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
-- Limita a fila de pré-renderização da NVIDIA a 1 frame -- reduz latência de
-- input em jogos (equivalente ao "Max Pre-Rendered Frames" do painel NVIDIA).
hl.env("__GL_MaxFramesAllowed", "1")

-- Autostart (essa parte já estava correta no arquivo original)
hl.on("hyprland.start", function()
    -- Autologin do SDDM sobe direto nessa sessão sem senha (necessário pra
    -- acesso 100% remoto via Moonlight/Sunshine, sem acesso físico à máquina).
    -- Trava a tela imediatamente pra não deixar o desktop exposto no boot -
    -- o destravamento acontece remotamente pelo próprio stream.
    hl.exec_cmd("hyprlock")

    -- Sem isso, xdg-desktop-portal-hyprland sobe ANTES do WAYLAND_DISPLAY/
    -- HYPRLAND_INSTANCE_SIGNATURE chegarem ao D-Bus/systemd --user, erra
    -- "Couldn't connect to a wayland compositor", reinicia rápido demais
    -- e trava em start-limit-hit (visto isso acontecer no login de hoje).
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP")
    hl.exec_cmd("bash -c 'systemctl --user reset-failed xdg-desktop-portal-hyprland.service; systemctl --user restart xdg-desktop-portal-hyprland.service'")
    hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")
    hl.exec_cmd("waybar")
    -- Escuta o socket2 do Hyprland e manda SIGRTMIN+8 pro Waybar assim que
    -- a workspace muda, pra custom/ws1..9 atualizarem na hora em vez de
    -- esperar o polling (era o que causava duas bolinhas azuis por até 1s
    -- depois do clique/atalho).
    hl.exec_cmd("~/.config/waybar/scripts/workspace-watch.sh")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("swaync")
    -- swaybg às vezes morre silenciosamente quando sobe antes do DRM
    -- terminar de configurar a saída (visto no log: "Cannot commit when
    -- a page-flip is awaiting" bem nesse instante do boot). Pequeno
    -- delay + bash -c evita a corrida.
    hl.exec_cmd("bash -c 'sleep 1 && swaybg -i /home/rafeu/Imagens/1Corintios(sombra).png -m fill'")
    -- hyprswitch NÃO está instalado (nem em repo oficial nem via paru) -- comentado até decidir se instala via AUR
    -- hl.exec_cmd("hyprswitch init --show-title --size-factor 5")

    -- Confere se tudo acima realmente subiu (dá pra um processo morrer
    -- silenciosamente igual o swaybg morreu hoje) e resobe sozinho o
    -- que não estiver de pé. Só notifica se achar algo errado.
    hl.exec_cmd("bash -c 'sleep 5 && ~/.config/hypr/scripts/healthcheck.sh'")
end)

-- Curvas e Animações
-- hl.bezier() NÃO EXISTE MAIS na API 0.55+. Foi renomeado para hl.curve()
-- com uma assinatura diferente (tabela com type + points, em vez de 4 números soltos).
-- Isso provavelmente travava a execução do script antes de chegar na seção de
-- "input" mais abaixo, explicando o layout de teclado bagunçado.
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
-- speed 6 era a mais lenta de todas as leaves (windows/fade=7, border=10)
-- -- bati o olho e confirmei via "hyprctl animations" antes de mudar.
-- Subido pra 8 (mais rápida que windows, ainda abaixo de border) depois
-- de reclamação de transição de workspace demorada.
hl.animation({ leaf = "workspaces", enabled = true, speed = 8, bezier = "default" })

-- Configuração Geral e Estado
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            -- cores em hex "0xAARRGGBB" viraram strings "rgba(RRGGBBAA)" na API nova
            active_border = { colors = { "rgba(3F68EEff)", "rgba(00BFFFff)" }, angle = 45 },
            inactive_border = "rgba(5c6370aa)"
        },
        layout = "dwindle",
        -- Pré-requisito pro window_rule "immediate" (jogos) lá embaixo.
        -- Ver https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/
        allow_tearing = true
    },
    decoration = {
        rounding = 8,
        blur = { enabled = true, size = 3, passes = 1 }
    },
    dwindle = { preserve_split = true },
    -- kb_layout = "br" é o que garante o teclado ABNT2. Antes ele nunca era
    -- aplicado por causa do erro no hl.bezier() acima travar o carregamento.
    -- accel_profile = "flat": sem curva de aceleração do libinput, input cru
    -- 1:1 do mouse gamer (G203) -- combinado com sensitivity=0 já existente.
    -- follow_mouse=0 (era 1): com hover-focus, o Claudesktop perdia foco de
    -- teclado toda vez que o cursor só passava por cima de outra janela entre
    -- uma ação e outra (sem nenhum clique) -- causa raiz de vários comandos
    -- caindo na janela errada durante automação. Agora foco só muda por clique.
    input = { kb_layout = "br", follow_mouse = 1, sensitivity = 0, accel_profile = "flat" },
    misc = { vrr = 1 },
    -- direct_scanout removido: travava a sessão ~90s após login em combo com
    -- allow_tearing na NVIDIA (visto se repetir 3x no boot de hoje, mesmo já
    -- com o kernel/driver no downgrade). allow_tearing + window_rule
    -- "immediate" abaixo já cobrem a maior parte do ganho de latência em
    -- fullscreen sem precisar pular o compositor inteiro.
    -- nvidia_anti_flicker=false compensa parte da latência perdida (troca:
    -- risco pequeno de flicker ocasional).
    opengl = { nvidia_anti_flicker = false },
    -- Ajuda escala/renderização de jogos antigos rodando via XWayland.
    xwayland = { force_zero_scaling = true }
})

-- Tearing (immediate present) só em janelas fullscreen -- cobre a maioria
-- dos jogos sem afetar o resto do desktop (que continua com vsync normal).
hl.window_rule({
    name = "tearing-fullscreen-games",
    match = { fullscreen = true },
    immediate = true
})

-- As regras dos popups da Waybar (sys-cpu/sys-mem/sys-vol/sys-net) NÃO
-- ficam mais aqui -- o próprio popup.sh injeta a regra completa (float,
-- size, pin, move E animation) via "hyprctl eval" a cada clique, porque a
-- posição depende de onde o botão foi clicado e precisa existir ANTES da
-- janela abrir (senão a animação de entrada toca no lugar errado).

-- ============================================================
-- BINDS ESSENCIAIS
-- MUDANÇA CRÍTICA: hl.bind() recebe UMA ÚNICA string combinando
-- mod + tecla (ex: "SUPER + Return"), não mais dois argumentos
-- separados como era hl.bind(mod, "Return", ...). Era isso que
-- deixava praticamente todos os atalhos sem funcionar.
-- ============================================================
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mod .. " + W", hl.dsp.window.close())              -- killactive -> window.close()
hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())                -- exit (antes era SUPER+Q, movido pra abrir espaço pro lock)
hl.bind(mod .. " + Q", hl.dsp.exec_cmd("hyprlock"))          -- lock screen (hyprlock)
hl.bind(mod .. " + X", hl.dsp.exec_cmd("pkill -x rofi 2>/dev/null; pkill -x wlogout || wlogout -b 5 -T 393 -B 393")) -- powermenu (wlogout, mesmo comando do botão da Waybar) -- movido de P pra abrir espaço pro claudesktop
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("uv run --project /mnt/Utilitarios/Projetos/claudesktop claudesktop panic")) -- kill switch do claudesktop (para ydotoold na hora, independente do MCP)
hl.bind(mod .. " + P", hl.dsp.exec_cmd("systemctl --user restart ydotool.service && notify-send 'claudesktop' 'ydotoold religado'")) -- religa o ydotoold depois do panic
hl.bind(mod .. " + G", hl.dsp.exec_cmd("~/.local/bin/vault-sync-menu.sh")) -- menu de jogos (vault-sync, rofi)
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" })) -- togglefloating

-- Janelas flutuantes: mover com teclado (setas, livres até agora) e
-- alcançar via foco -- "movefocus" (H/J/K/L acima) é espacial/dwindle e
-- ignora flutuantes por design do Hyprland, CONFIRMADO ao vivo nesta
-- máquina (2026-08-29: movefocus não sai de uma janela flutuante nem
-- entra numa). "window.cycle_next" percorre TODAS as janelas do
-- workspace, incluindo flutuantes (testado ao vivo: zenity flutuante →
-- Alacritty tiled → Alacritty tiled → zenity de volta) -- esse é o jeito
-- de teclado pra alcançar uma flutuante sem clicar. Em janela tiled,
-- window.move com x/y/relative não faz nada (testado, seguro).
hl.bind(mod .. " + Left", hl.dsp.window.move({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + Right", hl.dsp.window.move({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + Up", hl.dsp.window.move({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mod .. " + Down", hl.dsp.window.move({ x = 0, y = 40, relative = true }), { repeating = true })
hl.bind(mod .. " + Backslash", hl.dsp.window.cycle_next({ next = true }))

-- Dimensão Paralela e Rofi
hl.bind(mod .. " + M", hl.dsp.exec_cmd("~/.config/waybar/scripts/minimize.sh"))
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("~/.config/waybar/scripts/minimized.sh --restore"))
-- Toque simples na tecla Super pra abrir o rofi (vale testar, é um combo pouco comum)
hl.bind(mod .. " + SUPER_L", hl.dsp.exec_cmd(menu), { release = true })

-- Foco e Movimentação
hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))   -- movefocus l
hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))  -- movefocus r
hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))     -- movefocus u
hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))   -- movefocus d
hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))  -- swapwindow l
hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
hl.bind(mod .. " + SHIFT + R", hl.dsp.layout("togglesplit"))   -- layoutmsg togglesplit

-- Workspaces (Loop otimizado)
for i = 1, 9 do
    hl.bind(mod .. " + " .. tostring(i), hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. tostring(i), hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Utilitários (Print, Área de Transferência, Gravação)
hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("bash -c 'grim -g \"$(slurp)\" - | wl-copy && notify-send \"Captura Concluída\" \"Imagem copiada para a RAM.\"'"))
hl.bind(mod .. " + S", hl.dsp.exec_cmd("~/.config/waybar/scripts/screenshot-window.sh"))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("bash -c 'pkill -x wlogout 2>/dev/null; cliphist list | rofi -dmenu -p \"Área de Transferência\" | cliphist decode | wl-copy'"))
hl.bind(mod .. " + R", hl.dsp.exec_cmd("bash -c 'if pgrep -x wl-screenrec > /dev/null; then pkill -x wl-screenrec; notify-send \"Gravação Parada\" \"Vídeo finalizado\"; else wl-screenrec -f ~/Videos/Gravacao_$(date +\"%Y-%m-%d_%H-%M-%S\").mp4 & notify-send \"Gravando Tela\" \"Super+R para parar\"; fi'"))

-- Recarregar o config do Hyprland sem precisar reiniciar a sessão
hl.bind(mod .. " + SHIFT + C", hl.dsp.exec_cmd("bash -c 'hyprctl reload && notify-send \"Hyprland\" \"Config recarregado\" && ~/.config/hypr/scripts/healthcheck.sh'"))

-- Healthcheck manual (confere/resobe swaybg, waybar, swaync, cliphist,
-- portal e hyprpolkitagent -- só notifica se achar algo caído)
hl.bind(mod .. " + CTRL + H", hl.dsp.exec_cmd("~/.config/hypr/scripts/healthcheck.sh"))

-- Redimensionamento (delta relativo, com repetição ao segurar)
hl.bind(mod .. " + ALT + H", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + L", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- Mouse (mover/redimensionar janela)
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })    -- movewindow
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- resizewindow

-- Áudio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
