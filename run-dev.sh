#!/bin/bash
source "$(dirname "$0")/scripts/ui_utils.sh"

set -e

# Clear screen for dramatic effect
clear
print_logo_dev
print_title "🛠️  INICIANDO AMBIENTE DEV"

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
echo -e "${BLUE}🔍 Escaneando o multiverso por dispositivos...${RESET}"
$FLUTTER_BIN devices > "$LOG_FILE" 2>&1 &
run_with_spinner $! "Buscando sinais de vida Android"

DEVICES=$(cat "$LOG_FILE")
ANDROID_COUNT=$(echo "$DEVICES" | grep -c "android" || true)

if [ "$ANDROID_COUNT" -eq 0 ]; then
    print_warning "Nenhum Android detectado via cabos terrenos."
    
    if [ -n "$ADB_BIN" ]; then
        echo -e "${MAGENTA}📡 Iniciar protocolo de conexão Wi-Fi Interestelar? (s/N)${RESET}"
        read -t 5 -r CONNECT_WIFI || CONNECT_WIFI="n"
        
        if [[ "$CONNECT_WIFI" =~ ^[sS]$ ]]; then
            echo ""
            echo -e "${CYAN}📝 Digite as coordenadas (IP:Porta) [padrão: 192.168.18.50:5555]:${RESET}"
            read -r DEVICE_IP_PORT
            
            if [ -z "$DEVICE_IP_PORT" ]; then
                DEVICE_IP_PORT="192.168.18.50:5555"
            fi
            
            echo -e "${YELLOW}🚀 Tentando acoplagem em $DEVICE_IP_PORT...${RESET}"
            
            $ADB_BIN connect "$DEVICE_IP_PORT" > "$LOG_FILE" 2>&1 &
            run_with_spinner $! "Estabelecendo conexão quântica"
            
            # Re-checkdevices
            $FLUTTER_BIN devices > "$LOG_FILE" 2>&1 &
            run_with_spinner $! "Verificando estabilidade do link"
            
            DEVICES=$(cat "$LOG_FILE")
            ANDROID_COUNT=$(echo "$DEVICES" | grep -c "android" || true)
        fi
    fi
fi

if [ "$ANDROID_COUNT" -eq 0 ]; then
    print_error "Nenhum dispositivo encontrado. A missão falhou."
    echo -e "${YELLOW}💡 Dica: Conecte o cabo ou verifique o IP.${RESET}"
    rm "$LOG_FILE"
    exit 1
fi

print_success "Dispositivo Acoplado e Pronto!"
delay

# Infos
echo ""
echo -e "${GREEN}📦 Flavor:${RESET}   DEV"
echo -e "${GREEN}🎯 Target:${RESET}   lib/main_dev.dart"
echo -e "${GREEN}🏷️  ID:${RESET}       io.odyssey.moodtracker.dev"
echo ""

print_title "🚀 LANÇANDO APLICAÇÃO"
echo -e "${CYAN}Compilando os cristais de energia...${RESET}"

# Run
$FLUTTER_BIN run --flavor dev -t lib/main_dev.dart "$@"

# Cleanup
rm "$LOG_FILE"
print_success "Sessão finalizada. Até a próxima aventura!"
