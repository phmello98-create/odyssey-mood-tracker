#!/bin/bash

# Script para integrar o sistema de backup automático com o Kitty terminal
# Uso: ./setup_kitty_integration.sh

KITTY_CONFIG_DIR="$HOME/.config/kitty"
KITTY_CONF="$KITTY_CONFIG_DIR/kitty.conf"

# Criar diretório do kitty se não existir
mkdir -p "$KITTY_CONFIG_DIR"

# Verificar se já existe uma linha de include
if grep -q "kitty_backup_integration.conf" "$KITTY_CONF" 2>/dev/null; then
    echo "Integração com o kitty já está configurada."
else
    # Adicionar a linha de include no início do arquivo
    if [ -f "$KITTY_CONF" ]; then
        # Fazer backup do arquivo atual
        cp "$KITTY_CONF" "$KITTY_CONF.backup"
        echo "# Integração com o sistema de backup do projeto Odyssey" > temp_kitty.conf
        echo "include /home/agyspc1/Documentos/app com opus 4.5 copia atual/kitty_backup_integration.conf" >> temp_kitty.conf
        cat "$KITTY_CONF" >> temp_kitty.conf
        mv temp_kitty.conf "$KITTY_CONF"
        echo "Integração adicionada ao kitty.conf e backup criado como kitty.conf.backup"
    else
        # Criar novo arquivo com a integração
        echo "# Integração com o sistema de backup do projeto Odyssey" > "$KITTY_CONF"
        echo "include /home/agyspc1/Documentos/app com opus 4.5 copia atual/kitty_backup_integration.conf" >> "$KITTY_CONF"
        echo "Arquivo kitty.conf criado com a integração."
    fi
fi

echo "Configuração completada! Reinicie o Kitty terminal para aplicar as alterações."