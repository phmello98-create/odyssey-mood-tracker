#!/bin/bash
# Auto-Commit - Commit automático inteligente

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_title() {
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}  $1${NC}"
    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

clear
print_title "💾 COMMIT INTELIGENTE"

# Verificar se há mudanças
if ! git diff-index --quiet HEAD --; then
    echo ""
    print_info "Mudanças detectadas!"
    echo ""
    
    # Mostrar resumo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    git status -s | head -10
    
    total=$(git status -s | wc -l)
    if [ $total -gt 10 ]; then
        echo "... e mais $((total - 10)) arquivo(s)"
    fi
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Análise inteligente de mudanças
    message=""
    
    if git diff --name-only | grep -q "lib/.*\.dart$"; then
        if git diff | grep -q "class.*extends.*StatelessWidget\|class.*extends.*StatefulWidget"; then
            message="🎨 UI: Atualização de componentes"
        elif git diff | grep -q "Provider\|Riverpod\|StateNotifier"; then
            message="⚡ State: Atualização de providers"
        elif git diff | grep -q "Repository\|Box\|Hive"; then
            message="💾 Data: Atualização de repositórios"
        elif git diff | grep -q "^+.*TODO\|^+.*FIXME"; then
            message="📝 WIP: Trabalho em progresso"
        else
            message="✨ Feat: Atualização de código"
        fi
    elif git diff --name-only | grep -q "pubspec.yaml"; then
        if git diff pubspec.yaml | grep -q "^+.*dependencies:"; then
            message="📦 Deps: Adicionadas dependências"
        else
            message="📦 Deps: Atualização de dependências"
        fi
    elif git diff --name-only | grep -q "\.md$"; then
        message="📚 Docs: Atualização de documentação"
    elif git diff --name-only | grep -q "assets/\|images/"; then
        message="🎨 Assets: Atualização de recursos"
    elif git diff --name-only | grep -q "test/"; then
        message="🧪 Test: Atualização de testes"
    elif git diff --name-only | grep -q "scripts/"; then
        message="🔧 Scripts: Atualização de automação"
    else
        message="🔧 Chore: Atualizações gerais"
    fi
    
    # Adicionar timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M")
    full_message="$message [$timestamp]"
    
    # Estatísticas
    added=$(git diff --cached --numstat 2>/dev/null | awk '{sum+=$1} END {print sum}')
    deleted=$(git diff --cached --numstat 2>/dev/null | awk '{sum+=$2} END {print sum}')
    
    echo ""
    print_info "Estatísticas:"
    echo "  Arquivos: $total"
    echo "  Linhas adicionadas: ${added:-0}"
    echo "  Linhas removidas: ${deleted:-0}"
    echo ""
    
    print_info "Mensagem sugerida:"
    echo "  ${MAGENTA}$full_message${NC}"
    echo ""
    
    # Opções
    echo "Opções:"
    echo "  ${YELLOW}1)${NC} Usar mensagem sugerida"
    echo "  ${YELLOW}2)${NC} Escrever mensagem personalizada"  
    echo "  ${YELLOW}3)${NC} Pular (não commitar agora)"
    echo ""
    read -p "Escolha (1/2/3): " choice
    
    case $choice in
        1)
            print_info "Commitando..."
            git add -A
            git commit -m "$full_message"
            if [ $? -eq 0 ]; then
                print_status "Commit realizado!"
                echo ""
                print_info "Hash: $(git rev-parse --short HEAD)"
            fi
            ;;
        2)
            read -p "Mensagem do commit: " custom_message
            if [ -n "$custom_message" ]; then
                print_info "Commitando..."
                git add -A
                git commit -m "$custom_message"
                if [ $? -eq 0 ]; then
                    print_status "Commit realizado!"
                    echo ""
                    print_info "Hash: $(git rev-parse --short HEAD)"
                fi
            else
                print_warning "Mensagem vazia, usando sugerida"
                git add -A
                git commit -m "$full_message"
            fi
            ;;
        3)
            print_info "Commit cancelado"
            ;;
        *)
            print_warning "Opção inválida, usando mensagem sugerida"
            git add -A
            git commit -m "$full_message"
            if [ $? -eq 0 ]; then
                print_status "Commit realizado!"
            fi
            ;;
    esac
else
    echo ""
    print_info "Nenhuma mudança para commitar"
    echo ""
    print_info "Último commit:"
    git log -1 --oneline --decorate --color=always
fi

echo ""
