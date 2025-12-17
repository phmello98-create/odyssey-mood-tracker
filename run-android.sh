#!/bin/bash

# Script para rodar o app Odyssey no Android
# Uso: ./run-android.sh

cd "$(dirname "$0")"

# Exportar variáveis do Android SDK
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin"

FLUTTER_BIN="/usr/bin/flutter"

echo "🤖 Odyssey - Executar no Android"
echo "================================"
echo ""

# Verificar dispositivos
echo "🔍 Procurando dispositivos Android conectados..."
DEVICES=$($FLUTTER_BIN devices 2>&1)

# Tentar localizar o ADB
ADB_BIN=""
if [ -f "$ANDROID_HOME/platform-tools/adb" ]; then
    ADB_BIN="$ANDROID_HOME/platform-tools/adb"
elif command -v adb &> /dev/null; then
    ADB_BIN=$(command -v adb)
fi

if echo "$DEVICES" | grep -q "No devices"; then
    echo ""
    echo "❌ Nenhum dispositivo conectado via USB encontrado."
    echo ""
    
    if [ -n "$ADB_BIN" ]; then
        echo "📡 Deseja conectar via Wi-Fi? (s/N)"
        read -r CONNECT_WIFI
        if [[ "$CONNECT_WIFI" =~ ^[sS]$ ]]; then
            echo ""
            echo "📝 Digite o IP e Porta do dispositivo (ex: 192.168.1.50:5555):"
            echo "   (No android 11+: Configurações > Opções Desenvolvedor > Depuração por Wi-Fi)"
            read -r DEVICE_IP_PORT
            
            if [ -n "$DEVICE_IP_PORT" ]; then
                echo "🔄 Tentando conectar a $DEVICE_IP_PORT..."
                $ADB_BIN connect "$DEVICE_IP_PORT"
                
                # Atualizar lista de dispositivos
                echo "🔍 Verificando conexão..."
                DEVICES=$($FLUTTER_BIN devices 2>&1)
                
                if echo "$DEVICES" | grep -q "No devices"; then
                   echo "❌ Falha ao conectar. Verifique o IP e se o dispositivo está na mesma rede."
                   exit 1
                else
                   echo "✅ Conectado com sucesso!"
                fi
            else
                echo "❌ IP inválido."
                exit 1
            fi
        else
            echo "👋 Saindo..."
            exit 1
        fi
    else
        echo "⚠️ ADB não encontrado para realizar conexão Wi-Fi automática."
        echo "📱 Opções manuais:"
        echo ""
        echo "1️⃣  USB: Conecte seu celular via cabo USB"
        echo "2️⃣  Wi-Fi: Configure manualmente com adb connect"
        exit 1
    fi
fi

echo "$DEVICES"
echo ""

# Contar dispositivos Android (excluindo Linux desktop)
ANDROID_COUNT=$(echo "$DEVICES" | grep -c "android")

# Se nenhum dispositivo ANDROID for encontrado, tentar conectar via Wi-Fi
if [ "$ANDROID_COUNT" -eq 0 ]; then
    echo "⚠️  Nenhum dispositivo Android detectado."
    
    if [ -n "$ADB_BIN" ]; then
        echo "📡 Deseja conectar um dispositivo via Wi-Fi? (s/N)"
        read -r CONNECT_WIFI
        if [[ "$CONNECT_WIFI" =~ ^[sS]$ ]]; then
            echo ""
            echo "📝 Digite o IP e Porta do dispositivo (ex: 192.168.1.50:5555):"
            echo "   (No android 11+: Configurações > Opções Desenvolvedor > Depuração por Wi-Fi)"
            read -r DEVICE_IP_PORT
            
            if [ -n "$DEVICE_IP_PORT" ]; then
                echo "🔄 Tentando conectar a $DEVICE_IP_PORT..."
                $ADB_BIN connect "$DEVICE_IP_PORT"
                
                # Atualizar lista de dispositivos e contagem
                echo "🔍 Verificando conexão..."
                DEVICES=$($FLUTTER_BIN devices 2>&1)
                ANDROID_COUNT=$(echo "$DEVICES" | grep -c "android")
                
                if [ "$ANDROID_COUNT" -eq 0 ]; then
                   echo "❌ Falha ao conectar ou dispositivo não reconhecido como Android."
                   echo "Saída do flutter devices:"
                   echo "$DEVICES"
                   exit 1
                else
                   echo "✅ Conectado com sucesso!"
                fi
            else
                echo "❌ IP inválido."
                exit 1
            fi
        else
            echo "❌ Cancelado pelo usuário."
            # Continua para o exit abaixo se ainda for 0
        fi
    else
        echo "⚠️ ADB não encontrado em locais padrão. Instale o Android SDK platform-tools."
    fi
fi

if [ "$ANDROID_COUNT" -eq 0 ]; then
    echo "❌ Apenas desktop Linux encontrado (ou nenhum dispositivo). Conecte um dispositivo Android!"
    exit 1
fi

echo "✅ $ANDROID_COUNT dispositivo(s) Android encontrado(s)!"
echo ""

# Se houver múltiplos dispositivos, perguntar qual usar
if [ "$ANDROID_COUNT" -gt 1 ]; then
    echo "⚠️  Múltiplos dispositivos encontrados."
    echo "Você pode especificar um com: flutter run -d DEVICE_ID"
    echo ""
fi

echo "🚀 Iniciando o app no Android..."
echo "📬 Aguarde... o FCM Token aparecerá no console!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Executar o app
$FLUTTER_BIN run

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎉 App finalizado!"
echo ""
echo "💡 Para ver o FCM Token novamente:"
echo "   - No console: procure '✅ FCM Token obtido:'"
echo "   - No app: Mais → Configurações → Debug → FCM Token Debug"
