#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# 📦 ODYSSEY - Build APK (Dev ou Prod)
# ═══════════════════════════════════════════════════════════════════════════════
# 
# Uso: ./build-apk.sh [dev|prod] [debug|release]
# 
# Exemplos:
#   ./build-apk.sh dev debug     # APK dev para teste rápido
#   ./build-apk.sh dev release   # APK dev otimizado
#   ./build-apk.sh prod release  # APK final para Play Store
#
# ═══════════════════════════════════════════════════════════════════════════════

set -e

FLAVOR="${1:-prod}"
BUILD_TYPE="${2:-release}"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "📦 ODYSSEY - Gerando APK"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "🏷️  Flavor: $FLAVOR"
echo "🔧 Build Type: $BUILD_TYPE"
echo ""

# Validar argumentos
if [[ "$FLAVOR" != "dev" && "$FLAVOR" != "prod" ]]; then
    echo "❌ Flavor inválido: $FLAVOR"
    echo "💡 Use: dev ou prod"
    exit 1
fi

if [[ "$BUILD_TYPE" != "debug" && "$BUILD_TYPE" != "release" ]]; then
    echo "❌ Build type inválido: $BUILD_TYPE"
    echo "💡 Use: debug ou release"
    exit 1
fi

# Determinar entry point
if [[ "$FLAVOR" == "dev" ]]; then
    ENTRY_POINT="lib/main_dev.dart"
    PACKAGE_ID="io.odyssey.moodtracker.dev"
else
    ENTRY_POINT="lib/main_prod.dart"
    PACKAGE_ID="io.odyssey.moodtracker"
fi

echo "📄 Entry point: $ENTRY_POINT"
echo "📦 Package ID: $PACKAGE_ID"
echo ""

# Executar build
echo "🔨 Gerando APK..."
flutter build apk --flavor "$FLAVOR" -t "$ENTRY_POINT" --"$BUILD_TYPE"

# Mostrar localização do APK
APK_PATH="build/app/outputs/flutter-apk/app-$FLAVOR-$BUILD_TYPE.apk"
if [[ -f "$APK_PATH" ]]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "✅ APK gerado com sucesso!"
    echo "═══════════════════════════════════════════════════════"
    echo ""
    echo "📍 Localização: $APK_PATH"
    echo "📏 Tamanho: $APK_SIZE"
    echo ""
    echo "💡 Para instalar: adb install $APK_PATH"
else
    echo ""
    echo "⚠️  APK não encontrado no caminho esperado."
    echo "📁 Verifique em: build/app/outputs/flutter-apk/"
fi
