#!/bin/bash

# Script de backup automático para o projeto Odyssey
# Monitora alterações e faz commits automáticos

PROJECT_DIR="/home/agyspc1/Documentos/app com opus 4.5 copia atual"
LOG_FILE="$PROJECT_DIR/auto_backup.log"
BACKUP_INTERVAL=300  # 5 minutos em segundos

# Função para fazer commit automático
auto_commit() {
    cd "$PROJECT_DIR"
    
    # Verificar se há alterações
    if [[ -n $(git status --porcelain) ]]; then
        echo "$(date): Detectadas alterações, fazendo commit automático" >> "$LOG_FILE"
        
        # Adicionar todas as alterações
        git add .
        
        # Fazer commit com mensagem automática
        git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
        
        # Registrar no log
        echo "$(date): Commit automático realizado com sucesso" >> "$LOG_FILE"
        
        # Opcional: fazer push se estiver usando repositório remoto
        # git push origin main 2>> "$LOG_FILE"
    else
        echo "$(date): Nenhuma alteração detectada" >> "$LOG_FILE"
    fi
}

# Função para monitorar alterações em tempo real
monitor_changes() {
    cd "$PROJECT_DIR"
    
    # Usar inotifywait para monitorar alterações
    inotifywait -m -r -e modify,create,delete,move --include='.*\.(dart|yaml|md|txt|sh|py|json|toml)$' "$PROJECT_DIR" 2>/dev/null &
    
    INOTIFY_PID=$!
    
    echo "Monitoramento iniciado (PID: $INOTIFY_PID)"
    echo "Pressione Ctrl+C para parar"
    
    # Loop para verificar alterações a cada intervalo definido
    while true; do
        sleep $BACKUP_INTERVAL
        auto_commit
    done
}

# Configurar git se ainda não estiver configurado
setup_git() {
    cd "$PROJECT_DIR"
    
    # Verificar se é um repositório git
    if [[ ! -d .git ]]; then
        git init
        git add .
        git commit -m "Initial commit: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Repositório Git inicializado"
    fi
    
    # Configurar usuário do git se necessário
    if [[ -z $(git config --global user.name) ]]; then
        git config --global user.name "Auto Backup System"
        git config --global user.email "backup@system.local"
    fi
}

# Função para exibir status
show_status() {
    cd "$PROJECT_DIR"
    echo "Status do repositório:"
    git status --short
    echo "Últimos commits:"
    git log --oneline -n 5
}

# Verificar argumentos
case "${1:-monitor}" in
    "monitor")
        setup_git
        monitor_changes
        ;;
    "commit")
        setup_git
        auto_commit
        ;;
    "status")
        setup_git
        show_status
        ;;
    "setup")
        setup_git
        echo "Repositório configurado para backup automático"
        ;;
    *)
        echo "Uso: $0 [monitor|commit|status|setup]"
        echo "  monitor - Inicia o monitoramento e backup automático"
        echo "  commit  - Faz um commit automático imediato"
        echo "  status  - Mostra o status do repositório"
        echo "  setup   - Configura o repositório Git"
        ;;
esac