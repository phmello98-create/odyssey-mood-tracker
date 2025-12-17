#!/bin/bash
# Auto-Save Watch - Monitora e salva mudanças automaticamente

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[$(date +%H:%M:%S)]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date +%H:%M:%S)]${NC} $1"
}

print_error() {
    echo -e "${RED}[$(date +%H:%M:%S)]${NC} $1"
}

# Verificar se está em um repositório Git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Não é um repositório Git!"
    exit 1
fi

# Configurações
WATCH_DIR=$(pwd)
BRANCH=$(git branch --show-current)
LOG_FILE="$WATCH_DIR/.auto-save.log"
INTERVAL=300  # 5 minutos em segundos
LAST_SAVE_FILE="$WATCH_DIR/.last-save-time"

# Banner
clear
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🤖 AUTO-SAVE ATIVO - ODYSSEY"
echo "  📁 Diretório: $WATCH_DIR"
echo "  🌿 Branch: $BRANCH"
echo "  ⏰ Intervalo: ${INTERVAL}s ($(($INTERVAL / 60))min)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_info "Monitorando mudanças... (Ctrl+C para parar)"
print_info "Log: $LOG_FILE"
echo ""

# Inicializar timestamp
echo "$(date +%s)" > "$LAST_SAVE_FILE"

# Função de auto-save
auto_save() {
    # Verificar se há mudanças
    if ! git diff-index --quiet HEAD --; then
        print_warning "🔔 Mudanças detectadas!"
        
        # Mostrar arquivos modificados (máximo 5)
        git status -s | head -5 | while read line; do
            echo "     $line"
        done
        
        # Contar arquivos modificados
        num_files=$(git status -s | wc -l)
        if [ $num_files -gt 5 ]; then
            echo "     ... e mais $((num_files - 5)) arquivo(s)"
        fi
        
        # Fazer commit automático
        local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
        local commit_msg="🤖 Auto-save: $timestamp"
        
        git add -A
        git commit -m "$commit_msg" --quiet
        
        if [ $? -eq 0 ]; then
            print_status "✓ Mudanças salvas automaticamente!"
            echo "$(date +%s)" > "$LAST_SAVE_FILE"
            
            # Log
            echo "[$(date)] Auto-save realizado - $num_files arquivo(s)" >> "$LOG_FILE"
            
            # Notificação desktop (se disponível)
            if command -v notify-send &> /dev/null; then
                notify-send "Odyssey Auto-Save" "Mudanças salvas! 📝" -i dialog-information -t 2000
            fi
        else
            print_error "✗ Erro ao salvar"
            echo "[$(date)] ERRO ao fazer auto-save" >> "$LOG_FILE"
        fi
    else
        print_info "✓ Nenhuma mudança para salvar"
    fi
}

# Trap para cleanup
cleanup() {
    echo ""
    print_info "Parando monitor..."
    echo "[$(date)] Monitor parado" >> "$LOG_FILE"
    exit 0
}

trap cleanup SIGINT SIGTERM

# Loop principal
while true; do
    # Calcular tempo desde último save
    if [ -f "$LAST_SAVE_FILE" ]; then
        last_save=$(cat "$LAST_SAVE_FILE")
        current_time=$(date +%s)
        elapsed=$((current_time - last_save))
        
        if [ $elapsed -ge $INTERVAL ]; then
            echo ""
            auto_save
            echo ""
        else
            remaining=$((INTERVAL - elapsed))
            minutes=$((remaining / 60))
            seconds=$((remaining % 60))
            printf "\r  Próximo save em: %02d:%02d  " $minutes $seconds
        fi
    else
        auto_save
    fi
    
    # Aguardar antes da próxima verificação
    sleep 5  # Verificar a cada 5 segundos
done
