#!/bin/bash

# Script para instalar ferramentas úteis para desenvolvimento do projeto Odyssey
# Uso: ./install_dev_tools.sh

echo "Instalando ferramentas úteis para desenvolvimento no Arch Linux..."

# Atualizar o sistema primeiro
sudo pacman -Sy

# Instalar pacotes úteis
packages=(
    "fzf"           # Fuzzy finder
    "bat"           # Cat com syntax highlighting
    "exa"           # Modern ls replacement
    "htop"          # Process viewer
    "glances"       # System monitoring
    "git-delta"     # Beautiful git diffs
    "lazygit"       # Git UI in terminal
    "bottom"        # Modern system monitor
    "ripgrep"       # Fast search tool (similar to grep)
    "fd"            # User-friendly find alternative
    "tokei"         # Lines of code counter
)

echo "Instalando pacotes principais..."
sudo pacman -S ${packages[@]} --noconfirm

# Instalar ferramentas via cargo (rust) se disponível
if command -v cargo &> /dev/null; then
    echo "Instalando ferramentas via cargo..."
    cargo install --list | grep -q "bandwhich" || cargo install bandwhich
else
    echo "Cargo não encontrado, instalando bandwhich via pacman se disponível..."
    sudo pacman -S bandwhich --noconfirm 2>/dev/null || echo "Bandwhich não disponível via pacman"
fi

# Verificar se zsh está instalado e configurar oh-my-zsh se presente
if command -v zsh &> /dev/null; then
    echo "Zsh encontrado, instalando Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh já está instalado."
    fi
fi

# Configurar starship prompt se não estiver configurado
if ! command -v starship &> /dev/null; then
    echo "Instalando starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship já está instalado."
fi

# Adicionar configurações úteis ao shell
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
fi

if [ -n "$SHELL_CONFIG" ]; then
    echo "Adicionando configurações extras ao $SHELL_CONFIG..."
    
    # Adicionar configurações úteis
    echo "" >> $SHELL_CONFIG
    echo "# Configurações extras para desenvolvimento do Odyssey" >> $SHELL_CONFIG
    echo "alias cat='bat'" >> $SHELL_CONFIG
    echo "alias ls='exa --icons'" >> $SHELL_CONFIG
    echo "alias l='exa -la --icons'" >> $SHELL_CONFIG
    echo "alias grep='rg'" >> $SHELL_CONFIG
    echo "alias find='fd'" >> $SHELL_CONFIG
    
    # Configurar fzf
    if command -v fzf &> /dev/null && [ -f "/usr/share/fzf/key-bindings.zsh" ]; then
        echo "[ -f /usr/share/fzf/key-bindings.zsh ] && source /usr/share/fzf/key-bindings.zsh" >> $SHELL_CONFIG
        echo "[ -f /usr/share/fzf/completion.zsh ] && source /usr/share/fzf/completion.zsh" >> $SHELL_CONFIG
    fi
    
    # Configurar git-delta
    git config --global core.pager "delta"
    git config --global interactive.diffFilter "delta --color-only"
    git config --global delta.navigate "true"
    git config --global delta.side-by-side "true"
fi

# Configurar starship
if command -v starship &> /dev/null; then
    echo "Configurando starship..."
    if [ ! -f "$HOME/.config/starship.toml" ]; then
        mkdir -p "$HOME/.config"
        echo '[git_branch]
format = "via [$symbol$branch]($style) "
symbol = "🌱 "

[git_status]
format = "[\[$all_status$ahead_behind\]]($style) "
' > "$HOME/.config/starship.toml"
    fi
    
    # Adicionar inicialização do starship ao shell config
    if ! grep -q "starship init" "$SHELL_CONFIG"; then
        echo 'eval "$(starship init bash)"' >> $SHELL_CONFIG
    fi
fi

echo "Instalação concluída!"
echo ""
echo "Reinicie seu terminal ou execute:"
echo "source $SHELL_CONFIG"
echo ""
echo "Ferramentas instaladas:"
echo "- fzf: fuzzy finder para navegação"
echo "- bat: exibição de arquivos com syntax highlighting"
echo "- exa: ls moderno com ícones"
echo "- htop/glances: monitores de sistema"
echo "- lazygit: interface gráfica para git no terminal"
echo "- tokei: contador de linhas de código"
echo "- ripgrep: busca rápida de texto"
echo "- fd: alternativa amigável para find"
echo "- delta: diffs bonitos do git"
echo "- starship: prompt personalizado (execute 'starship init zsh' ou 'starship init bash')"