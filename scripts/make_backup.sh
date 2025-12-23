#!/bin/bash

# Configurações
BACKUP_DIR="/home/agys/Documentos/Backups Diario Odyssey"
PROJECT_DIR=$(pwd)
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_FILE="$BACKUP_DIR/odyssey_backup_$TIMESTAMP.tar.gz"

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Iniciando backup do Odyssey...${NC}"
echo "Diretório de destino: $BACKUP_DIR"

# Cria o diretório de backup se não existir
if [ ! -d "$BACKUP_DIR" ]; then
    echo "Criando diretório de backup..."
    mkdir -p "$BACKUP_DIR"
fi

# Executa o backup
# Exclui pastas de build, versionamento e dependências temporárias para economizar espaço
tar --exclude='./build' \
    --exclude='./.dart_tool' \
    --exclude='./.git' \
    --exclude='./.gradle' \
    --exclude='./.idea' \
    --exclude='./ios/Pods' \
    --exclude='./linux/flutter/ephemeral' \
    --exclude='./macos/Flutter/ephemeral' \
    --exclude='./windows/flutter/ephemeral' \
    --exclude='./backups' \
    --exclude='./analysis.txt' \
    -czf "$BACKUP_FILE" .

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo -e "${GREEN}✅ Backup concluído com sucesso!${NC}"
    echo "Arquivo: $BACKUP_FILE"
    echo "Tamanho: $SIZE"
else
    echo -e "\033[0;31m❌ Erro ao criar backup.${NC}"
    exit 1
fi
