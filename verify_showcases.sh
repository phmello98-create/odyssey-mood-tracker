#!/bin/bash
# verify_showcases.sh - Verifica implementação dos showcases

echo "🔍 Verificando implementação do ShowcaseView..."
echo ""

PROJECT_DIR="/home/agyspc1/Documentos/app com opus 4.5 copia atual/lib"

# Verificar serviço
if [ -f "$PROJECT_DIR/src/features/onboarding/services/showcase_service.dart" ]; then
    echo "✅ ShowcaseService existe"
else
    echo "❌ ShowcaseService NÃO encontrado"
fi

# Verificar imports nas telas
echo ""
echo "📦 Verificando imports nas telas:"
for screen in home tasks habits notes library time_tracker; do
    file=$(find "$PROJECT_DIR" -name "*${screen}*screen.dart" -type f | head -1)
    if [ -n "$file" ]; then
        if grep -q "showcaseview" "$file"; then
            echo "  ✅ $screen: import showcaseview OK"
        else
            echo "  ⚠️  $screen: falta import showcaseview"
        fi
        if grep -q "ShowcaseService" "$file"; then
            echo "  ✅ $screen: ShowcaseService OK"
        else
            echo "  ⚠️  $screen: falta ShowcaseService"
        fi
    fi
done

# Verificar erros de compilação
echo ""
echo "🔧 Verificando erros de compilação..."
cd "$(dirname "$PROJECT_DIR")"
/home/agyspc1/flutter/bin/flutter analyze lib/ 2>&1 | grep -c "error" | xargs -I {} echo "Total de erros: {}"

echo ""
echo "✨ Verificação completa!"
