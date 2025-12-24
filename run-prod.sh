#!/bin/bash
source "$(dirname "$0")/scripts/ui_utils.sh"

set -e

clear
print_logo_prod
print_title "🚀 PREPARANDO LANÇAMENTO PROD"

# Export vars
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin"

FLUTTER_BIN="$HOME/flutter/bin/flutter"
if [ ! -f "$FLUTTER_BIN" ]; then
    FLUTTER_BIN="flutter"
fi
ADB_BIN=""
if [ -f "$ANDROID_HOME/platform-tools/adb" ]; then
    ADB_BIN="$ANDROID_HOME/platform-tools/adb"
elif command -v adb &> /dev/null; then
    ADB_BIN=$(command -v adb)
fi

# Temp file for logs
LOG_FILE=$(mktemp)

# Check Devices
echo -e "${BLUE}🔍 Verificando sistemas de lançamento...${RESET}"
$FLUTTER_BIN devices > "$LOG_FILE" 2>&1 &
run_with_spinner $! "Escaneando alvos"

DEVICES=$(cat "$LOG_FILE")
ANDROID_COUNT=$(echo "$DEVICES" | grep -c "android" || true)

if [ "$ANDROID_COUNT" -eq 0 ]; then
    print_warning "Nenhum dispositivo detectado."
    
    if [ -n "$ADB_BIN" ]; then
        echo -e "${MAGENTA}📡 Tentar conexão Wi-Fi de emergência? (s/N)${RESET}"
        read -t 5 -r CONNECT_WIFI || CONNECT_WIFI="n"
        
        if [[ "$CONNECT_WIFI" =~ ^[sS]$ ]]; then
            echo ""
            echo -e "${CYAN}📝 Coordenadas IP [padrão: 192.168.18.50:5555]:${RESET}"
            read -r DEVICE_IP_PORT
            
            if [ -z "$DEVICE_IP_PORT" ]; then
                DEVICE_IP_PORT="192.168.18.50:5555"
            fi
            
            echo -e "${YELLOW}🚀 Conectando...${RESET}"
            $ADB_BIN connect "$DEVICE_IP_PORT" > "$LOG_FILE" 2>&1 &
            run_with_spinner $! "Iniciando uplink"
            
            $FLUTTER_BIN devices > "$LOG_FILE" 2>&1 &
            run_with_spinner $! "Verificando conexão"
            
            DEVICES=$(cat "$LOG_FILE")
            ANDROID_COUNT=$(echo "$DEVICES" | grep -c "android" || true)
        fi
    fi
fi

if [ "$ANDROID_COUNT" -eq 0 ]; then
    print_error "Abortar lançamento. Nenhum alvo encontrado."
    rm "$LOG_FILE"
    exit 1
fi

print_success "Alvo Confirmado!"
delay

# Infos
echo ""
echo -e "${GREEN}📦 Flavor:${RESET}   PROD"
echo -e "${GREEN}🎯 Target:${RESET}   lib/main_prod.dart"
echo -e "${GREEN}🏷️  ID:${RESET}       io.odyssey.moodtracker"
echo ""

print_title "🌟 DECOLAR"
echo -e "${CYAN}Iniciando sequência de build final...${RESET}"

# Run
$FLUTTER_BIN run --flavor prod -t lib/main_prod.dart "$@"

# Cleanup
rm "$LOG_FILE"
print_success "Missão cumprida!"
