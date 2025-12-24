#!/bin/bash

echo "🚀 Iniciando Build de Produção (APK Split ARM64/ARMv7/x86)..."
echo "Target: Prod Flavor, Release Mode, NO Tree Shake Icons (Fix)"

# Stop on error
set -e

# Limpa builds anteriores para garantir integridade
flutter clean

# Get dependencies
flutter pub get

# Builda o APK com split (gera um APK por arquitetura), modo release
# Adicionado --no-tree-shake-icons para corrigir erro de ícones dinâmicos
flutter build apk --flavor prod --release --split-per-abi --no-tree-shake-icons

echo ""
echo "✅ Build finalizado com sucesso!"
echo "📍 APKs gerados em: build/app/outputs/flutter-apk/"
