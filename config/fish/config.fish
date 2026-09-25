# Caminho de Instalação: ~/.config/fish/config.fish

# =====================================================================
# 1. CONFIGURAÇÃO DE AMBIENTE
# =====================================================================
set -U fish_greeting ""

# =====================================================================
# 2. ESPECTRO TERMODINÂMICO (Os 50 Tons de Azul)
# =====================================================================
# A Âncora (Azul Profundo solicitado)
set -g fish_color_command 3F68EE --bold      # Azul Principal (#3F68EE)
set -g fish_color_operator 00BFFF --bold     # Azul Céu Intenso (Operadores)

# A Claridade (Azuis Pastéis e Gelo)
set -g fish_color_param A3D5FF               # Azul Céu Pastel (Parâmetros/Variáveis)
set -g fish_color_quote 7DB9E8               # Azul Suave (Strings)
set -g fish_color_valid_path 8BE9FD --underline # Ciano/Gelo (Caminhos válidos)

# Exceção Estrita (Mantido apenas para erros)
set -g fish_color_error E5A4AA               # Vermelho Pastel 

# Auxiliares
set -g fish_color_autosuggestion 5c6370      # Cinza frio
set -g fish_color_search_match --background=3F68EE # Fundo da pesquisa no Azul Principal

# =====================================================================
# 3. INTERFACE DO USUÁRIO (O Prompt de Comando)
# =====================================================================
function fish_prompt
    # Azul Principal (#3F68EE)
    set_color 3F68EE --bold
    echo -n $USER'@'(prompt_hostname)
    
    # Azul Gelo / Branco
    set_color E6F2FF
    echo -n ':'
    
    # Azul Suave
    set_color 7DB9E8
    echo -n (prompt_pwd)
    
    # Azul Céu Intenso para a seta
    set_color 00BFFF --bold
    echo -n ' ❯ '
    
    # Restaura para o Azul Céu Pastel para a escrita do usuário
    set_color A3D5FF
end

# =====================================================================
# 4. INTERCEPTAÇÃO E PRESERVAÇÃO DE ESTADO (Override do Exit)
# =====================================================================
function exit
    clear
    # Azul Principal
    set_color 3F68EE --bold
    echo "Ação Intercetada:"
    
    # Azul Céu Pastel
    set_color A3D5FF
    echo "O comando 'exit' foi desativado para evitar a destruição do processo do Alacritty."
    echo "Utilize o atalho do Bspwm/Hyprland para encerrar a janela física."
    echo ""
end

# =====================================================================
# 5. INFRAESTRUTURA DE WAKE-ON-LAN (Motor MQTT)
# =====================================================================
function turn-on
    if not test -f ~/.config/fish/wol.env
        set_color E5A4AA
        echo "Erro: ~/.config/fish/wol.env não encontrado (credenciais MQTT ausentes)."
        set_color A3D5FF
        return 1
    end
    source ~/.config/fish/wol.env
    set -l BROKER $WOL_MQTT_BROKER
    set -l USER $WOL_MQTT_USER
    set -l PASS $WOL_MQTT_PASS
    set -l TOPIC ""

    switch $argv[1]
        case "RafeuPC"
            set TOPIC "rafeu/infra/wol/7b44d28f-fb01-3d61-8cd9-560e8da569cb"
        case "FeuVault"
            set TOPIC "rafeu/infra/wol/1988e096-623e-3764-9981-abe254a77b2a"
        case "All"
            set TOPIC "rafeu/infra/wol/a1b2c3d4-e5f6-47a8-9b0c-1d2e3f4a5b6c"
        case "*"
            set_color E5A4AA # Vermelho pastel para erro
            echo "Uso: turn-on [RafeuPC | FeuVault | All]"
            set_color A3D5FF
            return 1
    end

    mosquitto_pub -h $BROKER -p 8883 --cafile /etc/ssl/certs/ca-certificates.crt \
        -u $USER -P $PASS -t $TOPIC -m "WAKE_ALACRITTY_NOW"
    
    set_color 3F68EE # Azul principal
    echo "Comando de despertar enviado para: $argv[1]"
    set_color A3D5FF
end

# =====================================================================
# 6. NOSTRVPN — TOGGLE DE EXIT NODE (FeuVault)
# =====================================================================
# Liga/desliga o serviço nvpn sob demanda. Fica desabilitado no boot por
# padrão (veja setup abaixo) porque o exit-node é full-tunnel: se a
# FeuVault estiver dormindo, o kill-switch (exit_node_leak_protection)
# derruba a rota padrão e mata a internet inteira até alguém rodar
# 'nvpn-exit off'.
function nvpn-exit
    switch $argv[1]
        case "on"
            set_color 3F68EE
            echo "Ligando NostrVPN (tráfego sai pelo exit-node da FeuVault)..."
            set_color A3D5FF
            sudo systemctl start nvpn.service
        case "off"
            set_color 3F68EE
            echo "Desligando NostrVPN e restaurando a rota direta..."
            set_color A3D5FF
            sudo systemctl stop nvpn.service
            and sudo nvpn repair-network
        case "*"
            set_color E5A4AA
            echo "Uso: nvpn-exit [on | off]"
            set_color A3D5FF
            return 1
    end
end
set -gx PATH $HOME/.local/bin $PATH


# Added by Antigravity CLI installer
set -gx PATH "/home/rafeu/.local/bin" $PATH
