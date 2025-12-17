#!/bin/bash

# Script para iniciar o backup automático em segundo plano
# Uso: ./start_auto_backup.sh [stop|status]

# Usando um nome de arquivo PID sem espaços para evitar problemas
PID_FILE="/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual/auto_backup.pid"
SCRIPT_PATH="/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual/auto_backup.sh"

# Substituir espaços por underlines no caminho
PROJECT_DIR="/home/agyspc1/Documentos/app com opus 4.5 copia atual"
ESCAPED_PROJECT_DIR="/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual"

# Criar link simbólico com nome sem espaços se necessário
if [ ! -d "/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual" ]; then
    ln -sf "$PROJECT_DIR" "/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual"
fi

# Atualizar caminhos para usar o diretório sem espaços
PID_FILE="/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual/auto_backup.pid"
SCRIPT_PATH="/home/agyspc1/Documentos/app_com_opus_4_5_copia_atual/auto_backup.sh"

# Certificar-se de que os caminhos corretos são usados
REAL_PROJECT_DIR=$(readlink -f "$PROJECT_DIR")

case "${1:-start}" in
    "start")
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                echo "Sistema de backup automático já está rodando (PID: $PID)"
                exit 1
            else
                # Remover PID file se o processo não estiver mais ativo
                rm -f "$PID_FILE"
            fi
        fi

        echo "Iniciando sistema de backup automático..."
        cd "$REAL_PROJECT_DIR"
        nohup "$REAL_PROJECT_DIR/auto_backup.sh" monitor > "$REAL_PROJECT_DIR/auto_backup.log" 2>&1 &
        NEW_PID=$!
        echo $NEW_PID > "$PID_FILE"
        echo "Sistema de backup automático iniciado (PID: $NEW_PID)"
        ;;
    "stop")
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                kill "$PID"
                echo "Sistema de backup automático parado (PID: $PID)"
            else
                echo "Processo não encontrado (PID: $PID)"
            fi
            rm -f "$PID_FILE"
        else
            echo "Sistema de backup automático não está rodando"
        fi
        ;;
    "status")
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 "$PID" 2>/dev/null; then
                echo "Sistema de backup automático está rodando (PID: $PID)"
                ps -p "$PID" -o pid,ppid,cmd,etime,pcpu,pmem 2>/dev/null || echo "Não foi possível obter detalhes do processo"
            else
                echo "PID file encontrado (PID: $PID) mas processo não está ativo"
                rm -f "$PID_FILE"
            fi
        else
            echo "Sistema de backup automático não está rodando"
        fi
        ;;
    *)
        echo "Uso: $0 [start|stop|status]"
        ;;
esac