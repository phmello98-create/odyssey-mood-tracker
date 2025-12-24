#!/bin/bash

# Cores e Estilos
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
RESET="\033[0m"

# Spinners
SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')

# Função para delay estilizado
function delay() {
    sleep 0.5
}

# Print com estilo de sucesso
function print_success() {
    echo -e "${GREEN}✅ $1${RESET}"
}

# Print com estilo de erro
function print_error() {
    echo -e "${RED}❌ $1${RESET}"
}

# Print com estilo de aviso
function print_warning() {
    echo -e "${YELLOW}⚠️  $1${RESET}"
}

# Print com estilo de info
function print_info() {
    echo -e "${CYAN}ℹ️  $1${RESET}"
}

# Print de título
function print_title() {
    echo ""
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${RESET}"
    echo -e "${BOLD}${MAGENTA}   $1${RESET}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════════${RESET}"
    echo ""
}

# Spinner animado para processos longos
# Uso: comando & run_with_spinner $! "Mensagem"
function run_with_spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    # Hide cursor
    tput civis
    
    while ps -p $pid > /dev/null; do
        local temp=${spinstr:i++%${#spinstr}:1}
        printf "\r${CYAN} [%c]  %s...${RESET}" "$temp" "$message"
        sleep $delay
    done
    
    # Show cursor
    tput cnorm
    printf "\r\033[K" # Limpa a linha
}

# Logo da Odyssey em ASCII
function print_logo_dev() {
    echo -e "${YELLOW}"
    echo "   ____  ____  __  __  _____ _____ ______   __  "
    echo "  / __ \|  _ \|  \/  |/ ____/ ____|  ____| \  / "
    echo " | |  | | |_) | \  / | (___| (___ | |__     \  /  "
    echo " | |  | |  _ <| |\/| |\___ \\___ \|  __|    |  |  "
    echo " | |__| | |_) | |  | |____) |___) | |____   |  |  "
    echo "  \____/|____/|_|  |_|_____/_____/|______|  |__|  "
    echo -e "${RESET}"
    echo -e "${CYAN}   >>> DEV EDITION - UNLEASH THE CODE <<< ${RESET}"
}

function print_logo_prod() {
    echo -e "${BLUE}"
    echo "   ____  ____  __  __  _____ _____ ______   __  "
    echo "  / __ \|  _ \|  \/  |/ ____/ ____|  ____| \  / "
    echo " | |  | | |_) | \  / | (___| (___ | |__     \  /  "
    echo " | |  | |  _ <| |\/| |\___ \\___ \|  __|    |  |  "
    echo " | |__| | |_) | |  | |____) |___) | |____   |  |  "
    echo "  \____/|____/|_|  |_|_____/_____/|______|  |__|  "
    echo -e "${RESET}"
    echo -e "${GREEN}   >>> PRODUCTION BUILD - SHIP IT! <<< ${RESET}"
}
