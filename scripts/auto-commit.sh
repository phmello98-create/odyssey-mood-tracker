#!/bin/bash
# Auto-Commit - Commit automático inteligente

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
MAGENTA='\033[0;35m'
NC='\033[0m'

print_status() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

print_info() {
    printf "${BLUE}ℹ${NC} %s\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠${NC} %s\n" "$1"
}

print_title() {
    printf "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    printf "${MAGENTA}  %s${NC}\n" "$1"
    printf "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
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
    
    print_info "Mensagens sugeridas:"
    echo ""
    printf "  ${BLUE}1${NC}) ${MAGENTA}%s${NC}\n" "$full_message"
    printf "  ${BLUE}2${NC}) 🎨 UI: Melhorias visuais\n"
    printf "  ${BLUE}3${NC}) ✨ Feat: Nova funcionalidade\n"
    printf "  ${BLUE}4${NC}) 🐛 Fix: Correção de bug\n"
    printf "  ${BLUE}5${NC}) ♻️  Refactor: Refatoração de código\n"
    printf "  ${BLUE}6${NC}) 📝 Docs: Atualização de documentação\n"
    printf "  ${BLUE}7${NC}) 🔧 Chore: Manutenção geral\n"
    printf "  ${BLUE}8${NC}) 💾 WIP: Trabalho em progresso\n"
    printf "  ${BLUE}9${NC}) ✏️  Custom: Escrever mensagem personalizada\n"
    printf "  ${BLUE}0${NC}) ❌ Pular (não commitar agora)\n"
    echo ""
    printf "Escolha (0-9, Enter para opção 1): "
    read choice
    
    # Se vazio, usar opção 1
    choice=${choice:-1}
    
    case $choice in
        1)
            commit_msg="$full_message"
            ;;
        2)
            commit_msg="🎨 UI: Melhorias visuais"
            ;;
        3)
            printf "Descrição da feature: "
            read feat_desc
            commit_msg="✨ Feat: ${feat_desc:-Nova funcionalidade}"
            ;;
        4)
            printf "O que foi corrigido: "
            read fix_desc
            commit_msg="🐛 Fix: ${fix_desc:-Correção de bug}"
            ;;
        5)
            printf "O que foi refatorado: "
            read refactor_desc
            commit_msg="♻️  Refactor: ${refactor_desc:-Refatoração de código}"
            ;;
        6)
            commit_msg="📝 Docs: Atualização de documentação"
            ;;
        7)
            commit_msg="🔧 Chore: Manutenção geral"
            ;;
        8)
            commit_msg="💾 WIP: Trabalho em progresso"
            ;;
        9)
            printf "Mensagem personalizada: "
            read custom_msg
            commit_msg="${custom_msg:-$full_message}"
            ;;
        0)
            print_info "Commit cancelado"
            exit 0
            ;;
        *)
            print_warning "Opção inválida, usando sugestão automática"
            commit_msg="$full_message"
            ;;
    esac
    
    # Realizar commit
    print_info "Commitando..."
    git add -A
    git commit -m "$commit_msg"
    if [ $? -eq 0 ]; then
        print_status "Commit realizado!"
        echo ""
        print_info "Hash: $(git rev-parse --short HEAD)"
        print_info "Mensagem: $commit_msg"
    fi
else
    echo ""
    print_info "Nenhuma mudança para commitar"
    echo ""
    print_info "Último commit:"
    git log -1 --oneline --decorate --color=always
fi

echo ""
