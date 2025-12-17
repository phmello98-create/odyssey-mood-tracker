#!/bin/bash

# Script para substituir .withOpacity() por .withValues() em todo o projeto
# Uso: ./scripts/fix_withopacity.sh

set -e

echo "🔍 Buscando arquivos com .withOpacity()..."

# Encontrar todos os arquivos .dart com withOpacity
FILES=$(find lib -name "*.dart" -type f -exec grep -l "\.withOpacity(" {} \;)

if [ -z "$FILES" ]; then
    echo "✅ Nenhum arquivo com .withOpacity() encontrado!"
    exit 0
fi

COUNT=$(echo "$FILES" | wc -l)
echo "📝 Encontrados $COUNT arquivos para processar"
echo ""

PROCESSED=0
TOTAL_REPLACEMENTS=0

for file in $FILES; do
    echo "📄 Processando: $file"
    
    # Criar backup temporário
    cp "$file" "$file.bak"
    
    # Substituir .withOpacity(X) por .withValues(alpha: X)
    # Captura números decimais, variáveis e expressões simples
    sed -i -E 's/\.withOpacity\(([0-9.]+)\)/.withValues(alpha: \1)/g' "$file"
    sed -i -E 's/\.withOpacity\(([a-zA-Z_][a-zA-Z0-9_]*)\)/.withValues(alpha: \1)/g' "$file"
    sed -i -E 's/\.withOpacity\(([a-zA-Z_][a-zA-Z0-9_]*\.[a-zA-Z0-9_]+)\)/.withValues(alpha: \1)/g' "$file"
    
    # Contar quantas substituições foram feitas
    REPLACEMENTS=$(grep -c "\.withValues(alpha:" "$file" || true)
    
    if [ "$REPLACEMENTS" -gt 0 ]; then
        TOTAL_REPLACEMENTS=$((TOTAL_REPLACEMENTS + REPLACEMENTS))
        echo "   ✅ $REPLACEMENTS substituições feitas"
        PROCESSED=$((PROCESSED + 1))
        # Remover backup se sucesso
        rm "$file.bak"
    else
        # Restaurar backup se nada foi alterado
        mv "$file.bak" "$file"
        echo "   ⚠️  Nenhuma substituição (padrão não encontrado)"
    fi
done

echo ""
echo "========================================="
echo "✅ Concluído!"
echo "📊 Arquivos processados: $PROCESSED"
echo "🔄 Total de substituições: $TOTAL_REPLACEMENTS"
echo "========================================="
echo ""
echo "⚙️  Execute 'flutter analyze' para verificar se há erros."
